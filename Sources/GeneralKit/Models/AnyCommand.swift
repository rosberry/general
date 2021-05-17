//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public final class AnyCommand: ParsableCommand {

    public final class ParseResult {
        public var options: [String: String]
        public var arguments: [String: String]
        public var subcommands: [String: ParseResult]

        init(options: [String: String] = [:],
             arguments: [String: String] = [:],
             subcommands: [String: ParseResult] = [:]) {
            self.options = options
            self.arguments = arguments
            self.subcommands = subcommands
        }
    }

    public final class AnyOption: Codable {

        static let noValueOptions: [String] = ["version", "help"]

        public var long: String
        public var short: String?

        init(long: String, short: String? = nil) {
            self.long = long
            self.short = short
        }

        public func parse(arguments: [String]) -> (String, [String])? {
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
            if AnyOption.noValueOptions.contains(long) {
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

    public final class AnyArgument: Codable {
        public var name: String

        init(name: String) {
            self.name = name
        }

        public func parse(arguments: [String]) -> (String, [String])? {
            guard let first = arguments.first else {
                return nil
            }
            return (first, Array(arguments.dropFirst()))
        }
    }

    public var name: String = ""
    public var options: [String: AnyOption] = [:]
    public var arguments: [String: AnyArgument] = [:]
    public var subcommands: [String: AnyCommand] = [:]
    var isDefault: Bool = false

    public var defaultSubcommand: AnyCommand? {
        subcommands.values.first(where: \.isDefault)
    }

    required public init() {

    }

    public init(name: String = "",
                options: [String: AnyOption] = [:],
                arguments: [String: AnyArgument] = [:],
                subcommands: [String: AnyCommand] = [:],
                isDefault: Bool = false) {
        self.name = name
        self.options = options
        self.arguments = arguments
        self.subcommands = subcommands
        self.isDefault = isDefault
    }

    public func parse(arguments: [String]) -> (ParseResult?, [String])? {
        guard let first = arguments.first, first == name else {
            return nil
        }
        var arguments = Array(arguments.dropFirst())
        let result = ParseResult()

        options.values.forEach { option in
            guard let parseResult = option.parse(arguments: arguments) else {
                return
            }
            result.options[option.long] = parseResult.0
            arguments = parseResult.1
        }
        subcommands.values.forEach { subcommand in
            guard let parseResult = subcommand.parse(arguments: arguments) else {
                return
            }
            result.subcommands[subcommand.name] = parseResult.0
            arguments = parseResult.1
        }
        self.arguments.values.forEach { argument in
            guard let parseResult = argument.parse(arguments: arguments) else {
                return
            }
            result.arguments[argument.name] = parseResult.0
            arguments = parseResult.1
        }
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
}
