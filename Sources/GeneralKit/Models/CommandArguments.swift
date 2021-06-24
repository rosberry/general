//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public final class CommandArguments {
    public var options: [String: String]
    public var arguments: [String: String]
    public var subcommands: [String: CommandArguments]

    init(options: [String: String] = [:],
         arguments: [String: String] = [:],
         subcommands: [String: CommandArguments] = [:]) {
        self.options = options
        self.arguments = arguments
        self.subcommands = subcommands
    }
}
