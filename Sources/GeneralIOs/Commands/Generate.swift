//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import Stencil
import StencilSwiftKit
import Yams
import PathKit
import XcodeProj
import GeneralKit

public final class Generate: ParsableCommand {

    enum Error: Swift.Error, CustomStringConvertible {
        case projectName
        case serviceMarks

        var description: String {
            switch self {
            case .projectName:
                return "Project name was not specified."
            case .serviceMarks:
                return "Marks is not found for service template."
            }
        }
    }

    private enum Key {
        static let isNewFile = "isNewFile"
        static let company = "company"
    }

    typealias Dependencies = HasSpecFactory & HasProjectServiceFactory

    public static let configuration: CommandConfiguration = .init(commandName: "gen", abstract: "Generates modules from templates.")

    private lazy var specFactory: SpecFactory = dependencies.specFactory
    private lazy var projectService: ProjectService = dependencies.projectServiceFactory.makeProjectService(path: Path(path))

    private var dependencies: Dependencies {
        Services
    }

    private var askCompanyName: String {
        ask("What is the name of your company?", default: "") ?? ""
    }

    private lazy var generalSpec: GeneralSpec? = {
        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        let specURL = URL(fileURLWithPath: Constants.generalSpecName, relativeTo: pathURL)
        return try? specFactory.makeSpec(url: specURL)
    }()

    // MARK: - Parameters

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

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        if let xcodeSpec = generalSpec?.xcode {
            guard let projectName = xcodeSpec.name ?? askProject() else {
                throw Error.projectName
            }

            var marked = generalSpec?.services.serviceMarks
            marked?[Key.company] = xcodeSpec.company ?? askCompanyName
            let isNewFile = !FileManager.default.fileExists(atPath: generalSpec?.services.servicesPath ?? "") ? "\(true)" : ""
            guard let generalSpec = generalSpec else {
                throw Error.serviceMarks
            }
            let renderer = Renderer(name: name,
                                    marked: marked,
                                    template: template,
                                    path: path,
                                    variables: [.init(key: Key.isNewFile, value: isNewFile)],
                                    output: output,
                                    dependencies: Services)
            try projectService.createProject(projectName: projectName)
            let target = self.target ?? xcodeSpec.target
            try renderer.render { fileURL in
                try self.projectService.addFile(targetName: target, filePath: Path(fileURL.path))
            }
            try self.projectService.write()
        }
        else {
            let renderer = Renderer(name: name,
                                    template: template,
                                    path: path,
                                    variables: [.init(key: Key.isNewFile, value: "")],
                                    output: output,
                                    dependencies: Services)
            try renderer.render()
        }
    }
}
