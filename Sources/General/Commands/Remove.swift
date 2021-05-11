//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

final class Remove: ParsableCommand {

    enum Error: Swift.Error, CustomStringConvertible {
        case noSpecification
        case noPlugin(String)

        var description: String {
            switch self {
            case .noSpecification:
                return "Specifies the name of plugin that should be removed"
            case let .noPlugin(pluginName):
                return "Could not find installe plugin with name `\(pluginName)`"
            }
        }
    }

    public static let configuration: CommandConfiguration = .init(abstract: "Removes installed commands")

    // MARK: - Parameters

    @Argument(help: "Specifies the name of plugin that should be removed",
              completion: .installedPlugins)
    var pluginName: String?

    @Option(name: [.customLong("commands"), .customShort("c")],
            help: .init(stringLiteral: "Specifies concrere plugin commands that should be removed"),
            transform: { string in
                string.split(separator: ",").map { substring in
                    String(substring).trimmingCharacters(in: .whitespaces)
                }
            })
    var commands: [String]?

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {

    }
}
