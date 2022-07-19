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

        var description: String {
            switch self {
            case .projectName:
                return "Project name was not specified"
            }
        }
    }

    private enum Key {
        static let serviceMark = "serviceMark"
        static let serviceMarkName = "serviceMarkName"
        static let serviceMarkHas = "serviceMarkHas"
        static let isNewFile = "isNewFile"
    }

    typealias Dependencies = HasSpecFactory & HasProjectServiceFactory

    public static let configuration: CommandConfiguration = .init(commandName: "gen", abstract: "Generates modules from templates.")

    private lazy var specFactory: SpecFactory = dependencies.specFactory
    private lazy var projectService: ProjectService = dependencies.projectServiceFactory.makeProjectService(path: Path(path))

    private var dependencies: Dependencies {
        Services
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

    @Option(name: .long, help: "If you need create file Services then enter true, else ignoring because default nil.")
    var new: Bool?

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
        let new = new != nil ? "\(new ?? false)" : ""
        if let xcodeSpec = generalSpec?.xcode {
            guard let projectName = xcodeSpec.name ?? askProject()else {
                throw Error.projectName
            }

            var marked: [String: String]?
            if let servicesSpec = generalSpec?.services {
                marked = [Key.serviceMarkName: servicesSpec.serviceMarkName,
                          Key.serviceMark: servicesSpec.serviceMark,
                          Key.serviceMarkHas: servicesSpec.serviceMarkHas]

            }
            let renderer = Renderer(name: name,
                                    marked: marked,
                                    template: template,
                                    path: path,
                                    variables: [.init(key: Key.isNewFile, value: new)],
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
                                    variables: [.init(key: Key.isNewFile, value: new)],
                                    output: output,
                                    dependencies: Services)
            try renderer.render()
        }
    }
}
