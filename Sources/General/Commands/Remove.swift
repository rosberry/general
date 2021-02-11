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

        let defaultConfig = ConfigFactory.default
        try updateConfig { config in
            var config = config

            func isContainingCommand(withName name: String, in plugin: Plugin) -> Bool {
                plugin.commands.contains { command in
                    command.name == name || command.executable == name
                }
            }

            func findPlugin(with name: String) -> Plugin? {
                config.installedPlugins.first { plugin in
                     plugin.name == name
                }
            }

            func remove(command: String) {
                guard config.commands[command] != nil else {
                    return print(yellow("Command `\(command)` is not installed. Skipping."))
                }
                guard defaultConfig.commands[command] != nil ||
                   askBool(question: "Command `\(command)` has not default alternative. Are youre sure you want to remove it?") else {
                    return
                }
                config.commands[command] = defaultConfig.commands[command]
            }

            if let pluginName = self.pluginName,
               let commands = self.commands {
                guard let plugin = findPlugin(with: pluginName) else {
                    throw Error.noPlugin(pluginName)
                }
                commands.forEach { command in
                    guard isContainingCommand(withName: command, in: plugin) else {
                        return print(yellow("Plugin `\(pluginName)` does not contains command `\(command)`"))
                    }
                    remove(command: command)
                }
                return config
            }

            if let pluginName = self.pluginName {
                guard let plugin = findPlugin(with: pluginName) else {
                    throw Error.noPlugin(pluginName)
                }
                plugin.commands.forEach { command in
                    remove(command: command.executable)
                }
                return config
            }

            if let commands = self.commands {
                commands.forEach(remove)
                return config
            }

            throw Error.noSpecification
        }
    }
}
