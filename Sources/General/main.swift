//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import GeneralKit
import Foundation

func mapCommands(runConfig: RunConfig) -> [String: CommandArguments] {
    var result: [String: CommandArguments] = [:]
    let arguments = Array(CommandLine.arguments.dropFirst())
    ([runConfig.general] + runConfig.plugins).forEach { command in
        guard let parseResult = command.parse(arguments: [command.name] + arguments),
              parseResult.1.isEmpty else {
            return
        }

        result[command.name] = parseResult.0
    }
    return result
}

func definePlugin(commands: [String: CommandArguments], runConfig: RunConfig) -> String? {
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

func run(plugin: String) throws {
    let shell = Services.shell
    try shell(loud: "\(Constants.pluginsPath)/\(plugin) \(CommandLine.arguments[1...].joined(separator: " "))")
}

if let runConfig = General.runConfig,
   let plugin = definePlugin(commands: mapCommands(runConfig: runConfig),
                             runConfig: runConfig),
   plugin != (General.configuration.commandName ?? String(describing: General.self).lowercased()) {
    try run(plugin: plugin)
}
else {
    General.main()
}
