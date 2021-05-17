//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

public final class Setup: ParsableCommand {

    enum Error: Swift.Error, CustomStringConvertible {
        case github
        case loadSpec(URL)
        case noName

        var description: String {
            switch self {
            case .github:
                return "Templates repo was not specified"
            case let .loadSpec(url):
                return "Could not load spec from url `\(url)`"
            case .noName:
                return "Cold not setup xcode spec: no name provided"
            }
        }
    }

    public static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                                  abstract: "Provides your environment with templates")

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Fetch templates from specified github repo." +
                " Format: \"<github>\\ [branch]\"."),
            completion: .templatesRepos)
    var githubPath: String?

    @Option(name: [.customLong("global"), .customShort("g")],
            help: "If specified loads templates into user home directory")
    var shouldLoadGlobally: Bool = false

    @Option(name: [.customLong("xcodeproj"), .customShort("x")],
            help: "Configures name of .xcdoeproj file where files should be plased")
    var xcodeProject: String?

    @Option(name: [.customLong("target"), .customShort("t")],
            help: "Configures xcode project target where generated files should be placed")
    var target: String?

    @Option(name: [.customLong("company"), .customShort("c")],
            help: "Configures company name that will be placed in file headers")
    var company: String?

    private lazy var setupService: SetupService = .init()
    private lazy var specFactory: SpecFactory = .init()

    // MARK: - Lifecycle

    public init() {
        //
    }

    public func run() throws {
        if self.githubPath == nil {
            self.githubPath = ask("Please provide a path to repo with templates")
            print("You can use the command `general config repo <repo> --as <alias>` to use it later by the easiest way")
        }
        guard let githubPath = self.githubPath else {
            throw Error.github
        }
        try setupService.setup(githubPath: githubPath, shouldLoadGlobally: shouldLoadGlobally) { files in
            let specFile = files.first { file in
                file.url.lastPathComponent == Constants.generalSpecName
            }
            if let file = specFile {
                try self.updateSpec(file)
            }
        }
    }

    // MARK: - Private

    private func updateSpec(_ file: FileInfo) throws {
        guard var spec: GeneralSpec = try? specFactory.makeSpec(url: file.url) else {
            throw Error.loadSpec(file.url)
        }
        guard let name = xcodeProject ?? askProject() else {
            throw Error.noName
        }
        let target = self.target ?? ask("Target (optional)")
        let company = self.company ?? ask("Company (optional)", default: spec.xcode.company)
        spec.xcode = .init(name: name, target: target, company: company)
        guard let data = try? specFactory.makeData(spec: spec) else {
            throw Error.loadSpec(file.url)
        }
        try data.write(to: file.url)
    }
}
