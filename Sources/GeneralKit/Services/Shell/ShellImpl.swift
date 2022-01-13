//
// Copyright © 2021 Rosberry. All rights reserved.
//
import Foundation

public final class ShellImpl: Shell {

    public struct Error: Swift.Error {
        public let terminationStatus: Int32
        public let errorData: Data?
        public let outputData: Data?
        public var message: String? {
            errorData?.shellOutput()
        }
        public var output: String? {
            outputData?.shellOutput()
        }
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
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        if #available(OSX 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()
        let statusCode = process.terminationStatus
        if statusCode == 0 {
            return statusCode
        }
        else {
            throw Error(terminationStatus: statusCode, errorData: nil, outputData: nil)
        }
    }

    public func callAsFunction(silent command: String) throws -> String {
        observer?(.start(command: command, kind: .silent))
        let process = Process()
        Self.processCreationHandler?(process)
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        return try output(of: process, command: [command])
    }

    private func output(of process: Process, command: [String]) throws -> String {
        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        process.standardOutput = stdOutPipe
        process.standardError = stdErrPipe

        var outputData = Data()
        let outputQueue = DispatchQueue(label: "zsh-output-queue")
        stdOutPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                outputData.append(data)
            }
        }

        var errorData = Data()
        stdErrPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                errorData.append(data)
            }
        }

        if #available(OSX 10.13, *) {
            try process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()

        stdOutPipe.fileHandleForReading.readabilityHandler = nil
        stdErrPipe.fileHandleForReading.readabilityHandler = nil

        return try outputQueue.sync {
            if process.terminationStatus != 0 {
                throw Error(terminationStatus: process.terminationStatus,
                            errorData: errorData,
                            outputData: outputData)
            }
            else {
                return outputData.shellOutput()
            }
        }
    }

    private func terminationStatus(of process: Process) -> Int32 {
        process.launch()
        process.waitUntilExit()
        return process.terminationStatus
    }
}

extension ShellImpl: ProgressObservable {

    public enum State {
        case start(command: String, kind: CallKind)
    }

    @discardableResult
    public func subscribe(_ observer: @escaping (State) -> Void) -> Self {
        self.observer = observer
        return self
    }
}

extension ShellImpl: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
    }

    public func encode(to encoder: Encoder) throws {
    }
}

private extension Data {
    func shellOutput() -> String {
        guard let output = String(data: self, encoding: .utf8) else {
            return ""
        }

        guard !output.hasSuffix("\n") else {
            let endIndex = output.index(before: output.endIndex)
            return String(output[..<endIndex])
        }

        return output
    }
}
