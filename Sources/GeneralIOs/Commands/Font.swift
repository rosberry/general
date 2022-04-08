//
//  File.swift
//  GeneralIOs
//
//  Created by Evgeny Schwarzkopf on 29.03.2022.
//

import Foundation
import ArgumentParser
import GeneralKit
import AEXML
import Stencil
import PathKit

public final class Font: ParsableCommand {

    private enum Constant {
        static let fontsFolderPath = "./Resources/Fonts"
        static let extensionFolderPath = "./Classes/Presentation/Extensions"
        static var extensionFontPath = "./Classes/Presentation/Extensions/UIFonts+App.swift"
        static let fontsTemplatePath = "./.templates/rsb_fonts"
        static let commonTemplatePath = "./.templates/common"
        static let commandTemplatePath = "./.templates"
        static let fontValue = "UIAppFonts"
        static let fontTemplateName = "UIFonts+App.stencil"
        static let notFoundTemplate = #"""
                                      Is not found folder templates in directory.
                                      Please, call command `general setup -r rosberry/general-templates\ ios`
                                      """#
    }

    private enum Error: Swift.Error, LocalizedError {
        case notFoundFonts(String)
        case notFoundTarget(String)
        case notFoundInfoPlist(String)
        case invalidData
        case notFoundTemplate
        case somethingGoingWrong(String, String)

        public var errorDescription: String? {
            switch self {
            case let .notFoundFonts(path):
                return red("Is not found fonts in path \(path). Please check correctly path.")
            case let .notFoundTarget(targetName):
                return red("Is not found target - \(targetName)")
            case let .notFoundInfoPlist(path):
                return red("Is not found info plist by path \(path)")
            case .invalidData:
                return red("Data is not valid. Please check correctly Info.plist")
            case .notFoundTemplate:
                return red(Constant.notFoundTemplate)
            case .somethingGoingWrong(let title, let subtitle):
                return red("""
                          Something going wrong...
                          I try it \(title) ...
                          But I can't perform because \(subtitle).
                          Please check and try again.
                          """)
            }
        }
    }

    typealias Dependencies = HasFileHelper &
                             HasProjectServiceFactory &
                             HasSpecFactory
    private lazy var fileHelper = dependencies.fileHelper
    public static let configuration: CommandConfiguration = .init(abstract: "Add fonts in project.")
    private lazy var projectService: ProjectService = {
        let service = dependencies.projectServiceFactory.makeProjectService(path: "./")
        try? service.createProject(projectName: "\(unwrappedProjectName).xcodeproj")
        return service
    }()

    private lazy var specFactory: SpecFactory = dependencies.specFactory

    private lazy var generalSpec: GeneralSpec? = {
        let pathURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
        let specURL = URL(fileURLWithPath: Constants.generalSpecName, relativeTo: pathURL)
        return try? specFactory.makeSpec(url: specURL)
    }()

    private lazy var unwrappedProjectName: String = {
        return projectName ?? ask("Please enter project name") ?? ""
    }()

    private lazy var projectName: String? = {
        return (try? fileHelper.contentsOfDirectory(at: "./").first { file in
            file.url.pathExtension == "xcodeproj"
        })?.url.deletingPathExtension().lastPathComponent
    }()

    private var dependencies: Dependencies {
        Services
    }

    // MARK: - Parameters

    @Option(name: .shortAndLong, help: "Specify a path to folder fonts.")
    var path: String

    @Option(name: .long, help: "The target to which add files.", completion: .targets)
    var target: String?

    @Option(name: .shortAndLong, completion: .directory, help: "The path for the project.")
    var directoryPath: String = FileManager.default.currentDirectoryPath

    // MARK: - Lifecycle

    public func run() throws {
        try fontServiceFactory.addFontsInProject(path, target: target)
    }

    public init() {
    }
}
