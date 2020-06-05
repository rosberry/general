//
//  Created by Artem Novichkov on 04.06.2020.
//

import Foundation
import ArgumentParser
import Stencil
import Yams
import xcodeproj
import PathKit

struct File: Decodable {

    let template: String
    let name: String?
}

struct TemplateSpec: Decodable {

    let files: [File]
}

struct Output: Decodable {

    let templateName: String
    let path: String
}

struct ModuleGenSpec: Decodable {

    let outputs: [Output]

    func path(forTemplateName templateName: String) -> String? {
        var path: String?
        for output in outputs where output.templateName == templateName {
            path = output.path
        }
        return path
    }
}

final class Generate: ParsableCommand {

    enum Error: Swift.Error {
        case noOutput
    }

    private lazy var specFactory: SpecFactory = .init(decoder: .init())
    private lazy var fileManager: FileManager = .default

    private lazy var moduleGenSpec: ModuleGenSpec? = {
        let url = URL(fileURLWithPath: path)
        return try? specFactory.makeModuleGenSpec(url: url)
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
        let specURL = templateURL.appendingPathComponent(Constants.spec)
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
            var outputURL: URL
            if let output = output {
                outputURL = URL(fileURLWithPath: output)
            }
            else if let moduleGenSpec = moduleGenSpec, let templatePath = moduleGenSpec.path(forTemplateName: template) {
                outputURL = URL(fileURLWithPath: path).appendingPathComponent(templatePath)
            }
            else {
                throw Error.noOutput
            }
            outputURL.appendPathComponent(name.capitalized)

            // write rendered template to file
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            let fileURL = outputURL.appendingPathComponent(fileName)
            try rendered.write(to: fileURL, atomically: true, encoding: .utf8)
            print(rendered)

            //            let path = Path("/Users/artemnovichkov/Library/Developer/Xcode/DerivedData/ModuleGen-erkdnzflxbigfxbnxzsjrihxxpxj/Build/Products/Debug/Module/Module.xcodeproj")
            //            let xcodeproj = try XcodeProj(path: path)
            //            let project = xcodeproj.pbxproj.projects.first!
            //            let mainGroup = project.mainGroup
            //            try mainGroup?.addGroup(named: "MyGroup")
            //            try xcodeproj.write(path: path)
        }
    }
}

extension String {

    var removingStencilExtension: String {
        replacingOccurrences(of: ".stencil", with: "")
    }
}
