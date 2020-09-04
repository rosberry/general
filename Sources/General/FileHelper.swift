//
//  FileHelper.swift
//  AEXML
//
//  Created by Nick Tyunin on 03.09.2020.
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

    func createDirectory(at path: String) -> Bool {
        do {
            try fileManager.createDirectory(atPath: path,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
        catch {
            return false
        }
        return true
    }

    func createDirectory(at url: URL) -> Bool {
        createDirectory(at: url.path)
    }
}
