//
//  Created by Evgeny Schwarzkopf on 08.04.2022.
//

import Foundation
import ArgumentParser
import GeneralKit
import AEXML
import Stencil
import PathKit

public final class FontService {

    private enum Constant {
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

    private lazy var projectName: String? = {
        return (try? fileHelper.contentsOfDirectory(at: "./").first { file in
            file.url.pathExtension == "xcodeproj"
        })?.url.deletingPathExtension().lastPathComponent
    }()

    private lazy var unwrappedProjectName: String = {
        return projectName ?? ask("Please enter project name") ?? ""
    }()

    private var dependencies: Dependencies {
        Services
    }

    private let directoryPath: String

    public init(directoryPath: String) {
        self.directoryPath = directoryPath
    }

    public func addFontsInProject(_ fontsPath: String, target: String?) throws {
        let fonts = fonts(in: URL(fileURLWithPath: fontsPath))
        let infoPlistURL = URL(fileURLWithPath: "./\(unwrappedProjectName)/Info.plist")

        guard fonts.isEmpty == false else {
            throw Error.notFoundFonts(fontsPath)
        }

        let targetName = target ?? unwrappedProjectName

        guard targetName != "" else {
            throw Error.notFoundTarget(targetName)
        }

        guard let fontSpec = generalSpec?.font else {
            throw Error.notFoundTemplate
        }

        try createGroupIfNeeded(fontSpec)

        guard let infoPlistData = try? Data(contentsOf: infoPlistURL) else {
            throw Error.notFoundInfoPlist(infoPlistURL.path)
        }

        let appFonts = try writeFontsInInfoPlistAndFolderFonts(fonts,
                                                               infoPlistData: infoPlistData,
                                                               infoPlistPath: infoPlistURL.path,
                                                               fontSpec: fontSpec,
                                                               target: targetName)

        try renderTemplateAndWrite(appFonts: appFonts, fontSpec: fontSpec)

        // Same thing
        sleep(1)

        try addFileInProject(targetName, filePath: Path(fontSpec.extensionFontPath))
        try write()
    }

    private func write() throws {
        do {
            try projectService.write()
            print("✨ \(green("Successfully")) completed added fonts... ✨")
        }
        catch {
           throw Error.somethingGoingWrong("save changes", error.localizedDescription)
        }
    }

    private func addFileInProject(_ target: String, filePath: Path) throws {
        do {
            try projectService.addFile(targetName: target, filePath: filePath, sourceTree: .group)
        }
        catch {
           throw Error.somethingGoingWrong("add file in target", error.localizedDescription)
        }
    }

    private func renderTemplateAndWrite(appFonts: AEXMLElement, fontSpec: FontSpec) throws {
        guard fileHelper.fileManager.fileExists(atPath: fontSpec.commandTemplatePath) else {
            throw Error.notFoundTemplate
        }

        let env = Environment(loader: FileSystemLoader(paths: [
            Path(fontSpec.fontsTemplatePath),
            Path(fontSpec.commonTemplatePath)
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
            URL(fileURLWithPath: font.value ?? "").deletingPathExtension().lastPathComponent
        }

        let company = generalSpec?.xcode.company ?? ask("Please enter license company") ?? ""
        let year = Calendar.current.component(.year, from: .init())

        guard let result = try? env.renderTemplate(name: fontSpec.fontTemplateName,
                                                   context: ["fonts": fontName,
                                                             "year": year,
                                                             "company": company]) else {
            throw Error.somethingGoingWrong("generate ", "check font template in ./templates")
        }

        do {
            try result.write(toFile: fontSpec.extensionFontPath, atomically: true, encoding: .utf8)
        }
        catch {
            throw Error.somethingGoingWrong("write extension font", error.localizedDescription)
        }
    }

    private func writeFontsInInfoPlistAndFolderFonts(_ fonts: [FileInfo],
                                                     infoPlistData: Data,
                                                     infoPlistPath: String,
                                                     fontSpec: FontSpec, target: String) throws -> AEXMLElement {
        guard let xmlDoc = try? AEXMLDocument(xml: infoPlistData) else {
            throw Error.invalidData
        }

        let plsit = xmlDoc.root["dict"]

        let index = plsit.children.firstIndex { e in
            e.value == fontSpec.fontValue
        }

        let appFonts: AEXMLElement
        if let i = index {
            appFonts = plsit.children[i + 1];
        }
        else {
            plsit.addChild(.init(name: "key", value: fontSpec.fontValue))
            appFonts = .init(name: "array")
            plsit.addChild(appFonts)
        }

        try addFontsInInfoPlistAndFolderFonts(with: fonts,
                                              fontsFolderPath: fontSpec.fontsFolderPath,
                                              appFonts: appFonts,
                                              target: target)

        try xmlDoc.xml.write(toFile: infoPlistPath, atomically: true, encoding: .utf8)
        return appFonts
    }

    private func addFontsInInfoPlistAndFolderFonts(with fonts: [FileInfo],
                                                   fontsFolderPath: String,
                                                   appFonts: AEXMLElement,
                                                   target: String) throws {
        for newFont in fonts {
            if appFonts.children.contains(where: { $0.value == newFont.url.lastPathComponent }) == false {
                appFonts.addChild(.init(name: "string", value: newFont.url.lastPathComponent))
                let destination = URL(fileURLWithPath: fontsFolderPath + "/" + newFont.url.lastPathComponent)
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
                        try projectService.addFile(targetName: target,
                                                   filePath: Path(destination.relativePath),
                                                   sourceTree: .group,
                                                   isResource: true)
                        print("🎉 \(green("Added font:")) \(newFont.url.lastPathComponent) ... 🎉")
                    }
                    catch {
                        throw Error.somethingGoingWrong("add target", error.localizedDescription)
                    }
                }
            }
        }
    }

    private func createGroupIfNeeded(_ fontSpec: FontSpec) throws {
        if fileHelper.fileManager.fileExists(atPath: fontSpec.fontsFolderPath) == false {
            try fileHelper.createDirectory(at: fontSpec.fontsFolderPath)
        }

        if fileHelper.fileManager.fileExists(atPath: fontSpec.extensionFolderPath) == false {
            try fileHelper.createDirectory(at: fontSpec.extensionFolderPath)
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

            let pathExtenstion = file.url.pathExtension
            switch pathExtenstion {
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
