//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import Stencil
import StencilSwiftKit
import Yams
import PathKit

public final class Renderer {

    public enum Error: Swift.Error & CustomStringConvertible {
        case noOutput(template: String)
        case notFound
        case invalidTemplate

        public var description: String {
            switch self {
            case let .noOutput(template):
                return "There is no output path for \(template) template. Please use --output option or add output to general.yml."
            case .notFound:
                return "In current project not found file at path ../Classes/BusinessLogic/Services/Services.swift. Please check that file is existe and try again"
            case .invalidTemplate:
                return "Is not correctly template with marked key for Services.swift. Please remove his and generate again Services.swift. or fix marked yourself."
            }
        }
    }

    private enum Constant {
        static let newLine = "\n"
        static let newLineAndWhitespace = "\n    "
        static let marked = " /*mark:"
        static let endMarked = "*/"
        static let and = "&"
    }

    private class VariablesTemplate: Template {
        var variables: [String]
        required init(templateString: String, environment: Environment? = nil, name: String? = nil) {
            let pattern = "\\{\\{\\s*([a-zA-Z][a-zA-Z0-9]*)\\s*\\}\\}"
            self.variables = parseAllRegexMatches(pattern: pattern, rangeIndex: 1, string: templateString)
            super.init(templateString: templateString, environment: environment, name: name)
        }
    }

    public typealias Dependencies = HasFileHelper & HasSpecFactory

    let name: String
    let template: String
    let path: String
    let variables: [Variable]
    var marks: [String: String]?
    var output: String?

    private lazy var context: [String: Any] = {
        let year = Calendar.current.component(.year, from: .init())
        var context: [String: Any] = ["name": name,
                                      "year": year]
        for variable in variables {
            context[variable.key] = variable.value
        }
        if let marks = marks {
            for (key, value) in marks {
                context[key] = value
            }
        }
        return context
    }()

    private let dependencies: Dependencies

    public init(name: String,
                marks: [String: String]? = nil,
                template: String,
                path: String,
                variables: [Variable],
                output: String?,
                dependencies: Dependencies) {
        self.name = name
        self.marks = marks
        self.template = template
        self.path = path
        self.variables = variables
        self.output = output
        self.dependencies = dependencies
    }

    public func render(completion: ((URL) throws -> Void)? = nil) throws {
        let templatesURL = defineTemplatesURL()
        let templateURL = templatesURL + template
        let specURL = templateURL + Constants.specFilename
        let templateSpec: TemplateSpec = try dependencies.specFactory.makeSpec(url: specURL)

        let environment = try makeEnvironment(templatesURL: templatesURL, templateURL: templateURL)
        try add(templateSpec, environment: environment, completion: completion)
        try modify(templateSpec, environment: environment)
        print("🎉 \(template) template with \(name) name was successfully generated.")
    }

    public func add(_ templateSpec: TemplateSpec, environment: Environment, completion: ((URL) throws -> Void)? = nil) throws {
        for file in templateSpec.files {
            if let fileURL = try render(file, templateSpec: templateSpec, environment: environment) {
                try completion?(fileURL)
            }
        }
    }

    public func modify(_ templateSpec: TemplateSpec, environment: Environment) throws {
        guard let path = templateSpec.mark else {
            return
        }
        let fileURL = URL(fileURLWithPath: path)

        guard var line = try? String(contentsOf: fileURL) else {
            throw Error.notFound
        }
        var parts: [String] = []
        var searchStart = line.startIndex
        var isSecondIteration = false

        while searchStart != nil {
            guard let start = line.range(of: Constant.marked)?.lowerBound,
                  let endRange = line.range(of: Constant.endMarked) else {
                break
            }

            let nsRange = NSRange(endRange, in: line)

            guard let end = line.range(of: Constant.endMarked, range: Range(nsRange, in: line))?.upperBound else {
                break
            }

            let first = line[line.startIndex...start]
            let template = line[start...end]

            var rendered = removeMarkedFrom(template: template)

            if isSecondIteration {
                rendered = Constant.newLineAndWhitespace + removeMarkedFrom(template: template)
            }

            guard var renderedTemplate = try? environment.renderTemplate(string: rendered, context: context) else {
                throw Error.invalidTemplate
            }

            if isSecondIteration == false && variables.first?.value.isEmpty == true {
                renderedTemplate = Constant.and + Constant.newLineAndWhitespace + renderedTemplate
            }

            parts.append(contentsOf: [String(first), renderedTemplate, String(template), Constant.newLine])
            line = String(line[end...]).trimmingCharacters(in: .newlines)
            searchStart = line.startIndex
            isSecondIteration = true
        }
        parts.append(line)
        try parts.joined().write(toFile: fileURL.path, atomically: true, encoding: .utf8)
    }

    private func removeMarkedFrom(template: String.SubSequence) -> String {
        guard let index = template.firstIndex(of: ":") else {
            return String(template)
        }
        var line = template.suffix(from: index)
        line.removeFirst()
        var newLine = String(line).trimmingCharacters(in: .newlines)
        newLine.removeLast()
        newLine.removeLast()
        return newLine.trimmingCharacters(in: .whitespaces)
    }

    public func render(_ file: File, templateSpec: TemplateSpec, environment: Environment) throws -> URL? {
        askRequiredVariables(file, environment: environment)
        let rendered = try environment.renderTemplate(name: file.template, context: context).trimmingCharacters(in: .whitespacesAndNewlines)
        let module = name
        let fileName = file.fileName(in: module)

        // make output url for the file
        var outputURL = URL(fileURLWithPath: path)
        if let output = file.output {
            outputURL.appendPathComponent(output)
        }
        else if let folder = outputFolder() {
            outputURL.appendPathComponent(folder)
            if let suffix = templateSpec.suffix {
                outputURL.appendPathComponent(name + suffix)
            }
            else {
                outputURL.appendPathComponent(name)
            }
            if let subfolder = file.folder {
                outputURL.appendPathComponent(subfolder)
            }
            outputURL.appendPathComponent(fileName)
        }
        else {
            throw Error.noOutput(template: template)
        }

        // write rendered template to file
        let fileURL = outputURL
        outputURL.deleteLastPathComponent()
        let fileManager = dependencies.fileHelper.fileManager
        guard !fileManager.fileExists(atPath: fileURL.path) else {
            print(yellow("File already exists: \(fileURL.path)"))
            return nil
        }
        if !fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        }
        try rendered.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    // MARK: - Private

    private func outputFolder() -> String? {
        if let output = self.output {
            return output
        }

        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        let specURL = URL(fileURLWithPath: Constants.generalSpecName, relativeTo: pathURL)
        let generalSpec: GeneralSpec? = try? dependencies.specFactory.makeSpec(url: specURL)
        guard let output = generalSpec?.output(forTemplateName: template) else {
            return nil
        }
        return output.path
    }

    private func defineTemplatesURL() -> URL {
        let fileManager = dependencies.fileHelper.fileManager
        let folderName = Constants.templatesFolderName
        let localPath = "./\(folderName)/"
        if fileManager.fileExists(atPath: localPath + template) {
            return URL(fileURLWithPath: localPath)
        }
        return fileManager.homeDirectoryForCurrentUser + folderName
    }

    private func makeEnvironment(templatesURL: URL, templateURL: URL) throws -> Environment {
        let fileManager = dependencies.fileHelper.fileManager
        let commonTemplatesURL = templatesURL + Constants.commonTemplatesFolderName
        let contents = try fileManager.contentsOfDirectory(at: templateURL,
                                                           includingPropertiesForKeys: [.isDirectoryKey],
                                                           options: [])
        let directoryPaths: [Path] = contents.compactMap { url in
            guard url.hasDirectoryPath else {
                return nil
            }
            return Path(url.path)
        }
        var paths = [Path(commonTemplatesURL.path), Path(templateURL.path)]
        paths.append(contentsOf: directoryPaths)
        let environment = Environment(loader: FileSystemLoader(paths: paths))
        environment.extensions.forEach { ext in
            ext.registerStencilSwiftExtensions()
        }
        return environment
    }

    private func askRequiredVariables(_ file: File, environment: Environment) {
        let templateEnvironment = Environment(loader: environment.loader,
                                              extensions: environment.extensions,
                                              templateClass: VariablesTemplate.self)
        guard let template = try? templateEnvironment.loadTemplate(name: file.template) as? VariablesTemplate,
              !template.variables.isEmpty else {
            return
        }
        print(yellow("Please enter following template variables"))
        template.variables.forEach { variable in
            if !context.keys.contains(variable) {
                context[variable] = ask("\(variable)")
            }
        }
    }
}
