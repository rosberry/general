//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

final class Config: ParsableCommand {

    private class Print: ParsableCommand {

        enum Error: Swift.Error, CustomStringConvertible {
            case config

            var description: String {
                switch self {
                case .config:
                    return "Cold not read a `.config` file. Try run `general config reset`"
                }
            }
        }

        static let configuration: CommandConfiguration = .init(abstract: "Displays content of .config file")

        required init() {
            //
        }

        func run() throws {
            let config = try self.config()
            print(config.description)
        }
    }

    private class Reset: ParsableCommand {
        static let configuration: CommandConfiguration = .init(abstract: "Sets .config file to its default value")

        required init() {
            //
        }

        func run() throws {
            try FileHelper.default.removeFile(at: .init(fileURLWithPath: Constants.configPath))
            print(green(".config file is set to default value"))
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

    static var configuration: CommandConfiguration {
        return .init(abstract: "Provides an access to config file",
                     subcommands: [Print.self, Reset.self, Repo.self],
                    defaultSubcommand: Print.self)
    }
}
