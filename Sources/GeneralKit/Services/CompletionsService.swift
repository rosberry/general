//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public final class CompletionsService {

    static func templates() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: "./\(Constants.templatesFolderName)")) ?? []
    }

    static func installedPlugins() -> [String] {
        guard let files = try? FileHelper().contentsOfDirectory(at: Constants.pluginsPath) else {
            return []
        }
        return files.map { file in
            file.url.lastPathComponent
        }
    }

    static func executables() -> [String] {
        ["general"] + installedPlugins()
    }

    static func templatesRepos() -> [String] {
        guard let config = ConfigFactory.shared else {
            return []
        }
        return Array(config.templatesRepos.keys)
    }

    static func versions() -> [String] {
        return ["master", "0.3", "0.3.2", "0.3.3"]
    }
}

public extension CompletionKind {
    static var templates: CompletionKind {
        .custom { _ in
            CompletionsService.templates()
        }
    }

    static var installedPlugins: CompletionKind {
        .custom { _ in
            CompletionsService.installedPlugins()
        }
    }

    static var versions: CompletionKind {
        .custom { _ in
            CompletionsService.versions()
        }
    }

    static var templatesRepos: CompletionKind {
        .custom { _ in
            CompletionsService.templatesRepos()
        }
    }

    static var executables: CompletionKind {
        .custom { _ in
            CompletionsService.executables()
        }
    }
}
