//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ZIPFoundation

public final class FileHelper {

    enum Error: Swift.Error, CustomStringConvertible {
        case createDirectory(_ url: URL, error: Swift.Error)
        case resourceValue(_ url: URL, error: Swift.Error)
        case contentsOfDirectory(_ url: URL, error: Swift.Error)
        case remove(_ url: URL, error: Swift.Error)
        case move(_ url: URL, destination: URL, error: Swift.Error)
        case unzip(_ url: URL, error: Swift.Error)

        var description: String {
            switch self {
            case let .createDirectory(url, error):
                return red("Could not create directory at path: \(url.path). " +
                           "Occurred file system error: \(error.localizedDescription)")
            case let .contentsOfDirectory(url, error):
                return red("Could not retrieve contents of directory at path: \(url.path). " +
                           "Occurred file system error: \(error.localizedDescription)")
            case let .resourceValue(url, error):
                return red("Could not retrieve attributes of file at path: \(url.path). " +
                           "Occurred file system error: \(error.localizedDescription)")
            case let .remove(url, error):
                return red("Could not remove file at path: \(url.path). " +
                           "Occurred file system error: \(error.localizedDescription)")
            case let .move(url, destination, error):
                return red("Could not moved file at path: \(url.path) to \(destination.path). " +
                           "Occurred file system error: \(error.localizedDescription)")

            case let .unzip(url, error):
                return red("Could not unzip archive at path: \(url.path) to \(url.deletingLastPathComponent().path). " +
                "Occurred file system error: \(error.localizedDescription)")
            }
        }
    }

    static var `default` = FileHelper()

    private lazy var keys: Set<URLResourceKey> = [.isDirectoryKey, .contentModificationDateKey]

    lazy var fileManager: FileManager = .default

    func contentsOfDirectory(at path: String) throws -> [FileInfo] {
        try contentsOfDirectory(at: URL(fileURLWithPath: path, isDirectory: true))
    }

    func contentsOfDirectory(at url: URL) throws -> [FileInfo] {
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(at: url,
                                                           includingPropertiesForKeys: Array(keys),
                                                           options: [])
        }
        catch {
            throw Error.contentsOfDirectory(url, error: error)
        }
        return try contents.map(fileInfo(with:))
    }

    func fileInfo(with url: URL) throws -> FileInfo {
        let values = try? url.resourceValues(forKeys: keys)
        var isDirectory: ObjCBool = false
        let isExists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return .init(url: url,
                     isDirectory: isDirectory.boolValue,
                     isExists: isExists,
                     contentModificationDate: values?.contentModificationDate)
    }

    func createDirectory(at path: String) throws {
        do {
            try fileManager.createDirectory(atPath: path,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
        catch {
            throw Error.createDirectory(URL(fileURLWithPath: path), error: error)
        }
    }

    func createDirectory(at url: URL) throws {
        try createDirectory(at: url.path)
    }

    func removeFile(at url: URL) throws {
        do {
            try fileManager.removeItem(at: url)
        }
        catch {
            throw Error.remove(url, error: error)
        }
    }

    func moveFile(at url: URL, to destination: URL) throws {
        do {
            try fileManager.moveItem(at: url, to: destination)
        }
        catch {
            throw Error.move(url, destination: destination, error: error)
        }
    }

    func unzipArchive(at url: URL) throws -> URL {
        let folderURL = url.deletingLastPathComponent()
        do {
            try fileManager.unzipItem(at: url, to: folderURL)
        }
        catch {
            throw Error.unzip(url, error: error)
        }
        return folderURL
    }
}
