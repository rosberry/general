//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public struct Plugin: Codable, Hashable, CustomStringConvertible {
    public let name: String
    public let commands: [PluginCommand]
    public let repo: String

    public init(name: String, commands: [PluginCommand], repo: String) {
        self.name = name
        self.commands = commands
        self.repo = repo
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(repo)
    }
}
