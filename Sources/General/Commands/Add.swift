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

        var description: String {
            switch self {
            case .noPlugin:
                return "Could not find plugin to install"
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

    private lazy var githubService: GithubService = .init()
    private lazy var fileHelper: FileHelper = .default
    private lazy var upgradeService: UpgradeService = .init()

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        guard try isAllowedToInstall() else {
            return
        }
        try installPlugin()
    }

    // MARK: - Private

    private func isAllowedToInstall() throws -> Bool {
        guard try findInstalledPlugin() != nil else {
            return true
        }
        return askBool(question: "This action will replace currently installed plugin. Do you want to continue [yes, no]?")
    }

    private func findInstalledPlugin() throws -> Plugin? {
        findCandidates(in: try config().installedPlugins).first
    }

    private func installPlugin() throws {
        let plugin = try findPluginToInstall()
        try upgradeService.upgrade(to: .current) {
            try self.updateDependencies(with: plugin)
            try self.updateConfig(with: plugin)
        }
    }

    private func findPluginToInstall() throws -> Plugin {
        var plugins = try findCandidates()
        if plugins.isEmpty {
            plugins = try loadCandidates()
        }
        guard let plugin = askChoice("More than one acceptible plugin was found", values: plugins) else {
            throw Error.noPlugin
        }
        return plugin
    }

    private func findCandidates() throws -> [Plugin] {
        findCandidates(in: try config().availablePlugins)
    }

    private func loadCandidates() throws -> [Plugin] {
        guard let repo = githubPath ?? ask("Could not locate required plugin. Please specify the repo:") else {
            return []
        }
        let plugins = try githubService.downloadFiles(at: repo,
                                                      to: Constants.pluginsPath,
                                                      matchHandler: isPlugin).compactMap(loadPlugin)

        try save(repo: repo, plugins: plugins)
        return findCandidates(in: plugins)
    }

    private func findCandidates(in plugins: [Plugin]) -> [Plugin] {
        var result = [Plugin]()
        plugins.forEach { plugin in
            if plugin.name == pluginName,
               (githubPath ?? plugin.repo) == plugin.repo {
                result.append(plugin)
            }
        }
        return result
    }

    private func isPlugin(_ file: FileInfo) -> Bool {
        return pluginSpec(with: file) != nil
    }

    private func loadPlugin(with file: FileInfo) throws -> Plugin? {
        guard let spec = pluginSpec(with: file),
              let string = try? String(contentsOf: spec.url) else {
            return nil
        }
        let decoder = YAMLDecoder()
        return try decoder.decode(from: string)
    }

    private func pluginSpec(with file: FileInfo) -> FileInfo? {
        let specURL = file.url + Constants.specFilename
        guard file.isDirectory && fileHelper.fileManager.fileExists(atPath: specURL.path) else {
            return nil
        }
        return try? fileHelper.fileInfo(with: specURL)
    }

    private func save(repo: String, plugins: [Plugin]) throws {
        try ConfigFactory.update { config in
            var config = config
            config.pluginsRepos = config.addingUnique(repo, by: \.pluginsRepos)
            return config
        }
    }

    private func updateDependencies(with plugin: Plugin) throws {
        // TODO:
    }

    private func updateConfig(with plugin: Plugin) throws {
        // TODO:
    }
}
