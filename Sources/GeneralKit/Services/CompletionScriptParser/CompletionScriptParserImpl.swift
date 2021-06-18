//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public class CompletionScriptParserImpl: CompletionScriptParser {

    private class Parser {
        func parse(_ string: String) -> (String, String)? {
            return nil
        }
    }

    private final class TokenParser: Parser {
        let token: String

        init(token: String) {
            self.token = token
        }

        override func parse(_ string: String) -> (String, String)? {
            var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard string.starts(with: token) else {
                return nil
            }
            string.removeFirst(token.count)
            return (token, string)
        }
    }

    private final class SnakeCaseParser: Parser {
        override func parse(_ string: String) -> (String, String)? {
            var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let first = string.first, (first.isLetter || first == "_") else {
                return nil
            }
            var result = "\(first)"
            guard string.count > 1 else {
                return ("\(first)", "")
            }
            for index in 1..<string.count {
                let char = string[String.Index(utf16Offset: index, in: string)]
                guard char.isLetter || char.isNumber || char == "_" || char == "-" else {
                    string.removeFirst(index)
                    return (result, string)
                }
                result += "\(char)"
            }
            return (result, "")
        }
    }

    private final class BracketsContentParser: Parser {
        override func parse(_ string: String) -> (String, String)? {
            var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let first = string.first, first == "{", string.count > 1 else {
                return nil
            }
            var result = "\(first)"
            var depth = 1
            for index in 1..<string.count {
                let char = string[String.Index(utf16Offset: index, in: string)]
                result += "\(char)"
                if char == "{" {
                    depth += 1
                }
                else if char == "}" {
                    depth -= 1
                    if depth == 0 {
                        string.removeFirst(index + 1)
                        return (result, string)
                    }
                }
            }
            return nil
        }
    }

    private final class ZshStartParser: Parser {
        let snakeCaseParser = SnakeCaseParser()
        let parenthesesParser = TokenParser(token: "()")

        override func parse(_ string: String) -> (String, String)? {
            var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
            var result = ""
            while true {
                guard let index = string.firstIndex(of: "\n") else {
                    return nil
                }
                let line = String(string[string.startIndex...index]).trimmingCharacters(in: .whitespaces)
                guard let (_, remaining) = snakeCaseParser.parse(line),
                      let (_, _) = parenthesesParser.parse(remaining) else {
                    result += line
                    string = String(string.dropFirst(line.count))
                    continue
                }
                return (result, string)
            }
        }
    }

    public func parse(script: String, shell: CompletionShell) -> CompletionScript? {
        switch shell {
        case .bash:
            return parseBashScript(script: script)
        case .zsh:
            return parseZshScript(script: script)
        case .fish:
            return parseFishScript(script: script)
        default:
            return nil
        }
    }

    public func parseCaseName(name: String, shell: CompletionShell) -> (name: String, commands: [String])? {
        switch shell {
        case .bash, .zsh:
            return parseSnakeCaseParenthesesName(name: name)
        case .fish:
            return parseFishCaseName(name: name)
        default:
            return nil
        }
    }

    public func makeCaseName(name: String, script: CompletionScript) -> String? {
        switch script.shell {
        case .bash, .zsh:
            return makeSnakeCaseParenthesesName(name: name, script: script)
        case .fish:
            return makeFishCaseName(name: name, script: script)
        default:
            return nil
        }
    }

    private func parseBashScript(script: String) -> CompletionScript? {
        parseBracketsScript(script: script, startParser: TokenParser(token: "#!/bin/bash"), shell: .bash)
    }

    private func parseZshScript(script: String) -> CompletionScript? {
        parseBracketsScript(script: script, startParser: ZshStartParser(), shell: .zsh)
    }

    private func parseBracketsScript(script: String, startParser: Parser, shell: CompletionShell) -> CompletionScript? {
        var string = script
        let snakeCaseParser = SnakeCaseParser()
        let parenthesesParser = TokenParser(token: "()")
        let bracketsContentParser = BracketsContentParser()

        func parse(parser: Parser) -> String? {
            guard let (result, remaining) = parser.parse(string) else {
                return nil
            }
            string = remaining
            return result
        }

        func parseStart() -> String? {
            parse(parser: startParser)
        }

        func parseName() -> String? {
            guard let name = parse(parser: snakeCaseParser),
                  let parentheses = parse(parser: parenthesesParser) else {
                return nil
            }
            return name + parentheses
        }

        func parseCase() -> (key: String, value: String)? {
            guard let name = parseName(),
                  let conent = parse(parser: bracketsContentParser) else {
                return nil
            }
            return (name, conent)
        }

        func parseCases() -> [(String,String)]? {
            var cases = [(String,String)]()
            while let result = parseCase() {
                cases.append(result)
            }
            guard cases.isEmpty == false else {
                return nil
            }
            return cases
        }

        guard let start = parseStart(),
              let cases = parseCases() else {
            return nil
        }
        return .init(shell: shell, start: start, cases: cases, end: string)
    }

    private func parseFishScript(script: String) -> CompletionScript? {
        var start = ""
        var end = ""
        var cases = [(String, String)]()
        return .init(shell: .fish, start: start, cases: cases, end: end)
    }

    private func parseSnakeCaseParenthesesName(name: String) -> (name: String, commands: [String])? {
        var string = name.trimmingCharacters(in: .whitespaces)
        if string.hasSuffix("()") {
            string = String(string.dropLast(2))
        }
        var components = Array(string.split(separator: "_"))
        while components.first == "" {
            components = Array(components.dropFirst())
        }
        guard let first = components.first else {
            return nil
        }
        let name = String(first.split(separator: "-").map(\.capitalized).joined())
        guard components.count > 1 else {
            return (String(name), [])
        }
        let commands = components.dropFirst().map { command in
            String(command)
        }
        return (name, commands)
    }

    private func parseFishCaseName(name: String) -> (name: String, commands: [String])? {
        return nil
    }

    private func makeSnakeCaseParenthesesName(name: String, script: CompletionScript) -> String? {
        guard var string = script.cases.first?.0 else {
            return nil
        }
        if string.hasSuffix("()") {
            string = String(string.dropLast(2))
        }
        string += "_\(name)()"
        return string
    }

    private func makeFishCaseName(name: String, script: CompletionScript) -> String? {
        return nil
    }
}
