//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public struct GeneralConfig: Codable, CustomStringConvertible {
    public var version: String
    public var templatesRepos: [String: String]
    public var installedPlugins: [Plugin]
    public var defaultCommand: String?
    public var commands: [String: String]

    public init(version: String, templatesRepos: [String: String], installedPlugins: [Plugin], defaultCommand: String?, commands: [String: String]) {
        self.version = version
        self.templatesRepos = templatesRepos
        self.installedPlugins = installedPlugins
        self.defaultCommand = defaultCommand
        self.commands = commands
    }

    public func addingUnique<Value: Hashable>(_ value: Value, by keyPath: KeyPath<GeneralConfig, [Value]>) -> [Value] {
        Array(Set(self[keyPath: keyPath] + [value]))
    }

    public var description: String {
        return """
               version: \(green(version))
               templates repos: \(templatesReposDescription)
               installed plugins: \(installedPluginsDescription)
               default command: \(defaultCommandDescription)
               commands: \(commandsDescripntion)
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

    private var installedPluginsDescription: String {
        guard !installedPlugins.isEmpty else {
            return yellow("no plugins installed")
        }
        return green(installedPlugins.map(\.name).joined(separator: ", "))
    }

    private var defaultCommandDescription: String {
        if let command = defaultCommand {
            return green(command)
        }
        else {
            return yellow("not configured")
        }
    }

    private var commandsDescripntion: String {
        guard !commands.isEmpty else {
            return yellow("no custom commands specified")
        }
        return green(commands.keys.joined(separator: ", "))
    }
}
