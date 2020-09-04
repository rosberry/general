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

    @Option(name: [.customLong("repo"), .customShort("r")],
            help: .init(stringLiteral:
                "Fetch templates from specified github repo." +
                " Format: \"<github>\\ [branch]\"."))
    var githubPath: String = Constants.defaultTemplatesGithub

    @Option(name: [.customLong("global"), .customShort("g")],
            help: "If specified loads templates into user home directory")
    var shouldLoadGlobally: Bool = false

    private lazy var specFactory: SpecFactory = .init()
    private lazy var fileHelper: FileHelper = .default

    // MARK: - Lifecycle

    func run() throws {
        let url = try getGitRepoPath()
        try loadSetupFilesFromPath(url)
    }

    // MARK: - Private

    private func loadSetupFilesFromPath(_ path: String) throws {
        print("Loading setup files from \(githubPath)...")
        let archiveURL = try downloadArchive(at: path)
        let folderURL = try unzipArchive(at: archiveURL)
        let setupFiles = loadSetupFiles(in: folderURL)
        let destination = getTemplatesDestination()

        var moved = [FileInfo]()
        var isSpecModified = false
        do {
            moved = try move(setupFiles.templates, to: destination)
            isSpecModified = updateSpecIfNeeded(templateURL: setupFiles.spec)
        }
        catch {
            try remove(folderURL)
            throw error
        }
        try remove(folderURL)
        print()
        displayResult(moved, isSpecModified: isSpecModified)
    }

    private func getGitRepoPath() throws -> String {
        let components = githubPath.split(separator: " ")
        guard let name = components.first else {
            throw Error.githubName(githubPath)
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
        let folderName = "\(Constants.generalTmpFolderPrefix).\(UUID().uuidString)"
        let url = URL(fileURLWithPath: Constants.tmpFolderPath) + folderName
        if fileHelper.createDirectory(at: url) == false {
            throw Error.write(url)
        }
        return url
    }

    private func unzipArchive(at url: URL) throws -> URL {
        let folderURL = url.deletingLastPathComponent()
        do {
            try fileHelper.fileManager.unzipItem(at: url, to: folderURL)
        }
        catch {
            throw Error.write(folderURL)
        }
        return folderURL
    }

    private func loadSetupFiles(in url: URL) -> (templates: [FileInfo], spec: URL?) {
        var templates = [FileInfo]()
        var spec: URL?
        fileHelper.contentsOfDirectory(at: url).forEach { file in
            if file.isDirectory {
                if fileHelper.fileManager.fileExists(atPath: (file.url + Constants.specFilename).path) {
                    templates.append(fileHelper.fileInfo(with: file.url))
                }
                else {
                    let setupFiles = loadSetupFiles(in: file.url)
                    templates.append(contentsOf: setupFiles.templates)
                    if let foundSpec = setupFiles.spec {
                        spec = foundSpec
                    }
                }
            }
            else if file.url.lastPathComponent == Constants.generalSpecName {
                spec = file.url
            }
            else if file.url.pathExtension == Constants.stencilPathExtension {
                templates.append(fileHelper.fileInfo(with: file.url.deletingLastPathComponent()))
            }
        }
        return (Array(Set(templates)), spec)
    }

    private func getTemplatesDestination() -> URL {
        if shouldLoadGlobally {
            return fileHelper.fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        }
        else {
            return URL(fileURLWithPath: Constants.relativeCurrentPath + Constants.templatesFolderName)
        }
    }

    private func move(_ templates: [FileInfo], to destination: URL) throws -> [FileInfo] {
        var moved = [FileInfo]()
        if fileHelper.createDirectory(at: destination) == false {
            throw Error.write(destination)
        }

        for file in templates {
            let destination = fileHelper.fileInfo(with: destination + file.url.lastPathComponent)
            guard isNewerFile(file, than: destination) else {
                continue
            }
            do {
                if destination.isExists {
                    try fileHelper.fileManager.removeItem(at: destination.url)
                }
                try fileHelper.fileManager.moveItem(at: file.url, to: destination.url)
                moved.append(file)
            }
            catch {
                throw Error.write(destination.url)
            }
        }
        return moved
    }

    private func isNewerFile(_ lhs: FileInfo, than rhs: FileInfo) -> Bool {
        guard let lhs = modificationDateOfFile(lhs),
              let rhs = modificationDateOfFile(rhs) else {
            return true
        }
        return lhs > rhs
    }

    private func modificationDateOfFile(_ file: FileInfo) -> Date? {
        guard file.isDirectory else {
            return file.contentModificationDate
        }
        let files = fileHelper.contentsOfDirectory(at: file.url)
        var date: Date?
        for file in files {
            guard let fileDate = modificationDateOfFile(file) else {
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

    private func updateSpecIfNeeded(templateURL: URL?) -> Bool {
        guard let templateURL = templateURL else {
            return false
        }
        let destination = URL(fileURLWithPath: "\(Constants.relativeCurrentPath)\(Constants.generalSpecName)")
        guard fileHelper.fileManager.fileExists(atPath: destination.path),
              askBool(question: "General spec already exists. Do you want to replace it? (Yes, No)") == false else {
            return updateSpec(templateURL: templateURL, destination: destination)
        }
        return false
    }

    private func updateSpec(templateURL: URL, destination: URL) -> Bool {
        guard var spec: GeneralSpec = try? specFactory.makeSpec(url: templateURL) else {
            return false
        }
        spec.project = ask("Enter project name", default: findProject())
        spec.target = ask("Target (optional)")
        spec.testTarget = ask("Test target (optional)")
        spec.company = ask("Company (optional)", default: spec.company)
        guard let data = try? specFactory.makeData(spec: spec) else {
            return false
        }
        do {
            try data.write(to: destination)
            return true
        }
        catch {
            return false
        }
    }

    private func askBool(question: String) -> Bool {
        guard let result = ask(question) else {
            return askBool(question: question)
        }
        switch result.lowercased() {
        case "yes", "y":
            return true
        case "no", "n":
            return false
        default:
            return askBool(question: question)
        }
    }

    private func ask(_ question: String, default: String? = nil) -> String? {
        if let value = `default` {
            print("\(question) \u{001B}[0;32m(\(value))\u{001B}[0;0m:", terminator: " ")
        }
        else {
            print("\(question):", terminator: " ")
        }
        guard let value = readLine(),
            value.isEmpty == false else {
            return `default`
        }
        return value
    }

    private func findProject() -> String? {
        let info = fileHelper.contentsOfDirectory(at: Constants.relativeCurrentPath).first { info in
            info.url.pathExtension == Constants.xcodeProjectPathExtension
        }
        return info?.url.lastPathComponent
    }

    private func remove(_ url: URL) throws {
        do {
            try fileHelper.fileManager.removeItem(at: url)
        }
        catch {
            throw Error.remove(url)
        }
    }

    private func displayResult(_ templates: [FileInfo], isSpecModified: Bool) {
        if templates.isEmpty {
            print("\u{001B}[0;33mNo templates modified 🤷‍♂️")
        }
        else {
            print("✨ Updated templates:")
            templates.forEach { file in
                print("\u{001B}[0;32m" + file.url.lastPathComponent)
            }

        }
        if isSpecModified {
            print("\n\u{001B}[0;32mGeneral spec modified")
        }
        print("\u{001B}[0;0m")
    }
}

extension Setup.Error: CustomStringConvertible {

    var description: String {
        switch self {
        case .githubName(let github):
            return "Could not retrieve templates url from provided github (\(github)"
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
