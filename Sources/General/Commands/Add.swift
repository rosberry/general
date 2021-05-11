//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import Yams

public final class Add: ParsableCommand {

    enum Error: Swift.Error, CustomStringConvertible {
        case noPlugin
        case noPackageSwift
        case noSwiftPackageValue(String)
        case installation

        var description: String {
            switch self {
            case .noPlugin:
                return "Could not find plugin to install"
            case .noPackageSwift:
                return "Could not locate Package.swift"
            case let .noSwiftPackageValue(value):
                return "Package.swift does not declares value \(value)"
            case .installation:
                return "Could not install plugin"
            }
        }
    }

    public static let configuration: CommandConfiguration = .init(abstract: "Adds plugin from repo")

    // MARK: - Parameters

    @Argument(help: "Specifies the name of plugin that should be applied",
              completion: .installedPlugins)
    var pluginName: String?

    @Option(name: [.customLong("commands"), .customShort("c")],
            help: .init(stringLiteral: "Specifies concrere plugin commands that should be installed"))
    var commands: String?

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral: "Fetch plugin from specified github repo. Format: \"<github>\\ [branch]\"."))
    var githubPath: String?

    @Option(name: [.customLong("force"), .customShort("f")],
            help: .init(stringLiteral: "Rebuilds general completely event it is already complied with specified plugin"))
    var shouldForceReuild: Bool = false

    private lazy var upgradeService: UpgradeService = .init()
    private lazy var insertStringService: InsertStringService = .init()
    private lazy var githubService: GithubService = .init()
    private lazy var fileHelper: FileHelper = .default
    private lazy var shell: Shell = .init()

    // MARK: - Lifecycle

    public init() {
        //
    }

    public func run() throws {
        let config = try self.config()
        do {
            let availabelePlugins = try fetchPluginsMeta()
            let plugins = try findMatchPlugins(in: availabelePlugins)

            func updateSourceCode() throws {
                try plugins.forEach(self.updateSourceCode)
            }

            func needUpgrade() -> Bool {
                shouldForceReuild || !config.installedPlugins.contains(where: isPluginMatch)
            }

            if needUpgrade() {
                // TODO: Return to current
                try upgradeService.upgrade(to: .concrete("feature/xcode-independent"),
                                           customizationHandler: updateSourceCode)
            }
            try plugins.forEach(self.registerCommands)
        }
        catch {
            try updateConfig { _ in
                config
            }
            throw error
        }
        print(green("Plugin `\(pluginName ?? githubPath ?? "")` is successfully installed"))
    }

    // MARK: - Private

    private func isPluginMatch(_ plugin: Plugin) -> Bool {
        plugin.name == (pluginName ?? plugin.name) && plugin.repo == (githubPath ?? plugin.repo)
    }

    private func updateSourceCode(with plugin: Plugin) throws {
        let url = URL(fileURLWithPath: Constants.downloadedSourcePath)
        guard let swiftPackageFile = try? fileHelper.fileInfo(with: url + Constants.packageSwiftPath),
            let generalFile = try? fileHelper.fileInfo(with: url + Constants.generalSwiftPath) else {
                throw Error.installation
        }

        try insertStringService.insert(string: "\"\(plugin.name)\"",
                                       template: Constants.targetDependencyTemplate,
                                       file: swiftPackageFile,
                                       terminator: ",")

        try insertStringService.insert(string: makePackageDependency(plugin),
                                       template: Constants.packageDependencyTemplate,
                                       file: swiftPackageFile,
                                       terminator: ",")

        try insertStringService.insert(string: "import \(plugin.name)",
                                       template: Constants.importDependencyTemplate,
                                       file: generalFile)

        try updateConfig { config in
            var config = config
            config.installedPlugins = config.addingUnique(plugin, by: \.installedPlugins)
            return config
        }
    }

    private func registerCommands(with plugin: Plugin) throws {
        try updateConfig { config in
            var config = config
            plugin.commands.forEach { command in
                if config.commands[command.executable] != nil,
                    askBool(question: "Command `\(command.name)` from plugin `\(plugin.name)` overrides current command. Do you want to continue?") {
                    config.commands[command.executable] = "\(plugin.name).\(command.name)"
                }
            }
            return config
        }
    }

    private func fetchPluginsMeta() throws -> [Plugin] {
        try downloadPluginIfNeeded()
        let files = try fileHelper.contentsOfDirectory(at: Constants.pluginsPath)
        var availablePlugins = [Plugin]()
        try files.forEach { file in
            guard file.isDirectory else {
                return
            }
            let plugins = try parsePlugins(directory: file)
            availablePlugins.append(contentsOf: plugins)
        }
        return availablePlugins
    }

    private func downloadPluginIfNeeded() throws {
        guard let githubPath = githubPath else {
            return
        }
        print("Fetching plugins from \(githubPath)")
        let folder = "\(Constants.pluginsPath)/\(makeFolderName(repo: githubPath))"
        try githubService.downloadFiles(at: githubPath, to: folder)
        try githubPath.data(using: .utf8)?.write(to: .init(fileURLWithPath: "\(folder)/.git_source"))
    }

    private func findMatchPlugins(in plugins: [Plugin]) throws -> [Plugin] {
        let plugins = plugins.filter(isPluginMatch)
        guard !plugins.isEmpty else {
            throw Error.noPlugin
        }
        return plugins
    }

    private func makeFolderName(repo: String) -> String {
        return repo.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "/", with: "-")
    }

    private func parsePlugins(directory: FileInfo) throws -> [Plugin] {
        let packageSwift = try parsePackageSwift(directory: directory)
        let products = try mapValues(in: packageSwift, arrayName: "products", valueName: "name")
        return try products.compactMap { product in
            let file = try fileHelper.fileInfo(with: directory.url + "Sources/\(product)/Commands")
            guard file.isExists,
                  file.isDirectory,
                let repo = try? String(contentsOf: directory.url + ".git_source") else {
                return nil
            }
            let commandFiles = try fileHelper.contentsOfDirectory(at: file.url)
            return self.parsePlugin(commandFiles, product: product, repo: repo)
        }
    }

    private func parsePackageSwift(directory: FileInfo) throws -> [String: Any] {
        guard let packageSwiftFile = try? fileHelper.fileInfo(with: directory.url + Constants.packageSwiftPath),
              packageSwiftFile.isExists,
              let dump = try? shell(silent: "cd \(directory.url.path); swift package dump-package"),
              dump.status == 0,
              let data = dump.stdOut.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.noPackageSwift
        }
        return result
    }

    private func parsePlugin(_ files: [FileInfo], product: String, repo: String) -> Plugin? {
        let commands: [PluginCommand] = files.compactMap { file in
            let name = file.url.deletingPathExtension().lastPathComponent
            let executable = parseCommandExecutablle(in: file) ?? name.lowercased()
            return .init(name: name, executable: executable)
        }
        return Plugin(name: product, commands: commands, repo: repo)
    }

    private func parseCommandExecutablle(in file: FileInfo) -> String? {
        guard let sourceCode = try? String(contentsOf: file.url) else {
            return nil
        }
        let patterns = [":\\s*CommandConfiguration\\s*=.*\\s*\\(commandName:\\s*\"([a-zA-Z]+)\"",
                        "=\\s*CommandConfiguration\\s*\\(commandName:\\s*\"([a-zA-Z]+)\""]
        return parseFirstRegexMatch(patterns: patterns, rangeIndex: 1, string: sourceCode)
    }

    private func mapValues(in packageSwift: [String: Any], arrayName: String, valueName: String) throws -> [String] {
        guard let products = packageSwift[arrayName] as? [[String: Any]] else {
            throw Error.noSwiftPackageValue(arrayName)
        }
        return products.compactMap { product in
            product[valueName] as? String
        }
    }

    private func makePackageDependency(_ plugin: Plugin) -> String {
        let components = plugin.repo.split(separator: " ")
        let gitPath = "https://github.com/\(components[0]).git"
        if components.count == 2 {
            // TODO: Switch to upToNextMajors
            return ".package(url: \"\(gitPath)\", .branch(\"\(components[1])\"))"
        }
        else {
            return ".package(url: \"\(gitPath)\")"
        }
    }
}
