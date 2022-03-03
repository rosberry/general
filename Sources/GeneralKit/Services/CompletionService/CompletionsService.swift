//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser

public protocol HasCompletionsService {
    var completionsService: CompletionsService { get }
}

public protocol CompletionsService {
    var generateOptionName: String { get }
    func templates() -> [String]
    func installedPlugins() -> [String]
    func executables() -> [String]
    func templatesRepos() -> [String]
    func versions() -> [String]
    func defineCompletionShell() -> CompletionShell?
    func overrideCompletionScript(config: CompletionConfig) -> String
}
