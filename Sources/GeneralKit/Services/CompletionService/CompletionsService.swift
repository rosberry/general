//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser

public protocol HasCompletionsService {
    var completionsService: CompletionsService { get }
}

public protocol CompletionsService {
    func templates() -> [String]
    func installedPlugins() -> [String]
    func executables() -> [String]
    func templatesRepos() -> [String]
    func versions() -> [String]
}
