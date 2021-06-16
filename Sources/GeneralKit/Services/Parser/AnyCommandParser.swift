//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public final class AnyCommandParser: Parser<CommandArguments> {

    public final class AnyOptionParser: Parser<String>, Codable {

        static let noValueOptions: [String] = ["version", "help"]

        public var long: String
        public var short: String?

        init(long: String, short: String? = nil) {
            self.long = long
            self.short = short
        }

        public override func parse(arguments: [String]) -> (String, [String])? {
            guard var first = arguments.first else {
                return nil
            }
            if first.starts(with: "--") {
                first.removeFirst(2)
                guard first == long else {
                    return nil
                }
            }
            else if first.starts(with: "-") {
                first.removeFirst()
                guard first == short else {
                    return nil
                }
            }
            else {
                return nil
            }
            var value: String = ""
            var arguments = arguments
            if AnyOptionParser.noValueOptions.contains(long) {
                let slice = arguments.dropFirst()
                arguments = Array(slice)
            }
            else if arguments.count > 1 {
                value = arguments[1]
                let slice = arguments.dropFirst(2)
                arguments = Array(slice)
            }
            else {
                return nil
            }
            return (value, arguments)
        }
    }

    public final class AnyArgumentParser: Parser<String>, Codable {
        public var name: String

        init(name: String) {
            self.name = name
        }

        public override func parse(arguments: [String]) -> (String, [String])? {
            guard let first = arguments.first else {
                return nil
            }
            return (first, Array(arguments.dropFirst()))
        }
    }

    public var name: String = ""
    public var optionParsers: [String: AnyOptionParser] = [:]
    public var argumentParsers: [String: AnyArgumentParser] = [:]
    public var subcommandParsers: [String: AnyCommandParser] = [:]
    var isDefault: Bool = false

    public var defaultSubcommand: AnyCommandParser? {
        subcommandParsers.values.first(where: \.isDefault)
    }

    public override init() {
        //
    }

    public init(name: String = "",
                options: [String: AnyOptionParser] = [:],
                arguments: [String: AnyArgumentParser] = [:],
                subcommands: [String: AnyCommandParser] = [:],
                isDefault: Bool = false) {
        self.name = name
        self.optionParsers = options
        self.argumentParsers = arguments
        self.subcommandParsers = subcommands
        self.isDefault = isDefault
    }

    public override func parse(arguments: [String]) -> (CommandArguments, [String])? {
        guard let first = arguments.first, first == name else {
            return nil
        }
        var arguments = Array(arguments.dropFirst())
        let result = CommandArguments()
        var isParsed = false
        repeat {
            isParsed = false
            if let optionsParseResult = parse(arguments: arguments, parsers: self.optionParsers) {
                result.options = optionsParseResult.0
                arguments = optionsParseResult.1
                isParsed = true
            }
            if let subcommandsParseResult = parse(arguments: arguments, parsers: self.subcommandParsers) {
                result.subcommands = subcommandsParseResult.0
                arguments = subcommandsParseResult.1
                isParsed = true
            }
            if let argumentsParseResult = parse(arguments: arguments, parsers: self.argumentParsers) {
                result.arguments = argumentsParseResult.0
                arguments = argumentsParseResult.1
                isParsed = true
            }
        } while isParsed && arguments.isEmpty == false
        if arguments.isEmpty == false {
            if let command = defaultSubcommand,
               let parseResult = command.parse(arguments: [command.name] + arguments),
               parseResult.1.isEmpty {
                result.subcommands[command.name] = parseResult.0
                arguments = []
            }
            else {
                return nil
            }
        }
        return (result, arguments)
    }

    private func parse<Value>(arguments: [String],
                              parsers: [String: Parser<Value>]) -> ([String: Value], [String])? {
        var result = [String: Value]()
        var arguments = arguments

        parsers.forEach { key, parser in
            guard let parseResult = parser.parse(arguments: arguments) else {
                return
            }
            result[key] = parseResult.0
            arguments = parseResult.1
        }

        guard result.isEmpty == false else {
            return nil
        }
        return (result, arguments)
    }
}
