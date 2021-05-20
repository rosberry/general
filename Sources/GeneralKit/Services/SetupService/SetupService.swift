//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public protocol HasSetupService {
    var setupService: SetupService { get }
}

public protocol SetupService {

    func setup(githubPath: String,
               shouldLoadGlobally: Bool,
               customizationHandler: (([FileInfo]) throws -> Void)?) throws

    func setup(githubPath: String, shouldLoadGlobally: Bool) throws
}

public extension SetupService {

    func setup(githubPath: String, shouldLoadGlobally: Bool) throws {
        try self.setup(githubPath: githubPath,
                       shouldLoadGlobally: shouldLoadGlobally,
                       customizationHandler: nil)
    }
}
