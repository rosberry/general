//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public func parseFirstRegexMatch(pattern: String, rangeIndex: Int, string: String) -> String? {
    let fullRange = NSRange(location: 0, length: string.utf16.count)
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: string, options: [], range: fullRange) else {
        return nil
    }
    return parse(match: match, rangeIndex: rangeIndex, string: string)
}

public func parseAllRegexMatches(pattern: String, rangeIndex: Int, string: String) -> [String] {
    let fullRange = NSRange(location: 0, length: string.utf16.count)
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return []
    }
    return regex.matches(in: string, options: [], range: fullRange).compactMap { match in
        parse(match: match, rangeIndex: rangeIndex, string: string)
    }
}

public func parseFirstRegexMatch(patterns: [String], rangeIndex: Int, string: String) -> String? {
    let results = patterns.compactMap { pattern in
        parseFirstRegexMatch(pattern: pattern, rangeIndex: rangeIndex, string: string)
    }
    return results.first
}

private func parse(match: NSTextCheckingResult, rangeIndex: Int, string: String) -> String? {
    guard let range = Range(match.range(at: rangeIndex), in: string) else {
        return nil
    }
    return String(string[range])
}
