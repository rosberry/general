//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

final class GeneralIOS: ParsableCommand {
    static var configuration: CommandConfiguration {

        return .init(abstract: "Generates code from templates.",
                     version: "0.0.1",
                     subcommands: [Generate.self, Setup.self],
                     defaultSubcommand: Generate.self)
    }
}
