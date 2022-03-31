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
        static let extensionFolderPath = "./Classes/Core/Extensions"
        static var extensionFontPath = "./Classes/Core/Extensions/UIFonts+App.swift"
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
                             HasProjectServiceFactory
    private lazy var fileHelper = dependencies.fileHelper
    public static let configuration: CommandConfiguration = .init(abstract: "Add fonts in project.")
    private lazy var projectService: ProjectService = {
        let service = dependencies.projectServiceFactory.makeProjectService(path: "./")
        try? service.createProject(projectName: "\(unwrappedProjectName).xcodeproj")
        return service
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

    // MARK: - Lifecycle

    public func run() throws {
        let fonts = fonts(in: URL(fileURLWithPath: path))

        guard fonts.isEmpty == false else {
            throw Error.notFoundFonts(path)
        }

        let targetName = target ?? unwrappedProjectName

        guard targetName != "" else {
            throw Error.notFoundTarget(targetName)
        }

        let infoPlistPath = URL(fileURLWithPath: "./\(unwrappedProjectName)/Info.plist")

        if fileHelper.fileManager.fileExists(atPath: Constant.fontsFolderPath) == false {
            try fileHelper.createDirectory(at: Constant.fontsFolderPath)
        }

        if fileHelper.fileManager.fileExists(atPath: Constant.extensionFolderPath) == false {
            try fileHelper.createDirectory(at: Constant.extensionFolderPath)
        }

        guard let data = try? Data(contentsOf: infoPlistPath) else {
            throw Error.notFoundInfoPlist(infoPlistPath.path)
        }

        guard let xmlDoc = try? AEXMLDocument(xml: data) else {
            throw Error.invalidData
        }

        let plsit = xmlDoc.root["dict"]

        let index = plsit.children.firstIndex { e in
            e.value == Constant.fontValue
        }

        let appFonts: AEXMLElement
        if let i = index {
            appFonts = plsit.children[i + 1];
        }
        else {
            plsit.addChild(.init(name: "key", value: Constant.fontValue))
            appFonts = .init(name: "array")
            plsit.addChild(appFonts)
        }

        try addFontsInInfoPlistAndFolderFonts(with: fonts,
                                              appFonts: appFonts,
                                              target: targetName)

        try xmlDoc.xml.write(toFile: infoPlistPath.path, atomically: true, encoding: .utf8)

        guard fileHelper.fileManager.fileExists(atPath: Constant.commandTemplatePath) else {
            throw Error.notFoundTemplate
        }

        let env = Environment(loader: FileSystemLoader(paths: [
            Path(Constant.fontsTemplatePath),
            Path(Constant.commonTemplatePath)
        ]))

        env.extensions.forEach { ext in
            ext.registerStencilSwiftExtensions()
            ext.registerFilter("fontFunction") { arg in
                guard let name = arg as? String else {
                    return arg
                }
                return name.filter { !"-".contains($0) }.capitalizingFirstLetter()
            }
        }

        let fontName = appFonts.children.compactMap { font in
            font.value?.filter { !".ttf.otf".contains($0) }
        }

        guard let result = try? env.renderTemplate(name: Constant.fontTemplateName,
                                                   context: ["fonts": fontName]) else {
            throw Error.somethingGoingWrong("generate ", "check font template in ./templates")
        }

        do {
            try result.write(toFile: Constant.extensionFontPath, atomically: true, encoding: .utf8)
        }
        catch {
            throw Error.somethingGoingWrong("write extension font", error.localizedDescription)
        }

        // Same thing
        sleep(1)

        do {
            try projectService.addFile(targetName: targetName, filePath: Path(Constant.extensionFontPath))
        }
        catch {
           throw Error.somethingGoingWrong("add file in target", error.localizedDescription)
        }

        do {
            try projectService.write()
            print("✨ \(green("Successfully")) completed added fonts... ✨")
        }
        catch {
           throw Error.somethingGoingWrong("save changes", error.localizedDescription)
        }
    }

    public init() {
    }

    private func addFontsInInfoPlistAndFolderFonts(with fonts: [FileInfo],
                                                   appFonts: AEXMLElement,
                                                   target: String) throws {
        for newFont in fonts {
            var isContains: Bool = false
            for appFont in appFonts.children {
                if appFont.value == newFont.url.lastPathComponent {
                    isContains = true
                    break
                }
            }
            if isContains == false {
                appFonts.addChild(.init(name: "string", value: newFont.url.lastPathComponent))
                let destination = URL(fileURLWithPath: Constant.fontsFolderPath + "/" + newFont.url.lastPathComponent)
                if fileHelper.fileManager.fileExists(atPath: destination.path) == false {
                    do {
                        try fileHelper.fileManager.copyItem(at: newFont.url, to: destination)
                    }
                    catch {
                        throw Error.somethingGoingWrong("copy item", error.localizedDescription)
                    }

                    // Here setup sleep 1 second when copy item in directory after install target for file.
                    // if sleep delete when target is not install for file because cannot execute asynchronously.
                    sleep(1)

                    do {
                        try projectService.addFile(targetName: target, filePath: Path(destination.relativePath))
                        print("🎉 \(green("Added font:")) \(newFont.url.lastPathComponent) ... 🎉")
                    }
                    catch {
                        throw Error.somethingGoingWrong("add target", error.localizedDescription)
                    }
                }
            }
        }
    }

    private func fonts(in folder: URL) -> [FileInfo] {
        guard let filesInfo = try? fileHelper.contentsOfDirectory(at: folder) else {
            return []
        }
        return filesInfo.flatMap { file -> [FileInfo] in
            if file.isDirectory {
                return fonts(in: file.url)
            }

            let ext = file.url.pathExtension
            switch ext {
            case "otf", "ttf":
                return [file]
            default:
                break
            }
            return []
        }
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).lowercased() + self.dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
