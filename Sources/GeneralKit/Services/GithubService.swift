//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import PathKit
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

    private lazy var fileHelper: FileHelper = .default
    private lazy var shell: Shell = .init()

    public init() {
        //
    }

    public func getGitRepoPath(repo: String) throws -> String {
        let components = repo.split(separator: " ")
        guard let name = components.first else {
            throw Error.githubName(repo)
        }
        var branch = Constants.defaultGithubBranch
        if components.count > 1 {
            branch = String(components[1])
        }

        return Constants.githubArchivePath(String(name), branch)
    }

    public func downloadFiles(at repo: String, filesHandler: ([FileInfo]) throws -> Void) throws {
        let gitRepoPath = try getGitRepoPath(repo: repo)
        let archiveURL = try downloadArchive(at: gitRepoPath)
        let folderURL = try fileHelper.unzipArchive(at: archiveURL)
        let firstDirectory = try fileHelper.contentsOfDirectory(at: folderURL).first(where: \.isDirectory)
        guard let directory = firstDirectory else {
            throw Error.write(folderURL)
        }
        let files = try fileHelper.contentsOfDirectory(at: directory.url)
        do {
            try filesHandler(files)
        }
        catch {
            try fileHelper.removeFile(at: folderURL)
            throw error
        }
        try fileHelper.removeFile(at: folderURL)
    }

    @discardableResult
    public func downloadFiles(at repo: String,
                              to destination: String) throws -> [FileInfo] {
        var movedFiles: [FileInfo] = []
        let destination = URL(fileURLWithPath: destination)
        try downloadFiles(at: repo) { files in
            movedFiles.append(contentsOf: try move(files, to: destination))
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
            throw Error.download(url)
        }
    }

    private func fetchFiles(in url: URL, matchHandler: (FileInfo) -> Bool) throws -> [FileInfo] {
        var files = [FileInfo]()
        try fileHelper.contentsOfDirectory(at: url).forEach { file in
            if matchHandler(file) {
                files.append(file)
            }
        }
        return files
    }

    private func move(_ files: [FileInfo], to destination: URL) throws -> [FileInfo] {
        var moved = [FileInfo]()
        try fileHelper.createDirectory(at: destination)

        for file in files {
            let destination = try fileHelper.fileInfo(with: destination + file.url.lastPathComponent)
            if destination.isExists {
                try fileHelper.removeFile(at: destination.url)
            }
            try fileHelper.moveFile(at: file.url, to: destination.url)
            moved.append(destination)
        }
        return moved
    }
}
