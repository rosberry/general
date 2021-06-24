//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import PathKit
import Foundation

public enum UpgradeVersion {
    case current
    case latest
    case concrete(String)
}

public protocol HasUpgradeService {
    var upgradeService: UpgradeService { get }
}

public protocol UpgradeService {
    func upgrade(to version: UpgradeVersion, customizationHandler: (() throws -> Void)?) throws
    func fetchConcreteVersion(from version: UpgradeVersion) -> String
}

public extension UpgradeService {
    func upgrade(to version: UpgradeVersion) throws {
        try self.upgrade(to: version, customizationHandler: nil)
    }
}
