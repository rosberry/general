//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

final class Setup: ParsableCommand {

    enum Error: Swift.Error, CustomStringConvertible {
        case githubName(_ github: String)
        case url(_ url: String)
        case download(_ url: URL)
        case write(_ url: URL)
        case composite(_ errors: [Swift.Error])

        var description: String {
            switch self {
            case let .githubName(github):
                return "Could not retrieve templates url from provided github \(github)"
            case let .url(url):
                return "Invalid url provided \(url)"
            case let .download(url):
                return "Cold not download templates from url \(url)"
            case let .write(destination):
                return "Could not write templates to their destination \(destination)"
            case let .composite(errors):
                return  errors.reduce("Following errors occurred during process:\n") { result, error in
                    result + " - \(error)\n"
                }
            }
        }
    }

    static let configuration: CommandConfiguration = .init(commandName: "setup",
                                                           abstract: "Provides your environment with templates")

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
        let folderURL = try fileHelper.unzipArchive(at: archiveURL)
        let setupFiles = try loadSetupFiles(in: folderURL)
        let destination = getTemplatesDestination()

        var movedFiles: [FileInfo] = []
        var isSpecModified = false
        var errors: [Swift.Error] = []
        do {
            movedFiles = try move(setupFiles.templates, to: destination)
        }
        catch {
            errors.append(error)
        }
        do {
            isSpecModified = try updateSpecIfNeeded(templateURL: setupFiles.spec)
        }
        catch {
            errors.append(error)
        }
        try fileHelper.removeFile(at: folderURL)
        displayResult(movedFiles, isSpecModified: isSpecModified)
        if errors.isEmpty == false {
            throw Error.composite(errors)
        }
    }

    private func getGitRepoPath() throws -> String {
        let components = githubPath.split(separator: " ")
        guard let name = components.first else {
            throw Error.githubName(githubPath)
        }
        var branch = Constants.defaultGithubBranch
        if components.count > 1 {
            branch = String(components[1])
        }

        return Constants.githubArchivePath(String(name), branch)
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
        try fileHelper.createDirectory(at: url)
        return url
    }

    private func loadSetupFiles(in url: URL) throws -> (templates: [FileInfo], spec: URL?) {
        var templates = [FileInfo]()
        var spec: URL?
        try fileHelper.contentsOfDirectory(at: url).forEach { file in
            if file.isDirectory {
                if fileHelper.fileManager.fileExists(atPath: (file.url + Constants.specFilename).path) {
                    try templates.append(fileHelper.fileInfo(with: file.url))
                }
                else {
                    let setupFiles = try loadSetupFiles(in: file.url)
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
                try templates.append(fileHelper.fileInfo(with: file.url.deletingLastPathComponent()))
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
        try fileHelper.createDirectory(at: destination)

        for file in templates {
            let destination = try fileHelper.fileInfo(with: destination + file.url.lastPathComponent)
            if destination.isExists {
                if shouldUpdate(destination, with: file) {
                    try fileHelper.removeFile(at: destination.url)
                }
                else {
                    continue
                }
            }
            try fileHelper.moveFile(at: file.url, to: destination.url)
            moved.append(file)
        }
        return moved
    }

    private func shouldUpdate(_ destination: FileInfo, with file: FileInfo) -> Bool {
        guard let lhs = try? modificationDateOfFile(destination),
              let rhs = try? modificationDateOfFile(file) else {
                return askBool(question: "Could not compare downloaded template" + green(destination.url.lastPathComponent) +
                                         " with installed one. Do you want to replace it? (Yes, No)")
        }
        return rhs > lhs
    }

    private func modificationDateOfFile(_ file: FileInfo) throws -> Date? {
        guard file.isDirectory else {
            return file.contentModificationDate
        }
        let files = try fileHelper.contentsOfDirectory(at: file.url)
        var date: Date?
        for file in files {
            guard let fileDate = try modificationDateOfFile(file) else {
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

    private func updateSpecIfNeeded(templateURL: URL?) throws -> Bool {
        guard let templateURL = templateURL else {
            return false
        }
        let destination = URL(fileURLWithPath: "\(Constants.relativeCurrentPath)\(Constants.generalSpecName)")
        guard fileHelper.fileManager.fileExists(atPath: destination.path),
              askBool(question: "General spec already exists. Do you want to replace it? (Yes, No)") == false else {
            return try updateSpec(templateURL: templateURL, destination: destination)
        }
        return false
    }

    private func updateSpec(templateURL: URL, destination: URL) throws -> Bool {
        guard var spec: GeneralSpec = try? specFactory.makeSpec(url: templateURL) else {
            return false
        }
        spec.project = ask("Enter project name", default: try findProject())
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
            print("\(question) \(green("(\(value))")):", terminator: " ")
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

    private func findProject() throws -> String? {
        let info = try fileHelper.contentsOfDirectory(at: Constants.relativeCurrentPath).first { info in
            info.url.pathExtension == Constants.xcodeProjectPathExtension
        }
        return info?.url.lastPathComponent
    }

    private func displayResult(_ templates: [FileInfo], isSpecModified: Bool) {
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
        if isSpecModified {
            print(green("General spec modified"))
        }
    }
}
