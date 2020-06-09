//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import Stencil
import Yams
import PathKit
import XcodeProj

final class Generate: ParsableCommand {

    enum Error: Swift.Error {
        case noOutput
    }

    private lazy var specFactory: SpecFactory = .init()
    private lazy var fileManager: FileManager = .default
    private lazy var projectService: ProjectService = .init(path: .init(path))

    private lazy var generalSpec: GeneralSpec? = {
        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        let specURL = URL(fileURLWithPath: "general.yml", relativeTo: pathURL)
        return try? specFactory.makeSpec(url: specURL)
    }()

    // MARK: - Parameters

    static let configuration: CommandConfiguration = .init(commandName: "gen", abstract: "Generates modules from templates.")

    @Option(name: .shortAndLong, default: FileManager.default.currentDirectoryPath, help: "The path for the project.")
    var path: String

    @Option(name: .shortAndLong, help: "The name of the module.")
    var name: String

    @Option(name: .shortAndLong, help: "The name of the template.")
    var template: String

    @Option(name: .shortAndLong, help: "The output for the template.")
    var output: String?

    @Argument(help: "The additional parameters for templates.")
    var parameters: [Parameter]

    private var context: [String: Any] {
        let year = Calendar.current.component(.year, from: .init())
        var context: [String: Any] = ["name": name,
                                      "year": year]
        if let company = generalSpec?.company {
            context["company"] = company
        }
        for parameter in parameters {
            context[parameter.key] = parameter.value
        }
        return context
    }

    // MARK: - Lifecycle

    func run() throws {
        //create environment and spec
        let templatesURL = fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        let templateURL = templatesURL + template
        let specURL = templateURL + Constants.specFilename
        let templateSpec: TemplateSpec = try specFactory.makeSpec(url: specURL)

        let environment = try makeEnvironment(templatesURL: templatesURL, templateURL: templateURL)

        if let projectName = generalSpec?.project {
            try projectService.createProject(projectName: projectName)
        }

        for file in templateSpec.files {
            // render template for the file based on common and template files
            let rendered = try environment.renderTemplate(name: file.template, context: context)

            var fileName = file.name ?? file.template
            var relativeFileURL = URL(fileURLWithPath: fileName)
            if relativeFileURL.pathExtension == "stencil" {
                relativeFileURL.deletePathExtension()
            }
            fileName = name.capitalized + relativeFileURL.lastPathComponent

            // make output url for the file
            var outputURL = URL(fileURLWithPath: path)
            let templatePath: String
            if let output = output {
                outputURL.appendPathComponent(output)
                templatePath = ""
            }
            else if let generalSpec = generalSpec, let specTemplatePath = generalSpec.path(forTemplateName: template) {
                templatePath = specTemplatePath
            }
            else {
                throw Error.noOutput
            }
            let modulePath = Path(templatePath) + Path(name.capitalized)
            outputURL.appendPathComponent(modulePath.string)

            // write rendered template to file
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            let fileURL = outputURL + fileName
            try rendered.write(to: fileURL, atomically: true, encoding: .utf8)
            try projectService.addFile(targetName: generalSpec?.target,
                                       filePath: modulePath + Path(fileName))
        }
        try projectService.write()
        print("🎉 \(template) template with \(name) name was successfully generated.")
    }

    // MARK: - Private

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
        return environment
    }
}

extension Generate.Error: CustomStringConvertible {

    var description: String {
        switch self {
            case .noOutput:
                return "There is no output path for template. Please use --output option or add output to general.yml."
        }
    }
}
