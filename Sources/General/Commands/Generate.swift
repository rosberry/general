//
//  Created by Artem Novichkov on 04.06.2020.
//

import Foundation
import ArgumentParser
import Stencil
import Yams
import PathKit
import xcodeproj

final class Generate: ParsableCommand {

    enum Error: Swift.Error {
        case noOutput
    }

    private lazy var specFactory: SpecFactory = .init(decoder: .init())
    private lazy var fileManager: FileManager = .default
    private lazy var projectService: ProjectService = .init()

    private lazy var generalSpec: GeneralSpec? = {
        let url = URL(fileURLWithPath: path)
        return try? specFactory.makeGeneralSpec(url: url)
    }()

    // MARK: - Parameters

    static let configuration: CommandConfiguration = .init(commandName: "gen", abstract: "Generates modules from templates.")

    @Option(name: [.short, .long], default: FileManager.default.currentDirectoryPath, help: "The path for the project.")
    var path: String

    @Option(name: [.short, .long], help: "The name of the module.")
    var name: String

    @Option(name: [.short, .long], help: "The name of the template.")
    var template: String

    @Option(name: [.short, .long], help: "The output for the template.")
    var output: String?

    private var context: [String: Any] {
        let year = Calendar.current.component(.year, from: .init())
        return ["name": name,
                "year": year]
    }

    // MARK: - Lifecycle

    func run() throws {
        //create urls and spec
        let templatesURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(Constants.templatesFolderName)
        let commonTemplatesURL = templatesURL.appendingPathComponent(Constants.commonTemplatesFolderName)
        let templateURL = templatesURL.appendingPathComponent(template)
        let specURL = templateURL.appendingPathComponent(Constants.specFilename)
        let templateSpec = try specFactory.makeTemplateSpec(url: specURL)
        let codeURL = templateURL.appendingPathComponent(Constants.filesFolderName)

        for file in templateSpec.files {
            // render template for the file based on common and template files
            let environment = Environment(loader: FileSystemLoader(paths: [.init(commonTemplatesURL.path),
                                                                           .init(codeURL.path)]))
            let rendered = try environment.renderTemplate(name: file.template, context: context)

            var fileName = file.name ?? file.template.removingStencilExtension
            fileName = name.capitalized + fileName

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
            outputURL.appendPathComponent(templatePath)
            outputURL.appendPathComponent(name.capitalized)

            // write rendered template to file
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            let fileURL = outputURL.appendingPathComponent(fileName)
            try rendered.write(to: fileURL, atomically: true, encoding: .utf8)
            if let projectName = generalSpec?.project {
                try projectService.addFile(path: Path(path),
                projectName: projectName,
                templatePath: Path(templatePath) + Path(name.capitalized),
                filename: fileName)
            }
            print("Finish")
        }
    }
}

extension PBXGroup {

    func group(withPath path: String) -> PBXGroup? {
        children.first { element in
            element.path == path
        } as? PBXGroup
    }
}

extension String {

    var removingStencilExtension: String {
        replacingOccurrences(of: ".stencil", with: "")
    }
}
