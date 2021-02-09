//
//  Copyright © 2021 Rosberry. All rights reserved.
//


public struct GeneralConfig: Codable {
    public var version: String
    public var templatesRepo: String?
    public var availablePlugins: [Plugin]
    public var installedPlugins: [Plugin]
    public var pluginsRepos: [String]
    public var defaultCommand: String?
    public var commands: [String: String]

    public func addingUnique<Value: Hashable>(_ value: Value, by keyPath: KeyPath<GeneralConfig, [Value]>) -> [Value] {
        Array(Set(self[keyPath: keyPath] + [value]))
    }
}
