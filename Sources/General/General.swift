//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

final class General: ParsableCommand {

    static var configuration: CommandConfiguration {
        return .init(abstract: "Generates code from templates.",
                     version: version,
                     subcommands: [Generate.self,
                                   Create.self,
                                   List.self,
                                   Setup.self,
                                   Shared.self,
                                   Config.self,
                                   Upgrade.self],
                     defaultSubcommand: Generate.self)
    }

    public static func completionScript(for shell: CompletionShell) -> String {
        return "Hello world"
    }
}
