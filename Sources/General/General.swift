//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit
import GeneralIOs
// {% PluginImport %}

final class General: ParsableCommand {

    static var configuration: CommandConfiguration {
        ConfigFactory.default = .init(version: Constants.version,
                                      installedPlugins: [.init(name: "GeneralIOs",
                                                               commands: [.init(name: "Generate", executable: "gen"),
                                                                          .init(name: "Setup", executable: "setup")],
                                                               repo: "rosberry/GeneralIOs")],
                                      defaultCommand: "gen",
                                      commands: ["gen": "General.Generate",
                                                 "setup": "General.Setup"])

        let config = ConfigFactory.shared
        var commands = [ParsableCommand.Type]()
        var defaultCommand: ParsableCommand.Type?

        let commandsMap = config?.commands.compactMapValues({ className in
            NSClassFromString(className) as? ParsableCommand.Type
        })

        if let map = commandsMap {
            commands = Array(map.values)
            if let key = config?.defaultCommand {
                defaultCommand = map[key]
            }
        }

        return .init(abstract: "Generates code from templates.",
                     version: Constants.version,
                    subcommands: commands +
                                 [Create.self,
                                  List.self,
                                  Upgrade.self,
                                  Add.self,
                                  Remove.self],
                    defaultSubcommand: defaultCommand)
    }
}
