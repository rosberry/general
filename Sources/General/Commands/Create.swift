//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser
import GeneralKit

public final class Create: ParsableCommand {

    typealias Dependencies = HasFileHelper & HasSpecFactory

    private lazy var fileManager: FileManager = dependencies.fileHelper.fileManager
    private lazy var specFactory: SpecFactory = dependencies.specFactory

    var dependencies: Dependencies {
        Services
    }

    // MARK: - Parameters

    public static let configuration: CommandConfiguration = .init(abstract: "Creates a new template.")

    @Option(name: .shortAndLong, help: "The name of the template.")
    var template: String

    @Option(name: .shortAndLong, help: "The path for the template.", completion: .directory)
    var path: String?

    // MARK: - Lifecycle

    public init() {
    }

    public func run() throws {
        //folder url for a new template
        let url: URL
        if let path = path {
            url = URL(fileURLWithPath: path)
        }
        else {
            url = fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        }

        // create a folder for a new template
        let moduleURL = url + template
        try fileManager.createDirectory(at: moduleURL, withIntermediateDirectories: true, attributes: nil)

        // create a spec for a new template
        let spec = TemplateSpec(files: [.init(template: Constants.filesFolderName + "/" + Constants.templateFileName)],
                                suffix: nil)
        if let specData = try? specFactory.makeData(spec: spec) {
            let specURL = moduleURL + Constants.specFilename
            fileManager.createFile(atPath: specURL.path, contents: specData, attributes: nil)
        }

        // create a code folder for a new template
        let codeURL = moduleURL + Constants.filesFolderName
        try fileManager.createDirectory(at: codeURL, withIntermediateDirectories: true, attributes: nil)

        // create a template in files folder
        if let templateData = Constants.template.data(using: .utf8) {
            let templateURL = codeURL + Constants.templateFileName
            fileManager.createFile(atPath: templateURL.path, contents: templateData, attributes: nil)
            print("🎉 \(template) template was successfully created.")
        }
    }
}
