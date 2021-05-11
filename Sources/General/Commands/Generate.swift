//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public final class Generate: ParsableCommand {
    
    public static let configuration: CommandConfiguration = .init(commandName: "gen", abstract: "Generates modules from templates.")

    // MARK: - Parameters

    @Option(name: .shortAndLong, completion: .directory, help: "The path for the project.")
    var path: String = FileManager.default.currentDirectoryPath

    @Option(name: .shortAndLong, help: "The name of the module.")
    var name: String

    @Option(name: .shortAndLong, help: "The name of the template.", completion: .templates)
    var template: String

    @Option(name: .shortAndLong, help: "The output for the template.", completion: .directory)
    var output: String?

    @Argument(help: "The additional variables for templates.")
    var variables: [GeneralKit.Variable] = []

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        let renderer = Renderer(name: name, template: template, path: path, variables: variables, output: output)
        try renderer.render()
    }
}
