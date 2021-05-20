//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit

public final class RunConfig {
    let general: AnyCommandParser
    let plugins: [AnyCommandParser]
    let overrides: [String: String]

    init(general: AnyCommandParser, plugins: [AnyCommandParser], overrides: [String: String]) {
        self.general = general
        self.plugins = plugins
        self.overrides = overrides
    }
}

final class General: ParsableCommand {

    public static var runConfig: RunConfig? = try? buildRunConfig()

    static var configuration: CommandConfiguration {
        let version = "0.3.2"
        Services.configFactory.default = .init(version: version, templatesRepos: [:], pluginRepos: [:], overrides: [:])
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

    private static func loadPlugins() -> [AnyCommandParser] {
        let fileHelper = Services.fileHelper
        let parser: HelpParser = Services.helpParser
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
        let parser: HelpParser = Services.helpParser
        let general = try parser.parse(command: General.self)
        let plugins = loadPlugins()
        let overrides = Services.configFactory.shared?.overrides ?? [:]
        return .init(general: general, plugins: plugins, overrides: overrides)
    }
}
