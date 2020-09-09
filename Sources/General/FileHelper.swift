//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

final class FileHelper {

    static var `default` = FileHelper()

    private lazy var keys: Set<URLResourceKey> = [.isDirectoryKey, .contentModificationDateKey]

    lazy var fileManager: FileManager = .default

    func contentsOfDirectory(at path: String) -> [FileInfo] {
        contentsOfDirectory(at: URL(fileURLWithPath: path, isDirectory: true))
    }

    func contentsOfDirectory(at url: URL) -> [FileInfo] {
        let contents = (try? fileManager.contentsOfDirectory(at: url,
                                                             includingPropertiesForKeys: Array(keys),
                                                             options: [])) ?? []
        return contents.map(fileInfo(with:))
    }

    func fileInfo(with url: URL) -> FileInfo {
        let values = try? url.resourceValues(forKeys: keys)
        return .init(url: url,
                     isDirectory: values?.isDirectory == true,
                     isExists: fileManager.fileExists(atPath: url.path),
                     contentModificationDate: values?.contentModificationDate)
    }

    func createDirectory(at path: String) throws {
        try fileManager.createDirectory(atPath: path,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
    }

    func createDirectoryIfPossible(at path: String) -> Bool {
        do {
            try createDirectory(at: path)
        }
        catch {
            return false
        }
        return true
    }

    func createDirectoryIfPossible(at url: URL) -> Bool {
        createDirectoryIfPossible(at: url.path)
    }
}
