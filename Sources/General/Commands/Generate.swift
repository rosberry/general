//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import Stencil
import StencilSwiftKit
import Yams
import PathKit
import XcodeProj

public final class Generate: ParsableCommand {

    enum Error: Swift.Error {
        case noOutput(template: String)
    }

    private lazy var specFactory: SpecFactory = .init()
    private lazy var fileManager: FileManager = .default
    private lazy var projectService: ProjectService = .init(path: .init(path))

    private lazy var generalSpec: GeneralSpec? = {
        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        let specURL = URL(fileURLWithPath: Constants.generalSpecName, relativeTo: pathURL)
        return try? specFactory.makeSpec(url: specURL)
    }()

    // MARK: - Lifecycle

    public init() {
    }

    // MARK: - Parameters

    public static let configuration: CommandConfiguration = .init(commandName: "gen", abstract: "Generates modules from templates.")

    @Option(name: .shortAndLong, completion: .directory, help: "The path for the project.")
    var path: String = FileManager.default.currentDirectoryPath

    @Option(name: .shortAndLong, help: "The name of the module.")
    var name: String

    @Option(name: .shortAndLong, help: "The name of the template.", completion: .templates)
    var template: String

    @Option(name: .shortAndLong, help: "The output for the template.", completion: .directory)
    var output: String?

    @Option(name: .long, help: "The target to which add files.", completion: .targets)
    var target: String?

    @Option(name: .long, help: "The test target to which add test files.", completion: .targets)
    var testTarget: String?

    @Argument(help: "The additional variables for templates.")
    var variables: [Variable] = []

    private var context: [String: Any] {
        let year = Calendar.current.component(.year, from: .init())
        var context: [String: Any] = ["name": name,
                                      "year": year]
        if let company = generalSpec?.xcodeproj?.company {
            context["company"] = company
        }
        for variable in variables {
            context[variable.key] = variable.value
        }
        return context
    }

    // MARK: - Lifecycle

    public func run() throws {
        //create environment and spec
        let templatesURL = defineTemplatesURL()
        let templateURL = templatesURL + template
        let specURL = templateURL + Constants.specFilename
        let templateSpec: TemplateSpec = try specFactory.makeSpec(url: specURL)

        let environment = try makeEnvironment(templatesURL: templatesURL, templateURL: templateURL)

        if let xcodeproj = generalSpec?.xcodeproj {
            if let projectName = xcodeproj.project {
                try projectService.createProject(projectName: projectName)
            }
            try add(templateSpec, to: target ?? xcodeproj.target, with: environment)
            try projectService.write()
        }
        else {
            try add(templateSpec, environment: environment)
        }
        print("🎉 \(template) template with \(name) name was successfully generated.")
    }

    // MARK: - Private

    private func defineTemplatesURL() -> URL {
        let folderName = Constants.templatesFolderName
        let localPath = "./\(folderName)/"
        if fileManager.fileExists(atPath: localPath + template) {
            return URL(fileURLWithPath: localPath)
        }
        return fileManager.homeDirectoryForCurrentUser + folderName
    }

    private func makeEnvironment(templatesURL: URL, templateURL: URL) throws -> Environment {
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

    private func add(_ templateSpec: TemplateSpec, environment: Environment, completion: ((URL) throws -> Void)? = nil) throws {
        for file in templateSpec.files {
            // render template for the file based on common and template files
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
            guard !fileManager.fileExists(atPath: fileURL.path) else {
                print(yellow("File already exists: \(fileURL.path)"))
                continue
            }
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            try rendered.write(to: fileURL, atomically: true, encoding: .utf8)
            try completion?(fileURL)
        }
    }

    private func outputFolder() -> String? {
        if let output = self.output {
            return output
        }
        guard let generalSpec = generalSpec,
            let output = generalSpec.output(forTemplateName: template) else {
            return nil
        }
        return output.path
    }
}

// MARK: - XcodeProj

extension Generate {
    private func add(_ templateSpec: TemplateSpec, to target: String?, with environment: Environment) throws {
        try add(templateSpec, environment: environment) { fileURL in
            try self.projectService.addFile(targetName: target,
                                            isTestTarget: false,
                                            filePath: Path(fileURL.path))
        }
    }
}

// MARK: - Generate.Error

extension Generate.Error: CustomStringConvertible {

    var description: String {
        switch self {
            case .noOutput(let template):
                return "There is no output path for \(template) template. Please use --output option or add output to general.yml."
        }
    }
}
