//
//  Created by Artem Novichkov on 05.06.2020.
//

import Foundation
import ArgumentParser

final class Spec: ParsableCommand {

    private lazy var fileManager: FileManager = .default

    // MARK: - Parameters

    static let configuration: CommandConfiguration = .init(abstract: "Creates a new spec.")

    @Option(name: [.short, .long], help: "The path for the template.")
    var path: String?

    func run() throws {
        //folder url for a new spec
        var url: URL
        if let path = path {
            url = URL(fileURLWithPath: path)
        }
        else {
            url = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        }
        let specURL = url + Constants.generalSpecName

        if fileManager.fileExists(atPath: specURL.path) {
            print("\(Constants.generalSpecName) already exists.")
            return
        }
        let contents = try fileManager.contentsOfDirectory(atPath: url.path)
        var projectName = Constants.projectName
        if let name = contents.first(where: { content in content.contains(".xcworkspace") }) {
            projectName = name
        }
        else if let name = contents.first(where: { content in content.contains(".xcodeproj") }) {
            projectName = name
        }

        // create a new spec
        if let specData = Constants.generalSpec(withProjectName: projectName).data(using: .utf8) {
            fileManager.createFile(atPath: specURL.path, contents: specData, attributes: nil)
        }
    }
}
