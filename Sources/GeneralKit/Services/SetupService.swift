//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public final class SetupService {

    private lazy var githubService: GithubService = .init()
    private lazy var fileHelper: FileHelper = .default

    public init() {
        //
    }

    public func setup(githubPath: String, shouldLoadGlobally: Bool, customizationHandler: (([FileInfo]) throws -> Void)? = nil) throws {
        let destination = getTemplatesDestination(shouldLoadGlobally: shouldLoadGlobally)
        let files = try downloadFiles(from: githubPath, destination: destination)
        try customizationHandler?(files)
        displayResult(files)
    }

    // MARK: - Private

    private func downloadFiles(from path: String, destination: URL) throws -> [FileInfo] {
        print("Loading setup files from \(path)...")

        return try githubService.downloadFiles(at: path,
                                               to: destination.path,
                                               askForUpdate: { old, new in
            guard isGeneralSpec(old) == false else {
                return askBool(question: "General spec already exists. Do you want to replace it? (Yes, No)")
            }
            return askBool(question: "Could not compare downloaded template" +
                                     green(destination.lastPathComponent) +
                                     " with installed one. Do you want to replace it? (Yes, No)")
        }, matchHandler: { file in
            isGeneralSpec(file) || isTemplatesFolder(file)
        })
    }

    private func displayResult(_ templates: [FileInfo]) {
        print()
        if templates.isEmpty {
            print(yellow("No templates modified 🤷‍♂️"))
        }
        else {
            print("✨ Updated templates:")
            templates.forEach { file in
                print(green(file.url.lastPathComponent))
            }
        }
    }

    private func getTemplatesDestination(shouldLoadGlobally: Bool) -> URL {
        if shouldLoadGlobally {
            return fileHelper.fileManager.homeDirectoryForCurrentUser + Constants.templatesFolderName
        }
        else {
            return URL(fileURLWithPath: Constants.relativeCurrentPath + Constants.templatesFolderName)
        }
    }

    private func isGeneralSpec(_ file: FileInfo) -> Bool {
        file.url.lastPathComponent == Constants.generalSpecName
    }

    private func isTemplatesFolder(_ file: FileInfo) -> Bool {
        file.isDirectory && fileHelper.fileManager.fileExists(atPath: (file.url + Constants.specFilename).path)
    }
}
