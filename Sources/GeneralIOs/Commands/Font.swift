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

    private enum FontsError: Error {
        case notFoundTarget
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
            return
        }

        let targetName = target ?? unwrappedProjectName

        let infoPlistPath = URL(fileURLWithPath: "./\(unwrappedProjectName)/Info.plist")
        let fontsFolderPath = "./Resources/Fonts"
        let extensionFolderPath = "./Classes/Core/Extensions"
        let extensionFontPath = extensionFolderPath + "/UIFonts+App.swift"

        if fileHelper.fileManager.fileExists(atPath: fontsFolderPath) == false {
            try fileHelper.createDirectory(at: fontsFolderPath)
        }

        if fileHelper.fileManager.fileExists(atPath: extensionFolderPath) == false {
            try fileHelper.createDirectory(at: extensionFolderPath)
        }

        let data = try Data(contentsOf: infoPlistPath)
        let xmlDoc = try AEXMLDocument(xml: data)
        let plsit = xmlDoc.root["dict"]

        let index = plsit.children.firstIndex { e in
            e.value == "UIAppFonts"
        }

        let appFonts: AEXMLElement
        if let i = index {
            appFonts = plsit.children[i + 1];
        }
        else {
            plsit.addChild(.init(name: "key", value: "UIAppFonts"))
            appFonts = .init(name: "array")
            plsit.addChild(appFonts)
        }

        try addFontsInInfoPlistAndFolderFonts(with: fonts,
                                              appFonts: appFonts,
                                              target: targetName,
                                              fontsFolderPath: fontsFolderPath)

        try xmlDoc.xml.write(toFile: infoPlistPath.path, atomically: true, encoding: .utf8)

        let env = Environment(loader: FileSystemLoader(paths: [
            "./.templates/rsb_fonts",
            "./.templates/common"
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

        let result = try env.renderTemplate(name: "UIFonts+App.stencil",
                                         context: ["fonts": fontName])

        try result.write(toFile: extensionFontPath, atomically: true, encoding: .utf8)
        sleep(1)
        print("✨ Success completion fonts integration in project... ✨")
        try projectService.addFile(targetName: targetName, filePath: Path(extensionFontPath))
        try projectService.write()
    }

    public init() {
    }

    private func addFontsInInfoPlistAndFolderFonts(with fonts: [FileInfo],
                                                   appFonts: AEXMLElement,
                                                   target: String,
                                                   fontsFolderPath: String) throws {
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
                let destination = URL(fileURLWithPath: fontsFolderPath + "/" + newFont.url.lastPathComponent)
                if fileHelper.fileManager.fileExists(atPath: destination.path) == false {
                    try fileHelper.fileManager.copyItem(at: newFont.url, to: destination)
                    sleep(1)
                    print("🎉 Add font: \(newFont.url.lastPathComponent) in Project success... 🎉")
                    try projectService.addFile(targetName: target, filePath: Path(destination.relativePath))
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
