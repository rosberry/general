//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import Yams
import PathKit

public final class ConfigFactory {

    enum Error: Swift.Error, CustomStringConvertible {
        case invalidConfig
        case write

        var description: String {
            switch self {
            case .invalidConfig:
                return "Could not load the config"
            case .write:
                return "Could not write the config file"
            }
        }
    }

    let decoder: YAMLDecoder
    let encoder: YAMLEncoder

    public init(decoder: YAMLDecoder = .init(), encoder: YAMLEncoder = .init()) {
        self.decoder = decoder
        self.encoder = encoder
    }

    public static var `default`: GeneralConfig?  = try? ConfigFactory().makeConfig(url: .init(fileURLWithPath: Constants.configPath))

    func makeConfig(url: URL) throws -> GeneralConfig {
        guard let string = try? String(contentsOf: url) else {
            return .init(version: Constants.version,
                         templatesRepo: nil,
                         availablePlugins: [],
                         installedPlugins: [],
                         pluginsRepos: [],
                         defaultCommand: "gen",
                         commands: ["gen": "General.Generate"])
        }
        return try decoder.decode(from: string)
    }

    func makeData(config: GeneralConfig) throws -> Data? {
        let string = try encoder.encode(config)
        return string.data(using: .utf8)
    }

    public func update( _ handler: (GeneralConfig) -> GeneralConfig) throws {
        guard let config = ConfigFactory.default else {
            throw Error.invalidConfig
        }
        do {
            let data = try makeData(config: handler(config))
            try data?.write(to: .init(fileURLWithPath: Constants.configPath))
        }
        catch {
            throw Error.write
        }
    }

    public static func update( _ handler: (GeneralConfig) -> GeneralConfig) throws {
        try ConfigFactory().update(handler)
    }
}
