//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public protocol ProgressObservable {
    associatedtype State

    func subscribe(_ observer: @escaping (State) -> Void) -> Self
}

public protocol HasShell {
    var shell: Shell { get }
}

public protocol Shell {
    @discardableResult
    func callAsFunction(loud command: String) throws -> Int32
    @discardableResult
    func callAsFunction(silent command: String) throws -> String
}
