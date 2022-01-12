//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public final class AnyCommandParser: Parser<CommandArguments> {

    public final class AnyOptionParser: Parser<String>, Codable {

        static let noValueOptions: [String] = ["version", "help"]
        static let optionalValueOptions: [String] = ["generate-completion-script"]

        public var long: String
        public var short: String?
        var isRequired: Bool = false

        init(long: String, short: String? = nil, isRequired: Bool = false) {
            self.long = long
            self.short = short
            self.isRequired = isRequired
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
            else if arguments.count == 1 && AnyOptionParser.optionalValueOptions.contains(long) {
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
                isDefault: Bool = false,
                isRequired: Bool = false) {
        self.name = name
        self.optionParsers = options
        self.argumentParsers = arguments
        self.subcommandParsers = subcommands
        self.isDefault = isDefault
        self.optionParsers["generate-completion-script"] = AnyOptionParser(long: "generate-completion-script")
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
            if let (matchedOptions, remainingArguments) = parse(arguments: arguments, parsers: self.optionParsers) {
                result.options = matchedOptions
                arguments = remainingArguments
                isParsed = true
            }
            if let (matchedSubcommands, remainingArguments) = parse(arguments: arguments, parsers: self.subcommandParsers) {
                result.subcommands = matchedSubcommands
                arguments = remainingArguments
                isParsed = true
            }
            if let (matchedArguments, remainingArguments) = parse(arguments: arguments, parsers: self.argumentParsers) {
                result.arguments = matchedArguments
                arguments = remainingArguments
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

        var missingRequiredOptions = false
        optionParsers.forEach { key, parser in
            guard parser.isRequired else {
                return
            }
            if result.options[key] == nil {
                missingRequiredOptions = true
            }
        }
        guard missingRequiredOptions == false else {
            return nil
        }
        return (result, arguments)
    }

    private func parse<Value>(arguments: [String],
                              parsers: [String: Parser<Value>]) -> ([String: Value], [String])? {
        var result = [String: Value]()
        var arguments = arguments

        parsers.forEach { key, parser in
            guard let (matchedValue, remainingArguments) = parser.parse(arguments: arguments) else {
                return
            }
            result[key] = matchedValue
            arguments = remainingArguments
        }

        guard result.isEmpty == false else {
            return nil
        }
        return (result, arguments)
    }
}
