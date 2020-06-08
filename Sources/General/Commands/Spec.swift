//
//  Created by Artem Novichkov on 05.06.2020.
//

import Foundation
import ArgumentParser
import Yams
import XcodeProj

final class Spec: ParsableCommand {

    private lazy var fileManager: FileManager = .default
    private lazy var projectService: ProjectService = .init(path: .init(path))

    // MARK: - Parameters

    static let configuration: CommandConfiguration = .init(abstract: "Creates a new spec.")

    @Option(name: [.short, .long], default: FileManager.default.currentDirectoryPath, help: "The path for the template.")
    var path: String

    func run() throws {
        //folder url for a new spec
        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        let specURL = URL(fileURLWithPath: Constants.generalSpecName, relativeTo: pathURL)

        if fileManager.fileExists(atPath: specURL.path) {
            print("\(Constants.generalSpecName) already exists.")
            return
        }
        let contents = try fileManager.contentsOfDirectory(atPath: pathURL.path)
        var projectName = Constants.projectName
        if let name = contents.first(where: { content in content.contains(".xcodeproj") }) {
            projectName = name
        }

        // get organization name if possible
        var company: String?
        try? projectService.createProject(projectName: projectName)
        if let attributes = try? projectService.readAttributes(),
            let organizationName = attributes["ORGANIZATIONNAME"] as? String {
            company = organizationName
        }

        // create a new spec
        let spec = GeneralSpec(project: projectName, company: company)
        let specString = try YAMLEncoder().encode(spec)
        if let specData = specString.data(using: .utf8) {
            fileManager.createFile(atPath: specURL.path, contents: specData, attributes: nil)
            print("🎉 Spec was successfully created.")
        }
    }
}
