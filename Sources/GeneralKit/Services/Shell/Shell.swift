//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public struct ShellIO {
    public let stdOut: String
    public let stdErr: String
    public let stdIn: String
    public let status: Int32
    public let command: [String]

    public init(stdOut: String, stdErr: String, stdIn: String, status: Int32, command: [String]) {
        self.stdOut = stdOut
        self.stdErr = stdErr
        self.stdIn = stdIn
        self.status = status
        self.command = command
    }
}

public protocol HasShell {
    var shell: Shell { get }
}

public protocol Shell {
    @discardableResult
    func callAsFunction(loud command: String) throws -> Int32
    func callAsFunction(throw command: String) throws
    func callAsFunction(silent command: String) throws -> ShellIO
}
