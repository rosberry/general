//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public protocol HasFileHelper {
    var fileHelper: FileHelper { get }
}

public protocol FileHelper {

    var fileManager: FileManager { get }

    func contentsOfDirectory(at path: String) throws -> [FileInfo]
    func contentsOfDirectory(at url: URL) throws -> [FileInfo]
    func fileInfo(with url: URL) throws -> FileInfo
    func createDirectory(at path: String) throws
    func createDirectory(at url: URL) throws
    func removeFile(at url: URL) throws
    func moveFile(at url: URL, to destination: URL) throws
    func unzipArchive(at url: URL) throws -> URL
}
