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
        try fetchPluginsMeta()
        let plugin = try findPlugin()
        // TODO: Return to current
        try upgradeService.upgrade(to: .concrete("feature/xcode-independent"), customizationHandler: {
            try self.install(plugin)
        })
    }

    // MARK: - Private

    private func install(_ plugin: Plugin) throws {
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

    private func fetchPluginsMeta() throws {
        guard let repo = githubPath else {
            return
        }
        print("Fetching plugins from \(repo)")
        try githubService.downloadFiles(at: repo, to: "\(Constants.pluginsPath)/\(makeFolderName(repo: repo))")
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
            guard file.isExists, file.isDirectory else {
                return
            }
            let commandFiles = try fileHelper.contentsOfDirectory(at: file.url)
            plugins.append(contentsOf: commandFiles.compactMap { file in
                let name = file.url.deletingPathExtension().lastPathComponent
                return .init(name: name, repo: repo, package: product)
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
