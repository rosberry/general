//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

final class Config: ParsableCommand {

    private class Print: ParsableCommand {

        // swiftlint:disable:next nesting
        enum Error: Swift.Error, CustomStringConvertible {
            case config

            var description: String {
                switch self {
                case .config:
                    return "Cold not read a `.config` file. Try run `general config reset`"
                }
            }
        }

        static let configuration: CommandConfiguration = .init(abstract: "Displays general config")

        required init() {
            //
        }

        func run() throws {
            let config = try self.config()
            print(config.description)
        }
    }

    private class Reset: ParsableCommand {
        static let configuration: CommandConfiguration = .init(abstract: "Resets general config")
        // swiftlint:disable:next nesting
        typealias Dependencies = HasFileHelper

        private var dependencies: Dependencies {
            Services
        }

        required init() {
            //
        }

        func run() throws {
            try dependencies.fileHelper.removeFile(at: URL(fileURLWithPath: Constants.configPath))
            print(green("General config is reset"))
        }
    }

    private class Repo: ParsableCommand {
        static let configuration: CommandConfiguration = .init(abstract: "Allows to add templates repo for easy setup")

        @Argument(help: .init(stringLiteral: "Specifies templates location"))
        var githubPath: String

        @Option(name: [.customLong("as")],
                help: .init(stringLiteral: "Specifies short repo alias"))
        var alias: String?

        required init() {
            //
        }

        func run() throws {
            try updateConfig { config in
                var config = config
                config.templatesRepos[alias ?? githubPath] = githubPath
                return config
            }

            if let alias = self.alias {
                print(green("Repo \"\(githubPath)\" is linked with \"\(alias)\" alias"))
            }
            else {
                print(green("Repo \"\(githubPath)\" is linked for later usage"))
            }
        }
    }

    private final class Use: ParsableCommand {
        // swiftlint:disable:next nesting
        typealias Dependencies = HasConfigFactory

        private var dependencies: Dependencies {
            Services
        }

        static let configuration: CommandConfiguration = .init(abstract: "Set default executable instance for specific command")

        @Option(name: .shortAndLong, help: "The executable instance for the command", completion: .executables)
        var executable: String

        @Option(name: .customLong("for"), help: "The name on the command")
        var command: String

        func run() throws {
            try dependencies.configFactory.update { config in
                var config = config
                config.overrides[command] = executable
                return config
            }
            print("`\(executable)` is choosen as default executable for the command `\(command)`")
        }
    }

    static var configuration: CommandConfiguration {
        return .init(abstract: "Provides an access to general config",
                     subcommands: [Print.self, Reset.self, Repo.self, Use.self],
                     defaultSubcommand: Print.self)
    }
}
