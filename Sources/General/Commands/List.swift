//
//  Copyright © 2020 Rosberry. All rights reserved.
//
import Foundation
import ArgumentParser
import GeneralKit

public final class List: ParsableCommand {

    private lazy var fileManager: FileManager = .default
    public static let configuration: CommandConfiguration = .init(abstract: "List of available templates.")

    // MARK: - Parameters

    // MARK: - Lifecycle

    public func run() throws {
        let url = fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        try printContentOfDirectory(at: url)
    }

    public init() {
    }

    // MARK: - Private

    private func printContentOfDirectory(at url: URL) throws {
        var contents = try fileManager.contentsOfDirectory(at: url,
                                                           includingPropertiesForKeys: [.isDirectoryKey],
                                                           options: [.skipsHiddenFiles])
        contents.sort { lhs, rhs in
            if lhs.lastPathComponent == Constants.commonTemplatesFolderName {
                return true
            }
            if rhs.lastPathComponent == Constants.commonTemplatesFolderName {
                return false
            }
            return lhs.path < rhs.path
        }
        try contents.forEach { url in
            if url.lastPathComponent == Constants.commonTemplatesFolderName {
                try printCommonTemplates(at: url)
            }
            else if url.hasDirectoryPath {
                print(url.lastPathComponent)
            }
        }
    }

    private func printCommonTemplates(at url: URL) throws {
        var contents = try fileManager.contentsOfDirectory(at: url,
                                                           includingPropertiesForKeys: [.isDirectoryKey],
                                                           options: [.skipsHiddenFiles])
        contents = contents.filter { url in
            url.pathExtension == "stencil"
        }
        if contents.count > 0 {
            print("Common templates:")
        }
        for content in contents {
            print("\t", content.lastPathComponent)
        }
    }
}
