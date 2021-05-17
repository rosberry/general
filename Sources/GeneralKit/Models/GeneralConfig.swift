//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public struct GeneralConfig: Codable, CustomStringConvertible {
    public var version: String
    public var templatesRepos: [String: String]
    public var pluginRepos: [String: String]
    public var overrides: [String: String]

    public init(version: String,
                templatesRepos: [String: String],
                pluginRepos: [String: String],
                overrides: [String: String]) {
        self.version = version
        self.templatesRepos = templatesRepos
        self.pluginRepos = pluginRepos
        self.overrides = overrides
    }

    public func addingUnique<Value: Hashable>(_ value: Value, by keyPath: KeyPath<GeneralConfig, [Value]>) -> [Value] {
        Array(Set(self[keyPath: keyPath] + [value]))
    }

    public var description: String {
        return """
               version: \(green(version))
               templates repos: \(templatesReposDescription)
               overrides: \(overssidesDescription)
               """
    }

    private var templatesReposDescription: String {
        guard !templatesRepos.isEmpty else {
            return yellow("no repos specified")
        }
        let strings = templatesRepos.map { repo in
            repo.key == repo.value ? "\"\(repo.key)\"" : "\"\(repo.value)\" as \"\(repo.key)\""
        }
        return green(strings.joined(separator: ", "))
    }

    private var pluginReposDescription: String {
        guard !pluginRepos.isEmpty else {
            return yellow("no repos specified")
        }
        let strings = pluginRepos.map { repo in
            repo.key == repo.value ? "\"\(repo.key)\"" : "\"\(repo.value)\" as \"\(repo.key)\""
        }
        return green(strings.joined(separator: ", "))
    }

    private var overssidesDescription: String {
        guard !overrides.isEmpty else {
            return yellow("no overrides specified")
        }
        let strings = overrides.map { override in
            "\"\(override.key)\" : \"\(override.value)\""
        }
        return green(strings.joined(separator: ", "))
    }
}
