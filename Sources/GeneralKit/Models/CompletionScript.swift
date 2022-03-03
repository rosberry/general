//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public final class CompletionScript {
    let shell: CompletionShell
    let start: String
    var cases: [(String, String)]
    let end: String

    init(shell: CompletionShell, start: String, cases: [(String, String)], end: String) {
        self.shell = shell
        self.start = start
        self.cases = cases
        self.end = end
    }
}

extension CompletionScript: CustomStringConvertible {
    public var description: String {
        if shell == .fish {
            let casesString = cases.map { key, value in
                value
            }.joined(separator: "\n")
            return "\(start)\(casesString)\(end)"
        }
        else {
            let casesString = cases.map { key, value in
                "\(key) \(value)"
            }.joined(separator: "\n\n")
            return "\(start)\n\n\(casesString)\n\n\(end)"
        }
    }
}
