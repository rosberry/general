//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser

public struct Variable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

extension Variable: ExpressibleByArgument {

    public init?(argument: String) {
        let components = argument.components(separatedBy: ":")
        guard components.count == 2 else {
            return nil
        }
        self.init(key: components[0], value: components[1])
    }
}
