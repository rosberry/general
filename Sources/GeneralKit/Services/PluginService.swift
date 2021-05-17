//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public final class PluginService {
    enum Error: Swift.Error, CustomStringConvertible {
        case noPlugin
        case installation
        case activation

        var description: String {
            switch self {
            case .noPlugin:
                return "Could not find plugin"
            case .installation:
                return "Could not install plugin"
            case .activation:
                return "Could not activate plugin"
            }
        }
    }

    private lazy var fileHelper: FileHelper = .default
    private lazy var helpParser: HelpParser = .init()

    public init() {

    }

    public func add(path: String) throws {
        guard let url = URL(string: path),
              let file = try? fileHelper.fileInfo(with: url),
              file.isDirectory == false else {
            throw Error.noPlugin
        }
        let pluginURL = try copy(localUrl: url)
        try activate(path: pluginURL.path)
    }

    public func activate(path: String) throws {
        let url = URL(fileURLWithPath: path)
        guard let file = try? fileHelper.fileInfo(with: url),
              file.isDirectory == false else {
            throw Error.noPlugin
        }
    }

    private func copy(localUrl: URL) throws -> URL {
        let localUrl = URL(fileURLWithPath: localUrl.path)
        let installationDirectoryURL = URL(fileURLWithPath: Constants.pluginsPath)
        let name = localUrl.lastPathComponent
        let installationURL = installationDirectoryURL + name
        do {
            if fileHelper.fileManager.fileExists(atPath: installationDirectoryURL.path) == false {
                try fileHelper.createDirectory(at: installationDirectoryURL)
            }
            try fileHelper.fileManager.copyItem(at: localUrl, to: installationURL)
            return installationURL
        }
        catch {
            throw Error.installation
        }
    }
}
