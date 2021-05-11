//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public final class InsertStringService {

    public init() {
        //
    }

    public func insert(string: String, template: String, file: FileInfo, terminator: Character? = nil) throws {
        var sourceCode = try String(contentsOf: file.url)
        guard !sourceCode.contains(string) else {
            return
        }
        let lines = sourceCode.split(separator: "\n")
        var newLines = [String]()
        lines.forEach { line in
            guard line.contains(template) else {
                newLines.append(String(line))
                return
            }
            if let terminator = terminator,
               let last = newLines.last?.trimmingCharacters(in: .whitespaces),
               last.last != terminator,
               let terminated = newLines.last?.replacingOccurrences(of: last, with: last + "\(terminator)") {
                newLines[newLines.count - 1] = terminated
            }
            let insertingString = line.replacingOccurrences(of: template, with: string)
            newLines.append(String(insertingString))
            newLines.append(String(line))
        }
        sourceCode = newLines.joined(separator: "\n")
        let data = sourceCode.data(using: .utf8)
        try data?.write(to: file.url)
    }
}
