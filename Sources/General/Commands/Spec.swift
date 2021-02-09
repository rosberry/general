//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

public final class Spec: ParsableCommand {

    private lazy var specFactory: SpecFactory = .init()
    private lazy var fileManager: FileManager = .default

    // MARK: - Parameters

    public static let configuration: CommandConfiguration = .init(abstract: "Creates a new spec.")

    @Option(name: .shortAndLong, completion: .directory, help: "The path for the template.")
    var path: String = FileManager.default.currentDirectoryPath

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        //folder url for a new spec
        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        let specURL = URL(fileURLWithPath: Constants.generalSpecName, relativeTo: pathURL)

        if fileManager.fileExists(atPath: specURL.path) {
            print("\(Constants.generalSpecName) already exists.")
            return
        }

        let spec = GeneralSpec(outputs: [])
        if let specData = try? specFactory.makeData(spec: spec) {
            fileManager.createFile(atPath: specURL.path, contents: specData, attributes: nil)
            print("🎉 Spec was successfully created.")
        }
    }
}
