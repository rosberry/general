//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public final class RunConfig {
    let general: AnyCommandParser
    let plugins: [AnyCommandParser]
    let overrides: [String: String]

    init(general: AnyCommandParser, plugins: [AnyCommandParser], overrides: [String: String]) {
        self.general = general
        self.plugins = plugins
        self.overrides = overrides
    }
}
