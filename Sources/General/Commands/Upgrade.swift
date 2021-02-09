//
//  Copyright © 2020 Rosberry. All rights reserved.
//
import Foundation
import ArgumentParser

public final class Upgrade: ParsableCommand {

    private lazy var upgradeService: UpgradeService = .init()

    // MARK: - Parameters

    @Argument(help: "Branch or version tag",
              completion: .versions)
    var version: String?

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        if let version = self.version {
            try upgradeService.upgrade(to: .concrete(version))
        }
        else {
            try upgradeService.upgrade(to: .latest)
        }
    }
}
