//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import PathKit
import XcodeProj
import Foundation

public final class GithubService {

    enum Error: Swift.Error {
        case url(_ url: String)
        case githubName(_ github: String)
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

    private let fileHelper: FileHelper = .default

    public func getGitRepoPath(githubPath: String) throws -> String {
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

    @discardableResult
    public func downloadFiles(at gitRepoPath: String,
                              to destination: String,
                              askForUpdate: (FileInfo, FileInfo) -> Bool = { _, _ in true },
                              matchHandler: (FileInfo) -> Bool = { _ in true }) throws -> [FileInfo] {
        let archiveURL = try downloadArchive(at: gitRepoPath)
        let folderURL = try fileHelper.unzipArchive(at: archiveURL)
        guard let directory = try? fetchFiles(in: folderURL, matchHandler: matchHandler).filter({ file in
            file.isDirectory
        }).first else {
            throw Error.write(folderURL)
        }
        let destination = URL(fileURLWithPath: destination)
        if try fileHelper.fileInfo(with: destination).isExists {
            try fileHelper.removeFile(at: destination)
        }
        let files = try fileHelper.contentsOfDirectory(at: directory.url)
        var movedFiles: [FileInfo] = []
        var errors: [Swift.Error] = []
        do {
            movedFiles = try move(files, to: destination, askForUpdate: askForUpdate)
        }
        catch {
            errors.append(error)
        }
        try fileHelper.removeFile(at: folderURL)
        if errors.isEmpty == false {
            throw Error.composite(errors)
        }
        return movedFiles
    }

    // MARK: - Private

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
            // TODO: Authorize request if needed
            throw Error.download(url)
        }
    }

    private func tempFolderWithRandomName() throws -> URL {
        let folderName = "\(Constants.generalTmpFolderPrefix).\(UUID().uuidString)"
        let url = URL(fileURLWithPath: Constants.tmpFolderPath) + folderName
        try fileHelper.createDirectory(at: url)
        return url
    }

    private func fetchFiles(in url: URL, matchHandler: (FileInfo) -> Bool) throws -> [FileInfo] {
        var files = [FileInfo]()
        try fileHelper.contentsOfDirectory(at: url).forEach { file in
            if matchHandler(file) {
                files.append(file)
            }
            else if file.isDirectory {
                let folderFiles = try fetchFiles(in: file.url, matchHandler: matchHandler)
                files.append(contentsOf: folderFiles)
            }
        }
        return files
    }

    private func move(_ files: [FileInfo], to destination: URL, askForUpdate: (FileInfo, FileInfo) -> Bool) throws -> [FileInfo] {
        var moved = [FileInfo]()
        try fileHelper.createDirectory(at: destination)

        for file in files {
            let destination = try fileHelper.fileInfo(with: destination + file.url.lastPathComponent)
            if destination.isExists {
                if shouldUpdate(destination, with: file, ask: askForUpdate) {
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

    private func shouldUpdate(_ destination: FileInfo, with file: FileInfo, ask: (FileInfo, FileInfo) -> Bool) -> Bool {
        guard let lhs = try? modificationDateOfFile(destination),
              let rhs = try? modificationDateOfFile(file) else {
                return ask(destination, file)
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
}
