//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import Yams
import GeneralKit

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

    // MARK: - Parameters

    public static let configuration: CommandConfiguration = .init(abstract: "Adds plugin from repo")

    @Argument(help: "Specifies the name of plugin that should be installed",
              completion: .plugins)
    var pluginName: String

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Fetch plugin from specified github repo." +
                " Format: \"<github>\\ [branch]\"."), completion: .pluginsRepos)
    var githubPath: String?

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
            try fetchPluginsMeta()
            let plugin = try findPlugin()
            // TODO: Return to current
            try upgradeService.upgrade(to: .concrete("feature/xcode-independent"), customizationHandler: {
                try self.install(plugin)
            })
        }
        catch {
            try updateConfig { _ in
                config
            }
            throw error
        }
    }

    // MARK: - Private

    private func install(_ plugin: Plugin) throws {
        try updateSourceCode(with: plugin)
        try registerCommand(with: plugin)
    }

    private func updateSourceCode(with plugin: Plugin) throws {
        let url = URL(fileURLWithPath: Constants.downloadedSourcePath)
        guard let swiftPackageFile = try? fileHelper.fileInfo(with: url + Constants.packageSwiftPath),
            let generalFile = try? fileHelper.fileInfo(with: url + Constants.generalSwiftPath) else {
                throw Error.installation
        }

        try insertStringService.insert(string: "\"\(plugin.package)\"",
                                       template: Constants.targetDependencyTemplate,
                                       file: swiftPackageFile,
                                       terminator: ",")

        try insertStringService.insert(string: makePackageDependency(plugin),
                                       template: Constants.packageDependencyTemplate,
                                       file: swiftPackageFile,
                                       terminator: ",")

        try insertStringService.insert(string: "import \(plugin.package)",
                                       template: Constants.importDependencyTemplate,
                                       file: generalFile)

        try updateConfig { config in
            var config = config
            config.installedPlugins.append(plugin)
            config.availablePlugins.removeAll { availablePlugin in
                availablePlugin == plugin
            }
            return config
        }
    }

    private func registerCommand(with plugin: Plugin) throws {
        try updateConfig { config in
            var config = config
            if config.commands[plugin.command] != nil,
                askBool(question: "Plugin `\(plugin.name)` overrides current command `\(plugin.command)`. Do you want to continue?") {
                config.commands[plugin.command] = "\(plugin.package).\(plugin.name)"
            }
            return config
        }
    }

    private func fetchPluginsMeta() throws {
        guard let repo = githubPath else {
            return
        }
        print("Fetching plugins from \(repo)")
        let folder = "\(Constants.pluginsPath)/\(makeFolderName(repo: repo))"
        try githubService.downloadFiles(at: repo, to: folder)
        try repo.data(using: .utf8)?.write(to: .init(fileURLWithPath: "\(folder)/.git_source"))
        let files = try fileHelper.contentsOfDirectory(at: Constants.pluginsPath)
        var availablePlugins = [Plugin]()
        try files.forEach { file in
            guard file.isDirectory else {
                return
            }
            let plugins = try parsePlugins(repo: repo, directory: file)
            availablePlugins.append(contentsOf: plugins)
        }
        try updateConfig { config in
            var config = config
            config.availablePlugins = availablePlugins.filter { plugin in
                !config.installedPlugins.contains(plugin)
            }
            return config
        }
    }

    private func findPlugin() throws -> Plugin {
        let plugins = try self.config().availablePlugins.filter { plugin in
            plugin.name == pluginName
        }
        guard !plugins.isEmpty,
              let plugin = askChoice("More the one plugin with name `\(pluginName)` was found. Please selecect one", values: plugins) else {
            throw Error.noPlugin
        }
        return plugin
    }

    private func makeFolderName(repo: String) -> String {
        return repo.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "/", with: "-")
    }

    private func parsePlugins(repo: String, directory: FileInfo) throws -> [Plugin] {
        let packageSwift = try parsePackageSwift(directory: directory)
        let products = try mapValues(in: packageSwift, arrayName: "products", valueName: "name")
        var plugins = [Plugin]()
        try products.forEach { product in
            let file = try fileHelper.fileInfo(with: directory.url + "Sources/\(product)/Commands")
            guard file.isExists,
                  file.isDirectory,
                let repo = try? String(contentsOf: directory.url + ".git_source") else {
                return
            }
            let commandFiles = try fileHelper.contentsOfDirectory(at: file.url)
            plugins.append(contentsOf: commandFiles.compactMap { file in
                self.parsePlugin(file, product: product, repo: repo)
            })
        }
        return plugins
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

    private func parsePlugin(_ file: FileInfo, product: String, repo: String) -> Plugin? {
        let name = file.url.deletingPathExtension().lastPathComponent
        let command = parseCommandName(in: file) ?? name.lowercased()
        return Plugin(name: name, command: command, repo: repo, package: product)
    }

    private func parseCommandName(in file: FileInfo) -> String? {
        guard let sourceCode = try? String(contentsOf: file.url) else {
            return nil
        }
        let patterns = [":\\s*CommandConfiguration\\s*=.*\\s*\\(commandName:\\s*\"([a-zA-Z]+)\"",
                        "=\\s*CommandConfiguration\\s*\\(commandName:\\s*\"([a-zA-Z]+)\""]
        let commands = patterns.compactMap { pattern in
            parse(pattern: pattern, rangeIndex: 1, string: sourceCode)
        }
        return commands.first
    }

    private func parse(pattern: String, rangeIndex: Int, string: String) -> String? {
        let fullRange = NSRange(location: 0, length: string.utf16.count)
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, options: [], range: fullRange),
              let range = Range(match.range(at: rangeIndex), in: string) else {
            return nil
        }
        return String(string[range])
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
