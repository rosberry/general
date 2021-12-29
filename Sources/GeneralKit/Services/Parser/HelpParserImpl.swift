//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public final class HelpParserImpl: HelpParser {

    public typealias Dependencies = HasShell

    public enum Error: Swift.Error, LocalizedError {
        case unparsed(String)

        public var errorDescription: String? {
            switch self {
            case let .unparsed(line):
                return "Could not parse the line: `\(line)`"
            }
        }
    }

    private final class Context {

        // swiftlint:disable:next nesting
        struct HelpArgument {
            public let argument: String
            public let description: String
        }

        // swiftlint:disable:next nesting
        struct HelpOption {
            public let long: String
            public let short: String?
            public let argument: String?
            public let description: String
        }

        // swiftlint:disable:next nesting
        struct HelpSubcommand {
            public let command: String
            public let description: String
            public let isDefault: Bool
        }

        var overview: String = ""
        var usage: String = ""
        var arguments: [HelpArgument] = []
        var options: [HelpOption] = []
        var subcommands: [HelpSubcommand] = []
        var unexpectedStrings: [String] = []
        var index: Int = 0
        var lines: [String] = []
    }

    private lazy var parsers: [(Context) -> Void] = [
        makeSingleLineParser(start: "OVERVIEW:", keyPath: \.overview),
        makeSingleLineParser(start: "USAGE:", keyPath: \.usage),
        makeBlockParser(start: "ARGUMENTS:", parser: argumentParser),
        makeBlockParser(start: "OPTIONS:", parser: optionParser),
        makeBlockParser(start: "SUBCOMMANDS:", parser: subcommandParser),
        emptyLineParser,
        unexpectedStringParser
    ]

    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func parse(path: String? = nil, command: String) throws -> AnyCommandParser {
        let path = path ?? ""
        var string = try dependencies.shell(silent: "\(path)\(command) --help")
        string = string.replacingOccurrences(of: "\n", with: " \n")
        let context = Context()
        context.lines = string.split(separator: "\n").map { string in
            String(string).trimmingCharacters(in: .whitespaces)
        }

        while context.index < context.lines.count {
            let currentIndex = context.index
            parsers.forEach { parser in
                guard context.index == currentIndex else {
                    return
                }
                parser(context)
            }
            guard context.index > currentIndex else {
                throw Error.unparsed(context.lines[context.index])
            }
        }

        var options: [String: AnyCommandParser.AnyOptionParser] = [:]
        var arguments: [String: AnyCommandParser.AnyArgumentParser] = [:]
        var subcommands: [String: AnyCommandParser] = [:]

        context.options.forEach { helpOption in
            options[helpOption.long] = .init(long: helpOption.long, short: helpOption.short)
        }

        context.arguments.forEach { helpArgument in
            arguments[helpArgument.argument] = .init(name: helpArgument.argument)
        }

        try context.subcommands.forEach { helpSubcommand in
            let command = try parse(path: "\(path)\(command) ", command: helpSubcommand.command)
            command.isDefault = helpSubcommand.isDefault
            subcommands[helpSubcommand.command] = command
        }

        return .init(name: command,
                     options: options,
                     arguments: arguments,
                     subcommands: subcommands)
    }

    public func parse(command: ParsableCommand.Type) throws -> AnyCommandParser {
        let name = makeCommandName(command)
        let string = command.helpMessage().replacingOccurrences(of: "\n", with: " \n")
        let context = Context()
        context.lines = string.split(separator: "\n").map { string in
            String(string).trimmingCharacters(in: .whitespaces)
        }

        while context.index < context.lines.count {
            let currentIndex = context.index
            parsers.forEach { parser in
                guard context.index == currentIndex else {
                    return
                }
                parser(context)
            }
            guard context.index > currentIndex else {
                throw Error.unparsed(context.lines[context.index])
            }
        }
        var options: [String: AnyCommandParser.AnyOptionParser] = [:]
        var arguments: [String: AnyCommandParser.AnyArgumentParser] = [:]
        var subcommands: [String: AnyCommandParser] = [:]

        context.options.forEach { helpOption in
            let isRequired = context.usage.contains("\(helpOption.long)") &&
                             !context.usage.contains("[--\(helpOption.long) <\(helpOption.long)>]")
            options[helpOption.long] = .init(long: helpOption.long, short: helpOption.short, isRequired: isRequired)
        }

        context.arguments.forEach { helpArgument in
            arguments[helpArgument.argument] = .init(name: helpArgument.argument)
        }

        var defaultCommandName: String?
        if let defaultSubcommand = command.configuration.defaultSubcommand {
            defaultCommandName = defaultSubcommand.configuration.commandName ?? String(describing: defaultSubcommand).lowercased()
        }
        try command.configuration.subcommands.map(parse).forEach { command in
            subcommands[command.name] = command
            command.isDefault = command.name == defaultCommandName
        }

        return .init(name: name,
                     options: options,
                     arguments: arguments,
                     subcommands: subcommands)
    }

    // MARK: Private

    private func makeSingleLineParser(start: String, keyPath: ReferenceWritableKeyPath<Context, String>) -> ((Context) -> Void) {
        return { context in
            var line = context.lines[context.index]
            guard line.starts(with: start) else {
                return
            }
            line.removeFirst(start.count)
            context[keyPath: keyPath] = line.trimmingCharacters(in: .whitespacesAndNewlines)
            context.index += 1
        }
    }

    // MARK: Private

    private func makeBlockParser(start: String, parser: @escaping ((Context) -> Bool)) -> ((Context) -> Void) {
        return { context in
            let line = context.lines[context.index]
            guard line.starts(with: start) else {
                return
            }
            while context.index < context.lines.count - 1 {
                context.index += 1
                let line = context.lines[context.index]
                guard line.isEmpty == false else {
                    return
                }
                if parser(context) == false {
                    return
                }
            }
        }
    }

    private func emptyLineParser(context: Context) {
        let line = context.lines[context.index]
        guard line.isEmpty else {
            return
        }
        context.index += 1
    }

    private func argumentParser(context: Context) -> Bool {
        var line = context.lines[context.index]
        var argument = ""
        var parsed = false

        func parse(pattern: String) -> String? {
            guard let match = parseFirstRegexMatch(pattern: pattern, rangeIndex: 0, string: line),
                  line.starts(with: match) else {
                return nil
            }
            line.removeFirst(match.count)
            line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            parsed = true
            return match
        }

        if let match = parse(pattern: "<[a-zA-Z\\-]+>") {
            argument = match
            argument.removeFirst()
            argument.removeLast()
        }

        if parsed {
            context.arguments.append(.init(argument: makeArgumentName(argument), description: line))
        }
        return parsed
    }

    private func optionParser(context: Context) -> Bool {
        var short: String?
        var long: String = ""
        var argument: String?
        var line = context.lines[context.index]
        while context.index + 1 < context.lines.count &&
              context.lines[context.index + 1].starts(with: "-") == false &&
              context.lines[context.index + 1].isEmpty == false {
            line += " " + context.lines[context.index + 1]
            context.index += 1
        }
        var parsed = false

        func parse(pattern: String) -> String? {
            guard let match = parseFirstRegexMatch(pattern: pattern, rangeIndex: 0, string: line),
                  line.starts(with: match) else {
                return nil
            }
            line.removeFirst(match.count)
            line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            parsed = true
            return match
        }

        while true {
            if let match = parse(pattern: "--[a-zA-Z]+") {
                long = match
                long.removeFirst(2)
            }
            else if let match = parse(pattern: "-[a-zA-Z]") {
                short = match
                short?.removeFirst(1)
            }
            else if let match = parse(pattern: "<[a-zA-Z]+>") {
                argument = match
            }
            else if parse(pattern: ",") != nil {
                continue
            }
            else {
                break
            }
        }
        if parsed {
            context.options.append(.init(long: long, short: short, argument: argument, description: line))
        }
        return parsed
    }

    private func subcommandParser(context: Context) -> Bool {
        var line = context.lines[context.index]
        var command = ""
        var isDefault = false
        var parsed = false

        func parse(pattern: String) -> String? {
            guard let match = parseFirstRegexMatch(pattern: pattern, rangeIndex: 0, string: line),
                  line.starts(with: match) else {
                return nil
            }
            line.removeFirst(match.count)
            line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            parsed = true
            return match
        }

        if let match = parse(pattern: "[a-zA-Z]+\\s\\(default\\)"),
           let commandMatch = parseFirstRegexMatch(pattern: "[a-zA-Z]+\\s", rangeIndex: 0, string: match) {
            isDefault = true
            command = commandMatch.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else if let match = parse(pattern: "[a-zA-Z]+\\s") {
            command = match.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if parsed {
            context.subcommands.append(.init(command: command, description: line, isDefault: isDefault))
        }
        return parsed
    }

    private func unexpectedStringParser(context: Context) {
        let line = context.lines[context.index]
        context.unexpectedStrings.append(line)
        context.index += 1
    }

    private func makeCommandName(_ command: ParsableCommand.Type) -> String {
        if let name = command.configuration.commandName {
            return name
        }
        let string = String(describing: command)
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: string.count)
        let result = regex?.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "$1-$2")
        return result?.lowercased() ?? string
    }

    private func makeArgumentName(_ string: String) -> String {
        string.split(separator: "-").enumerated().map { index, word in
            index > 0 ? word.capitalized : word.lowercased()
        }.joined()
    }
}
