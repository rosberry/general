//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public final class CompletionConfig {
    let shell: CompletionShell
    let command: ParsableCommand.Type
    let plugins: [String: String]
    let overrides: [String: String]

    init(shell: CompletionShell,
         command: ParsableCommand.Type,
         plugins: [String: String],
         overrides: [String: String]) {
        self.shell = shell
        self.command = command
        self.plugins = plugins
        self.overrides = overrides
    }
}
