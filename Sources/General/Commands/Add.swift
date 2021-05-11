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

    public static let configuration: CommandConfiguration = .init(abstract: "Adds plugin from repo")

    // MARK: - Parameters

    @Argument(help: "Specifies the name of plugin that should be applied",
              completion: .installedPlugins)
    var pluginName: String?

    @Option(name: [.customLong("commands"), .customShort("c")],
            help: .init(stringLiteral: "Specifies concrere plugin commands that should be installed"))
    var commands: String?

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral: "Fetch plugin from specified github repo. Format: \"<github>\\ [branch]\"."))
    var githubPath: String?

    @Option(name: [.customLong("force"), .customShort("f")],
            help: .init(stringLiteral: "Rebuilds general completely event it is already complied with specified plugin"))
    var shouldForceReuild: Bool = false

    private lazy var upgradeService: UpgradeService = .init()
    private lazy var insertStringService: InsertStringService = .init()
    private lazy var githubService: GithubService = .init()
    private lazy var fileHelper: FileHelper = .default
    private lazy var shell: Shell = .init()
    private lazy var helpParser: HelpParser = .init()

    // MARK: - Lifecycle

    public init() {
        //
    }

    public func run() throws {
        let help = try helpParser.parse(command: "./\(pluginName!)")
        print()
    }

    // MARK: - Private
}
