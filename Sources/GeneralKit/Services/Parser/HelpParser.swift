//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public protocol HasHelpParser {
    var helpParser: HelpParser { get }
}

public protocol HelpParser {
    func parse(path: String?, command: String) throws -> AnyCommandParser
    func parse(command: ParsableCommand.Type) throws -> AnyCommandParser
}

public extension HelpParser {
    func parse(command: String) throws -> AnyCommandParser {
        try self.parse(path: nil, command: command)
    }
}
