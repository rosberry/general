//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

public final class RunConfig {
    let general: AnyCommand
    let plugins: [AnyCommand]
    let overrides: [String: String]

    init(general: AnyCommand, plugins: [AnyCommand], overrides: [String: String]) {
        self.general = general
        self.plugins = plugins
        self.overrides = overrides
    }
}

final class General: ParsableCommand {

    public static var runConfig: RunConfig? = try? buildRunConfig()

    static var configuration: CommandConfiguration {
        let version = "0.3.2"
        ConfigFactory.default = .init(version: version, templatesRepos: [:], pluginRepos: [:], overrides: [:])
        return .init(abstract: "Generates code from templates.",
                     version: "0.3.2",
                     subcommands: [Generate.self,
                                   Create.self,
                                   List.self,
                                   Setup.self,
                                   Config.self,
                                   Upgrade.self],
                     defaultSubcommand: Generate.self)
    }

    init() {

    }

    private static func loadPlugins() -> [AnyCommand] {
        let fileHelper = FileHelper.default
        let parser: HelpParser = .init()
        guard let pluginFiles = try? fileHelper.contentsOfDirectory(at: Constants.pluginsPath) else {
            return []
        }
        return pluginFiles.compactMap { file in
            let url = file.url
            let name = url.lastPathComponent
            var path = url.deletingLastPathComponent().path
            if path.last != "/" {
                path += "/"
            }
            let plugin = try? parser.parse(path: path, command: name)
            return plugin
        }
    }

    private static func buildRunConfig() throws -> RunConfig {
        let parser: HelpParser = .init()
        let general = try parser.parse(command: General.self)
        let plugins = loadPlugins()
        let overrides = ConfigFactory.default?.overrides ?? [:]
        return .init(general: general, plugins: plugins, overrides: overrides)
    }
}
