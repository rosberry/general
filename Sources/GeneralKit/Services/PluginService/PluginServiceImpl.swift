//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation

final class PluginServiceImpl: PluginService {

    typealias Dependencies = HasFileHelper & HasHelpParser & HasCompletionsService & HasShell

    private let dependencies: Dependencies

    enum Error: Swift.Error, LocalizedError {
        case brokenPlugin(String)

        var errorDescription: String? {
            switch self {
            case let .brokenPlugin(message):
                return message
            }
        }
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func main(command: ParsableCommand.Type) throws {
        let runConfig = try buildRunConfig(command: command)
        let completionService = dependencies.completionsService
        if let plugin = definePlugin(commands: mapCommands(runConfig: runConfig),
                                     runConfig: runConfig),
           plugin != (command.configuration.commandName ?? String(describing: command).lowercased()) {
            try run(plugin: plugin)
        }
        else if let shell = completionService.defineCompletionShell() {
            var plugins: [String: String] = [:]
            let _: [(String, String)] = try mapPlugins { path, name in
                let script = try dependencies.shell(silent: path + name + " \(dependencies.completionsService.generateOptionName) \(shell.rawValue)")
                plugins[name] = script
                return (name, script)
            }
            let config = CompletionConfig(shell: shell, command: command, plugins: plugins, overrides: runConfig.overrides)
            let script = completionService.overrideCompletionScript(config: config)
            print(script)
        } else {
            command.main()
        }
    }

    private func definePlugin(commands: [String: CommandArguments], runConfig: RunConfig) -> String? {
        guard commands.isEmpty == false else {
            return nil
        }
        if let first = commands.keys.first,
           commands.count == 1 {
            return first
        }
        let commandsSet = Set(commands.flatMap { key, command in
            command.subcommands.map(\.key)
        })
        guard commandsSet.count == 1,
              let command = commandsSet.first else {
            return nil
        }
        if let overrided = runConfig.overrides[command],
           commands.keys.contains(overrided) {
            return overrided
        }
        guard let choice = askChoice("More then one executable instance provides the command `\(command)`", values: commands.map(\.key)) else {
            exit(0)
        }
        if askBool(question: "Do you want use `\(choice)` by default for command `\(command)`?") {
            try? Services.configFactory.update { config in
                var config = config
                config.overrides[command] = choice
                return config
            }
        }
        print("You can set a default executable instance with `general config use --executable <executable> --for <command>`")
        return choice
    }

    private func loadPlugins() throws -> [AnyCommandParser] {
        try mapPlugins { path, name in
            if let plugin = try? dependencies.helpParser.parse(path: path, command: name) {
                return plugin
            }
            else {
                throw Error.brokenPlugin(path + name)
            }
        }
    }

    private func mapPlugins<Value>(_ handler: (String, String) throws -> Value) throws -> [Value] {
        guard let pluginFiles = try? dependencies.fileHelper.contentsOfDirectory(at: Constants.pluginsPath) else {
            return []
        }
        return try pluginFiles.map { file in
            let url = file.url
            let name = url.lastPathComponent
            var path = url.deletingLastPathComponent().path
            if path.last != "/" {
                path += "/"
            }

            return try handler(path, name)
        }
    }

    private func mapCommands(runConfig: RunConfig) -> [String: CommandArguments] {
        var result: [String: CommandArguments] = [:]
        let arguments = CommandLine.arguments.dropFirst()
        ([runConfig.general] + runConfig.plugins).forEach { command in
            guard let (matchedCommandArguments, remainingArguments) = command.parse(arguments: [command.name] + arguments),
                  remainingArguments.isEmpty else {
                return
            }

            result[command.name] = matchedCommandArguments
        }
        return result
    }

    private func run(plugin: String) throws {
        let shell = Services.shell
        try shell(loud: "\(Constants.pluginsPath)/\(plugin) \(CommandLine.arguments[1...].joined(separator: " "))")
    }

    private func buildRunConfig(command: ParsableCommand.Type) throws -> RunConfig {
        let parser: HelpParser = Services.helpParser
        let general = try parser.parse(command: command)
        let plugins = try loadPlugins()
        let overrides = Services.configFactory.shared?.overrides ?? [:]
        return .init(general: general, plugins: plugins, overrides: overrides)
    }
}
