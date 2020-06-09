//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser

struct Variable {

    let key: String
    let value: String
}

extension Variable: ExpressibleByArgument {

    init?(argument: String) {
        let components = argument.components(separatedBy: ":")
        guard components.count == 2 else {
            return nil
        }
        self.init(key: components[0], value: components[1])
    }
}
