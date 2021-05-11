//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public final class Setup: ParsableCommand {

    public static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                           abstract: "Provides your environment with templates")

    private lazy var setupService: SetupService = .init()

    // MARK: - Parameters

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Fetch templates from specified github repo." +
                            " Format: \"<github>\\ [branch]\"."),
            completion: .templatesRepos)
    var githubPath: String

    @Option(name: [.customLong("global"), .customShort("g")],
            help: "If specified loads templates into user home directory")
    var shouldLoadGlobally: Bool = false

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        try setupService.setup(githubPath: githubPath,
                               shouldLoadGlobally: shouldLoadGlobally)
    }
}
