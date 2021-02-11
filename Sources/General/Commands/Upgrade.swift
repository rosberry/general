//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

public final class Upgrade: ParsableCommand {

    private lazy var upgradeService: UpgradeService = .init()
    public static let configuration: CommandConfiguration = .init(abstract: "Upgrades general to specified version")

    // MARK: - Parameters

    @Argument(help: "Branch or version tag",
              completion: .versions)
    var version: String?

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        let version = parseVersion()
        try upgradeService.upgrade(to: version)
        try updateConfig { config in
            var config = config
            config.version = upgradeService.fetchConcreteVersion(from: version)
            return config
        }
    }

    // MARK: - Private

    private func parseVersion() -> UpgradeService.Version {
        if let string = self.version {
            return .concrete(string)
        }
        else {
            return .latest
        }
    }
}
