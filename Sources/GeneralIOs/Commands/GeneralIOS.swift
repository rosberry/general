//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

// TODO: remove test command

final class Test: ParsableCommand {
    public static let configuration: CommandConfiguration = .init(commandName: "test", abstract: "Runs test command for check completions works")

    func run() throws {
        print(green("Test command run"))
    }
}

final class GeneralIOS: ParsableCommand {
    static var configuration: CommandConfiguration {

        return .init(abstract: "Generates code from templates.",
                     version: "0.0.1",
                     subcommands: [Generate.self, Setup.self, Test.self],
                     defaultSubcommand: Generate.self)
    }
}
