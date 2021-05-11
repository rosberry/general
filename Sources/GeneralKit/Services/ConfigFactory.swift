//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import Yams
import PathKit

public final class ConfigFactory {

    enum Error: Swift.Error, CustomStringConvertible {
        case defaultConfig
        case invalidConfig
        case write

        var description: String {
            switch self {
            case .invalidConfig:
                return "Could not load the config"
            case .defaultConfig:
                return "No defalt config specified"
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

    public static var shared: GeneralConfig?  = try? ConfigFactory().makeConfig(url: .init(fileURLWithPath: Constants.configPath))

    public static var `default`: GeneralConfig?

    func makeConfig(url: URL) throws -> GeneralConfig {
        guard let string = try? String(contentsOf: url) else {
            guard let `default` = ConfigFactory.default else {
                throw Error.defaultConfig
            }
            return `default`
        }
        return try decoder.decode(from: string)
    }

    func makeData(config: GeneralConfig) throws -> Data? {
        let string = try encoder.encode(config)
        return string.data(using: .utf8)
    }

    public func update( _ handler: (GeneralConfig) throws -> GeneralConfig) throws {
        guard var config = ConfigFactory.shared else {
            throw Error.invalidConfig
        }
        config = try handler(config)
        do {
            ConfigFactory.shared = config
            let data = try makeData(config: config)
            try data?.write(to: .init(fileURLWithPath: Constants.configPath))
        }
        catch {
            throw Error.write
        }
    }

    public static func update( _ handler: (GeneralConfig) throws -> GeneralConfig) throws {
        try ConfigFactory().update(handler)
    }
}
