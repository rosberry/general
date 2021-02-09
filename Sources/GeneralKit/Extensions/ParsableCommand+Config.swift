//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public extension ParsableCommand {
    func config() throws -> GeneralConfig {
        guard let config = ConfigFactory.default else {
            throw ConfigFactory.Error.invalidConfig
        }
        return config
    }

    func updateConfig(handler: (GeneralConfig) -> GeneralConfig) throws {
        try ConfigFactory.update(handler)
    }
}
