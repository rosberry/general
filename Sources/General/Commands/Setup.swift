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

    @Option(name: .shortAndLong,
            default: Constants.defaultTemplatesGithub,
            help: .init(stringLiteral:
                "Use this option if templates are placed on github." +
                " Format: \"<github>\\ [branch]\". Default: \"\(Constants.defaultTemplatesGithub)\""))
    var github: String

    @Option(name: .shortAndLong, default: false, help: "If specified loads templates into current folder")
    var local: Bool

    private lazy var fileManager: FileManager = .default

    // MARK: - Lifecycle

    func run() throws {
        let url = try getGitRepoPath()
        try loadTemplatesFromPath(url)
    }

    // MARK: - Private

    private func loadTemplatesFromPath(_ path: String) throws {
        print("Loading templates from \(github)...")
        let archiveURL = try downloadArchive(at: path)
        let folderURL = try unzipArchive(at: archiveURL)
        let templates = loadTemplates(in: folderURL)
        let destination = getTemplatesDestination()
        var moved = [URL]()
        do {
            moved = try move(templates, to: destination)
        }
        catch {
            try remove(folderURL)
            throw error
        }
        try remove(folderURL)
        print()
        if moved.isEmpty {
            print("\u{001B}[0;33mNo templates modified 🤷‍♂️")
        }
        else {
            print("✨ Updated templates:")
            moved.forEach { url in
                print("\u{001B}[0;32m" + url.lastPathComponent)
            }
        }
        print("\u{001B}[0;0m")
    }

    private func getGitRepoPath() throws -> String {
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
                var isDirectory: ObjCBool = false
                _ = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                if isDirectory.boolValue {
                    if fileManager.fileExists(atPath: (url + Constants.specFilename).path) {
                        templates.append(url)
                    }
                    else {
                        templates.append(contentsOf: loadTemplates(in: url))
                    }
                }
                else if url.pathExtension == "stencil" {
                    templates.append(url.deletingLastPathComponent())
                }
            }
        }
        catch {
            return Array(Set(templates))
        }
        return Array(Set(templates))
    }

    private func getTemplatesDestination() -> URL {
        if local {
            return URL(fileURLWithPath: "./" + Constants.templatesFolderName)
        }
        else {
            return fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        }
    }

    private func move(_ templates: [URL], to destination: URL) throws -> [URL] {
        var moved = [URL]()

        do {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            throw Error.write(destination)
        }

        for url in templates {
            let destination = destination + url.lastPathComponent
            guard isNewerFileWithURL(url, than: destination) else {
                continue
            }
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.moveItem(at: url, to: destination)
                moved.append(url)
            }
            catch {
                throw Error.write(destination)
            }
        }
        return moved
    }

    private func isNewerFileWithURL(_ lhs: URL, than rhs: URL) -> Bool {
        guard let lhs = modificationDateOfFileWithURL(lhs),
              let rhs = modificationDateOfFileWithURL(rhs) else {
            return true
        }
        return lhs > rhs
    }

    private func modificationDateOfFileWithURL(_ url: URL) -> Date? {
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        guard isDirectory.boolValue else {
            return try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        }
        guard let urls = try? fileManager.contentsOfDirectory(at: url,
                                                              includingPropertiesForKeys: nil,
                                                              options: []) else {
            return nil
        }
        var date: Date?
        for url in urls {
            guard let fileDate = modificationDateOfFileWithURL(url) else {
                continue
            }
            guard let lastDate = date else {
                date = fileDate
                continue
            }
            if fileDate > lastDate {
                date = fileDate
            }
        }
        return date
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
