//
//  VariablesTemplate.swift
//  GeneralIOs
//
//  Created by Nick Tyunin on 11.11.2021.
//

import Stencil

public class VariablesTemplate: Template {
    public var variables: [String]
    public required init(templateString: String, environment: Environment? = nil, name: String? = nil) {
        let pattern = "\\{\\{\\s*([a-zA-Z][a-zA-Z0-9.]*)\\s*\\}\\}"
        self.variables = Array(Set(parseAllRegexMatches(pattern: pattern, rangeIndex: 1, string: templateString)))
        super.init(templateString: templateString, environment: environment, name: name)
    }
}
