//
//  Copyright © 2020 Rosberry. All rights reserved.
//
import Foundation
import ArgumentParser
import ZIPFoundation

final class Setup: ParsableCommand {

    enum Error: Swift.Error {
        case githubName(_ github: String)
        case url(_ url: String)
        case download(_ url: URL)
        case write(_ url: URL)
        case remove(_ url: URL)
    }

    static let configuration: CommandConfiguration = .init(commandName: "setup", abstract: "Provides your environment with templates")

    @Option(name: .shortAndLong, help: "Remote url where tamplates placed")
    var url: String?

    @Option(name: .shortAndLong, help: "Use this option if templates are placed on github. Format: \"<github>\\ [branch]\". Default: \"\(Constants.defaultTemplatesGithub)\"")
    var github: String?

    @Option(name: .shortAndLong, default: false, help: "If specified loads templates into current folder")
    var local: Bool

    private lazy var fileManager: FileManager = .default

    // MARK: - Lifecycle

    func run() throws {
        if let url = self.url {
            return try loadTemplatesFromPath(url)
        }
        let url = try getGitRepoPath()
        try loadTemplatesFromPath(url)
    }

    // MARK: - Private

    private func loadTemplatesFromPath(_ path: String) throws {
        let archiveURL = try downloadArchive(at: path)
        let folderURL = try unzipArchive(at: archiveURL)
        let templates = loadTemplates(in: folderURL)
        let destination = getTemplatesDestination()
        do {
            try move(templates, to: destination)
        }
        catch {
            try remove(folderURL)
            throw error
        }
        try remove(folderURL)
    }

    private func getGitRepoPath() throws -> String {
        let github = self.github ?? Constants.defaultTemplatesGithub
        let components = github.split(separator: " ")
        guard let name =  components.first else {
            throw Error.githubName(github)
        }
        var branch = "master"
        if components.count > 1 {
            branch = String(components[1])
        }

        return "https://github.com/\(name)/archive/\(branch).zip"
    }

    private func downloadArchive(at path: String) throws -> URL {
        guard let url = URL(string: path) else {
            throw Error.url(path)
        }
        let data = try self.data(at: url)
        let tmpFolderURL = try tempFolderWithRandomName()
        let fileURL = tmpFolderURL + url.lastPathComponent
        do {
            try data.write(to: fileURL)
        }
        catch {
            throw Error.write(tmpFolderURL)
        }
        return fileURL
    }

    private func data(at url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        }
        catch {
            throw Error.download(url)
        }
    }

    private func tempFolderWithRandomName() throws -> URL {
        let root = fileManager.homeDirectoryForCurrentUser
        let url = root + Constants.appFolderName + "tmp" + UUID().uuidString
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            throw Error.write(url)
        }
        return url
    }

    private func unzipArchive(at url: URL) throws -> URL {
        let folderURL = url.deletingLastPathComponent()
        do {
            try fileManager.unzipItem(at: url, to: folderURL)
        }
        catch {
            throw Error.write(folderURL)
        }
        return folderURL
    }

    private func loadTemplates(in url: URL) -> [URL] {
        var templates = [URL]()
        do {
            let contents = try fileManager.contentsOfDirectory(at: url,
                                                               includingPropertiesForKeys: nil,
                                                               options: [])
            for url in contents {
                var isDirrectory: ObjCBool = false
                _ = fileManager.fileExists(atPath: url.path, isDirectory: &isDirrectory)
                if isDirrectory.boolValue {
                    if fileManager.fileExists(atPath: (url + Constants.specFilename).path) {
                        templates.append(url)
                    }
                    else {
                        templates.append(contentsOf: loadTemplates(in: url))
                    }
                }
            }
        }
        catch {
            return templates
        }
        return templates
    }

    private func getTemplatesDestination() -> URL {
        if local {
            return URL(fileURLWithPath: "./")
        }
        else {
            return fileManager.homeDirectoryForCurrentUser
        }
    }

    private func move(_ templates: [URL], to destination: URL) throws {
        do {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            throw Error.write(destination)
        }
        for url in templates {
            let destination = destination + url.lastPathComponent
            do {
                // TODO: check existing, make soft update
                try fileManager.moveItem(at: url, to: destination)
            }
            catch {
                throw Error.write(destination)
            }
        }
    }

    private func remove(_ url: URL) throws {
        do {
            try fileManager.removeItem(at: url)
        }
        catch {
            throw Error.remove(url)
        }
    }
}

extension Setup.Error: CustomStringConvertible {

    var description: String {
        switch self {
        case .githubName(let github):
            return "Could not retrive templates url from provided github (\(github)"
        case .url(let url):
            return "Invalid url provided \(url)"
        case .download(let url):
            return "Cold not download teplates from url \(url)"
        case .write(let destination):
            return "Could not write templates to their destination \(destination)"
        case .remove(let url):
            return "Could not remove temp directory at \(url)"
        }
    }
}
