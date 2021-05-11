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
        ConfigFactory.shared?.installedPlugins.map(\.name) ?? []
    }

    static func templatesRepos() -> [String] {
        guard let config = ConfigFactory.shared else {
            return []
        }
        return Array(config.templatesRepos.keys)
    }

    static func versions() -> [String] {
        return ["master", "0.3", "0.2", "0.1.2", "0.1.1", "0.1.0"]
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
}
