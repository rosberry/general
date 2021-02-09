//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

public final class Setup: ParsableCommand {

    enum Error: Swift.Error, CustomStringConvertible {
        case loadSpec(URL)

        var description: String {
            switch self {
            case let .loadSpec(url):
                return "Could not load spec from url `\(url)`"
            }
        }
    }

    public static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                           abstract: "Provides your environment with templates")

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Fetch templates from specified github repo." +
                " Format: \"<github>\\ [branch]\"."))
    var githubPath: String

    @Option(name: [.customLong("global"), .customShort("g")],
            help: "If specified loads templates into user home directory")
    var shouldLoadGlobally: Bool = false

    @Option(name: [.customLong("platform"), .customShort("p")],
            help: "Configures provide platform specific specs. Currently supported platforms: iOS, macOS")
    var platform: String?

    private lazy var specFactory: SpecFactory = .init()
    private lazy var githubService: GithubService = .init()
    private lazy var fileHelper: FileHelper = .default

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        let url = try githubService.getGitRepoPath(githubPath: githubPath)
        let files = try downloadFiles(from: url)
        displayResult(files)
    }

    // MARK: - Private

    private func downloadFiles(from path: String) throws -> [FileInfo] {
        print("Loading setup files from \(path)...")
        let destination = getTemplatesDestination()

        return try githubService.downloadFiles(at: path,
                                               to: destination.path,
                                               askForUpdate: { old, new in
            guard isGeneralSpec(old) == false else {
                return askBool(question: "General spec already exists. Do you want to replace it? (Yes, No)")
            }
            return askBool(question: "Could not compare downloaded template" +
                                     green(destination.lastPathComponent) +
                                     " with installed one. Do you want to replace it? (Yes, No)")
        }, matchHandler: { file in
            isGeneralSpec(file) || isTemplatesFolder(file)
        })
    }

    private func isGeneralSpec(_ file: FileInfo) -> Bool {
        file.url.lastPathComponent == Constants.generalSpecName
    }

    private func isTemplatesFolder(_ file: FileInfo) -> Bool {
        file.isDirectory && fileHelper.fileManager.fileExists(atPath: (file.url + Constants.specFilename).path)
    }

    private func getTemplatesDestination() -> URL {
        if shouldLoadGlobally {
            return fileHelper.fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        }
        else {
            return URL(fileURLWithPath: Constants.relativeCurrentPath + Constants.templatesFolderName)
        }
    }

    private func displayResult(_ templates: [FileInfo]) {
        print()
        if templates.isEmpty {
            print(yellow("No templates modified 🤷‍♂️"))
        }
        else {
            print("✨ Updated templates:")
            templates.forEach { file in
                print(green(file.url.lastPathComponent))
            }
        }
    }
}
