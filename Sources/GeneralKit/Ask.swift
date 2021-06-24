//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public func askBool(question: String) -> Bool {
    guard let result = ask(question) else {
        return askBool(question: question)
    }
    switch result.lowercased() {
    case "yes", "y":
        return true
    case "no", "n":
        return false
    default:
        return askBool(question: question)
    }
}

public func ask(_ question: String, default: String? = nil) -> String? {
    if let value = `default` {
        print("\(question) \(green("(\(value))")):", terminator: " ")
    }
    else {
        print("\(question):", terminator: " ")
    }
    guard let value = readLine(),
        value.isEmpty == false else {
        return `default`
    }
    return value
}

public func askChoice<Value: CustomStringConvertible>(_ question: String, values: [Value]) -> Value? {
    guard values.count > 1 else {
        return values.first
    }
    print("\(question):")
    values.enumerated().forEach { number, value in
        print("\(number + 1): \(value.description)")
    }
    print("0: cancel\n> ", terminator: " ")
    guard let answer = readLine(),
        let number = Int(answer) else {
        print("Invalid value entered")
        return askChoice(question, values: values)
    }
    guard number > 0 else {
        return nil
    }
    guard number <= values.count else {
        print("Please enter number in valid range")
        return askChoice(question, values: values)
    }
    return values[number - 1]
}
