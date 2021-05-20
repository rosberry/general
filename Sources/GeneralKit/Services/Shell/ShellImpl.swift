//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public final class ShellImpl: Shell {

    public enum Error: Swift.Error {
        case failure(ShellIO)
        case badStatusCode(String, Int32)
    }

    public enum CallKind {
        case loud
        case silent
    }

    public static var processCreationHandler: ((Process) -> Void)?
    private var observer: ((State) -> Void)?

    public init() {
    }

    @discardableResult
    public func callAsFunction(loud command: String) throws -> Int32 {
        observer?(.start(command: command, kind: .loud))
        let process = Process()
        Self.processCreationHandler?(process)
        process.launchPath = Constants.shell
        process.arguments = ["-c", command]
        process.launch()
        process.waitUntilExit()
        let statusCode = process.terminationStatus
        if statusCode == 0 {
            return statusCode
        }
        else {
            throw Error.badStatusCode(command, statusCode)
        }
    }

    public func callAsFunction(throw command: String) throws {
        observer?(.start(command: command, kind: .loud))
        let process = Process()
        Self.processCreationHandler?(process)
        process.launchPath = Constants.shell
        process.arguments = ["-c", command]
        process.launch()
    }

    public func callAsFunction(silent command: String) throws -> ShellIO {
        observer?(.start(command: command, kind: .silent))
        let process = Process()
        Self.processCreationHandler?(process)
        process.launchPath = Constants.shell
        process.arguments = ["-c", command]
        let shellIO = try output(of: process, command: [command])
        if shellIO.status == 0 {
            return shellIO
        }
        else {
            throw Error.failure(shellIO)
        }
    }

    private func output(of process: Process, command: [String]) throws -> ShellIO {
        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        let stdInFileHandle = Pipe().fileHandleForReading
        process.standardOutput = stdOutPipe
        process.standardError = stdErrPipe
        process.standardInput = stdInFileHandle
        process.launch()
        process.waitUntilExit()
        let handlersStrings = [stdOutPipe.fileHandleForReading,
                               stdErrPipe.fileHandleForReading,
                               stdInFileHandle].map { handler -> String in
            let outputData = handler.readDataToEndOfFile()
            return String(data: outputData, encoding: .utf8) ?? ""
        }
        return ShellIO(stdOut: handlersStrings[0],
                       stdErr: handlersStrings[1],
                       stdIn: handlersStrings[2],
                       status: process.terminationStatus,
                       command: command)
    }

    private func terminationStatus(of process: Process) -> Int32 {
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus
    }
}

extension ShellImpl {
    public enum State {
        case start(command: String, kind: CallKind)
    }

    @discardableResult
    public func subscribe(_ observer: @escaping (State) -> Void) -> Self {
        self.observer = observer
        return self
    }
}
