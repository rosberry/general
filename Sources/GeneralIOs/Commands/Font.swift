//
//  Font.swift
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

    typealias Dependencies = HasFontServiceFactory
    public static let configuration: CommandConfiguration = .init(abstract: "Add fonts in project.")

    private lazy var fontServiceFactory: FontService = {
        let service = dependencies.fontServiceFactory.makeFontService(directoryPath: directoryPath)
        return service
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
