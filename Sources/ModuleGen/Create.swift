//
//  Created by Artem Novichkov on 05.06.2020.
//

import Foundation
import ArgumentParser

final class Create: ParsableCommand {

    private lazy var fileManager: FileManager = .default

    // MARK: - Parameters

    static let configuration: CommandConfiguration = .init(abstract: "Creates a new template.")

    @Option(name: [.short, .long], help: "The name of the template.")
    var template: String

    @Option(name: [.short, .long], help: "The path for the template.")
    var path: String?

    func run() throws {
        //folder url for a new template
        let url: URL
        if let path = path {
            url = URL(fileURLWithPath: path)
        }
        else {
            url = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(Constants.templatesFolderName)
        }

        // create a folder for a new template
        let moduleURL = url.appendingPathComponent(template)
        try fileManager.createDirectory(at: moduleURL, withIntermediateDirectories: true, attributes: nil)

        // create a spec for a new template
        if let specData = Constants.spec.data(using: .utf8) {
            let specURL = moduleURL.appendingPathComponent(Constants.specFilename)
            fileManager.createFile(atPath: specURL.path, contents: specData, attributes: nil)
        }

        // create a code folder for a new template
        let codeURL = moduleURL.appendingPathComponent(Constants.filesFolderName)
        try fileManager.createDirectory(at: codeURL, withIntermediateDirectories: true, attributes: nil)

        // create a template in files folder
        if let templateData = Constants.template.data(using: .utf8) {
            let templateURL = codeURL.appendingPathComponent(Constants.templateFilename)
            fileManager.createFile(atPath: templateURL.path, contents: templateData, attributes: nil)
        }
    }
}
