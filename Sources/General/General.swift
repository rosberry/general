//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

final class General: ParsableCommand {

    static var configuration: CommandConfiguration {
        let config = ConfigFactory.default
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
                                  Spec.self,
                                  List.self,
                                  Setup.self,
                                  Upgrade.self,
                                  Add.self],
                    defaultSubcommand: defaultCommand)
    }
}
