//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import GeneralKit
import ArgumentParser

public final class Setup: ParsableCommand {

    enum Error: Swift.Error {
        case github

        var description: String {
            switch self {
            case .github:
                return "Templates repo was not specified"
            }
        }
    }

    public typealias Dependencies = HasSetupService

    public static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                                  abstract: "Provides your environment with templates",
                                                                  subcommands: [Shared.self])

    private lazy var setupService: SetupService = dependencies.setupService

    private var dependencies: Dependencies {
        Services
    }

    // MARK: - Parameters

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Fetch templates from specified github repo." +
                            " Format: \"<github>\\ [branch]\"."),
            completion: .templatesRepos)
    var githubPath: String?

    @Option(name: [.customLong("global"), .customShort("g")],
            help: "If specified loads templates into user home directory")
    var shouldLoadGlobally: Bool = false

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        if self.githubPath == nil {
            self.githubPath = ask("Please provide a path to repo with templates")
            print("You can use the command `general config repo <repo> --as <alias>` to use it later by the easiest way")
        }
        guard let githubPath = self.githubPath else {
            throw Error.github
        }
        try setupService.setup(githubPath: githubPath,
                               shouldLoadGlobally: shouldLoadGlobally)
    }
}


public final class Shared: ParsableCommand {

    public final class Setup: ParsableCommand {

        public static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                                      abstract: "Applies shared setup")

        public typealias Dependencies = HasSetupService

        @Option(name: [.customLong("repo"), .customShort("r")],
                help: .init(stringLiteral: "GitHub repo with shared configuration"),
                completion: .templatesRepos)
        var githubPath: String

        private var dependencies: Dependencies {
            Services
        }

        // MARK: - Lifecycle

        public init() {
        }

        public func run() throws {
            try dependencies.setupService.setupShared(githubPath: githubPath)
        }
    }

    public static let configuration: CommandConfiguration = .init(commandName: "shared",
                                                                  abstract: "Applies shared setup",
                                                                  subcommands: [Setup.self])
    // MARK: - Lifecycle

    public init() {
    }
}
