//
//  Copyright © 2021 Rosberry. All rights reserved.
//


public struct GeneralConfig: Codable {
    var version: String
    var templatesRepo: String?
    var availablePlugins: [Plugin]
    var installedPlugins: [Plugin]
    var pluginsRepos: [String]
    var defaultCommand: String?
    var commands: [String: String]

    func addingUnique<Value: Hashable>(_ value: Value, by keyPath: KeyPath<GeneralConfig, [Value]>) -> [Value] {
        Array(Set(self[keyPath: keyPath] + [value]))
    }
}
