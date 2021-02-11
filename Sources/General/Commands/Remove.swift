//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

final class Remove: ParsableCommand {

    public static let configuration: CommandConfiguration = .init(abstract: "Removes installed plugin")
    // MARK: - Parameters

    @Argument(help: "Specifies the name of plugin that should be installed",
              completion: .installedPlugins)
    var pluginName: String

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        let defaultConfig = ConfigFactory.default
        try updateConfig { config in
            var config = config
            let installedPlugin = config.installedPlugins.first { plugin in
                 plugin.name == pluginName
            }
            guard let plugin = installedPlugin else {
                print(yellow("Could not find installed plugin with name `\(pluginName)`"))
                return config
            }
            config.installedPlugins.removeAll { plugin in
                plugin == installedPlugin
            }
            config.availablePlugins.append(plugin)
            config.commands[plugin.command] = defaultConfig.commands[plugin.command]
            print(green("Plugin `\(pluginName)` removed"))
            return config
        }
    }
}
