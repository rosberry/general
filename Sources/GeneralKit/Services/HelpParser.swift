//
//  HelpParser.swift
//  GeneralIOs
//
//  Created by Nick Tyunin on 11.05.2021.
//

import Foundation

public final class HelpParser {

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
        var overview: String = ""
        var usage: String = ""
        var arguments: [HelpArgument] = []
        var options: [HelpOption] = []
        var subcommands: [HelpSubcommand] = []
        var unexpectedStrings: [String] = []
        var index: Int = 0
        var lines: [String] = []
    }

    private lazy var shell: Shell = .init()

    private lazy var parsers: [(Context) -> Void] = [
        makeSingleLineParser(start: "OVERVIEW:", keyPath: \.overview),
        makeSingleLineParser(start: "USAGE:", keyPath: \.usage),
        makeBlockParser(start: "ARGUMENTS", parser: argumentParser),
        makeBlockParser(start: "OPTIONS:", parser: optionParser),
        makeBlockParser(start: "SUBCOMMANDS:", parser: subcommandParser),
        emptyLineParser,
        unexpectedStringParser
    ]

    public init() {
        //
    }

    public func parse(command: String) throws -> Help {
        let string = try shell(silent: "\(command) --help").stdOut
        let context = Context()
        context.lines = string.split(separator: "\n").map({String($0).trimmingCharacters(in: .whitespacesAndNewlines)})

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
        return .init(overview: context.overview,
                     usage: context.usage,
                     arguments: context.arguments,
                     options: context.options,
                     subcommands: try context.subcommands.map({ subcommand in
                        try parse(command: "\(command) \(subcommand)")
                     }))
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

    private func makeBlockParser(start: String, parser: @escaping ((Context) -> Void)) -> ((Context) -> Void) {
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
                parser(context)
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

    private func argumentParser(context: Context) {
        let line = context.lines[context.index]
        context.arguments.append(.init(argument: "", description: line))
    }

    private func optionParser(context: Context) {
        let line = context.lines[context.index]
        context.options.append(.init(long: "", short: nil, argument: nil, description: line))
    }

    private func subcommandParser(context: Context) {
        let line = context.lines[context.index]
        context.subcommands.append(.init(command: "", description: line, isDefault: false))
    }

    private func unexpectedStringParser(context: Context) {
        let line = context.lines[context.index]
        context.unexpectedStrings.append(line)
        context.index += 1
    }
}
