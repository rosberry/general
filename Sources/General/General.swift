//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

final class General: ParsableCommand {

    static var configuration: CommandConfiguration {
        let version = "0.3.2"
        Services.configFactory.default = .init(version: version, templatesRepos: [:], pluginRepos: [:], overrides: [:])
        return .init(abstract: "Generates code from templates.",
                     version: "0.3.2",
                     subcommands: [Generate.self,
                                   Create.self,
                                   List.self,
                                   Setup.self,
                                   Config.self,
                                   Upgrade.self],
                     defaultSubcommand: Generate.self)
    }
}
