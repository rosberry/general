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
        case installation

        var description: String {
            switch self {
            case .noPlugin:
                return "Could not find plugin to install"
            case .installation:
                return "Could not install plugin"
            }
        }
    }

    public static let configuration: CommandConfiguration = .init(abstract: "Adds plugin from repo")

    // MARK: - Parameters

    @Option(name: .shortAndLong, completion: .directory, help: "The path to the plugin binary that should be installed")
    var path: String = FileManager.default.currentDirectoryPath

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Repo with plugin source code. Repo should provide `make build` option that places binary into repo folder root"),
            completion: .templatesRepos)
    var githubPath: String?

    private lazy var fileHelper: FileHelper = .default
    private lazy var helpParser: HelpParser = .init()

    // MARK: - Lifecycle

    public init() {
        //
    }

    public func run() throws {
        if let url = URL(string: path),
           let file = try? fileHelper.fileInfo(with: url),
           file.isDirectory == false {
            return try add(localUrl: url)
        }
        if let repo = self.githubPath {
            return try add(repo: repo)
        }
        throw Error.noPlugin
    }

    // MARK: - Private

    private func add(repo: String) throws {
        // TODO: install from repo
    }

    private func add(localUrl: URL) throws {
        // TODO: Check for overrides
        try copy(localUrl: localUrl)
    }

    private func copy(localUrl: URL) throws {
        let localUrl = URL(fileURLWithPath: localUrl.path)
        let installationDirectoryURL = URL(fileURLWithPath: Constants.pluginsPath)
        let name = localUrl.lastPathComponent
        let installationURL = installationDirectoryURL + name
        do {
            if fileHelper.fileManager.fileExists(atPath: installationDirectoryURL.path) == false {
                try fileHelper.createDirectory(at: installationDirectoryURL)
            }
            try fileHelper.fileManager.copyItem(at: localUrl, to: installationURL)
        }
        catch {
            throw Error.installation
        }
    }
}
