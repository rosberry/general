//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public final class CompletionsServiceImpl: CompletionsService {

    public typealias Dependencies = HasFileHelper & HasConfigFactory

    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func templates() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: "./\(Constants.templatesFolderName)")) ?? []
    }

    public func installedPlugins() -> [String] {
        guard let files = try? dependencies.fileHelper.contentsOfDirectory(at: Constants.pluginsPath) else {
            return []
        }
        return files.map { file in
            file.url.lastPathComponent
        }
    }

    public func executables() -> [String] {
        ["general"] + installedPlugins()
    }

    public func templatesRepos() -> [String] {
        guard let config = dependencies.configFactory.shared else {
            return []
        }
        return Array(config.templatesRepos.keys)
    }

    public func versions() -> [String] {
        return ["master", "0.3", "0.3.2", "0.3.3"]
    }
}

public extension CompletionKind {

    static var dependencies: HasCompletionsService = Services

    static var templates: CompletionKind {
        .custom { _ in
            dependencies.completionsService.templates()
        }
    }

    static var installedPlugins: CompletionKind {
        .custom { _ in
            dependencies.completionsService.installedPlugins()
        }
    }

    static var versions: CompletionKind {
        .custom { _ in
            dependencies.completionsService.versions()
        }
    }

    static var templatesRepos: CompletionKind {
        .custom { _ in
            dependencies.completionsService.templatesRepos()
        }
    }

    static var executables: CompletionKind {
        .custom { _ in
            dependencies.completionsService.executables()
        }
    }
}
