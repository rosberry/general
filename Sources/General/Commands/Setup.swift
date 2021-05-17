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

    public static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                           abstract: "Provides your environment with templates")

    private lazy var setupService: SetupService = .init()

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
