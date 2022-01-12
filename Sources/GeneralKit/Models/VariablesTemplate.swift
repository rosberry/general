//
//  VariablesTemplate.swift
//  GeneralIOs
//
//  Created by Nick Tyunin on 11.11.2021.
//

import Stencil
import StencilSwiftKit

public class VariablesTemplate: Template {
    
    public var variables: [String]
    public required init(templateString: String, environment: Environment? = nil, name: String? = nil) {
        var variables: [String] = []
        var dynamicVariables: [String] = []
        let lexer = CustomLexer(templateString: templateString)
        let tokens = lexer.tokenize()
        var ifDepth = 0

        func add(dynamic: String) {
            guard dynamicVariables.contains(dynamic) == false else {
                return
            }
            dynamicVariables.append(dynamic)
        }

        func add(variable: String) {
            guard  ifDepth == 0 else {
                return
            }
            var variable = variable
            if let unfiltered = variable.split(separator: "|").first {
                variable = String(unfiltered).trimmingCharacters(in: .whitespaces)
            }
            guard variables.contains(variable) == false else {
                return
            }
            let components = variable.split(separator: ".")
            for i in 0..<components.count {
                let string = components[0...i].joined(separator: ".")
                guard dynamicVariables.contains(string) == false else {
                    return
                }
                let containsInGlobal = Export.global.contains { key, _ in
                    string == key
                }
                guard containsInGlobal == false else {
                    return
                }
            }
            variables.append(variable)
        }

        tokens.forEach { token in
            switch token.kind {
            case .variable:
                guard let name = token.components.first else {
                    return
                }
                add(variable: name)
            case .block:
                let components = token.components
                guard let tag = components.first else {
                    return
                }
                switch tag {
                case "for":
                    guard components.count >= 4 else {
                        return
                    }
                    add(dynamic: "forloop")
                    add(dynamic: components[1])
                    add(variable: components[3])
                case "using":
                    guard components.count >= 4 else {
                        return
                    }
                    add(dynamic: components[3])
                case "if":
                    ifDepth += 1
                case "endif":
                    ifDepth -= 1
                default:
                    return
                }
            default:
                return
            }
        }
        self.variables = Array(Set(variables))
        super.init(templateString: templateString, environment: environment, name: name)
    }

    public override func render(_ dictionary: [String : Any]? = nil) throws -> String {
        var context = [String : Any]()
        Export.global.forEach { key, value in
            context[key] = value
        }
        dictionary?.forEach{ key, value in
            context[key] = value
        }
        return try super.render(context)
    }
}
