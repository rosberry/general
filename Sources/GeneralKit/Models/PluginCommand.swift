//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public struct PluginCommand: Codable, Equatable, CustomStringConvertible {

    public let name: String
    public let executable: String

    public init(name: String, executable: String) {
        self.name = name
        self.executable = executable
    }
}
