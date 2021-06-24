//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public extension ParsableCommand {

    var configFactory: ConfigFactory {
        Services.configFactory
    }

    func config() throws -> GeneralConfig {
        guard let config = configFactory.shared else {
            throw ConfigFactoryImpl.Error.invalidConfig
        }
        return config
    }

    func updateConfig(handler: (GeneralConfig) throws -> GeneralConfig) throws {
        try configFactory.update(handler)
    }
}
