//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import XcodeProj
import ArgumentParser

public final class CompletionsService {

    static func templates() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: "./\(Constants.templatesFolderName)")) ?? []
    }

    static func targets() -> [String] {
        guard let projectPath = try? ProjectService.findProject() else {
            return []
        }
        return (try? XcodeProj(path: projectPath).pbxproj.nativeTargets.map { $0.name }) ?? []
    }

    static func plugins() -> [String] {
        ConfigFactory.default?.availablePlugins.map(\.name) ?? []
    }

    static func pluginsRepos() -> [String] {
        ConfigFactory.default?.pluginsRepos ?? []
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

    static var targets: CompletionKind {
        .custom { _ in
            CompletionsService.targets()
        }
    }

    static var plugins: CompletionKind {
        .custom { _ in
            CompletionsService.plugins()
        }
    }

    static var pluginsRepos: CompletionKind {
        .custom { _ in
            CompletionsService.pluginsRepos()
        }
    }

    static var versions: CompletionKind {
        .custom { _ in
            CompletionsService.versions()
        }
    }
}
