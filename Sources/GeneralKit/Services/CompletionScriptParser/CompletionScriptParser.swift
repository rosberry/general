//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public protocol HasCompletionScriptParser {
    var completionScriptParser: CompletionScriptParser { get }
}

public protocol CompletionScriptParser {
    func parse(script: String, shell: CompletionShell) -> CompletionScript?
    func parseCaseName(name: String, shell: CompletionShell) -> (name: String, commands: [String])?
    func makeCaseName(name: String, script: CompletionScript) -> String?
}
