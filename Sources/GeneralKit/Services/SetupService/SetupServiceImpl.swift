//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public final class SetupServiceImpl: SetupService {

    public typealias Dependencies = HasFileHelper & HasGithubService & HasConfigFactory

    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func setup(githubPath: String, shouldLoadGlobally: Bool, customizationHandler: (([FileInfo]) throws -> Void)?) throws {
        let destination = getTemplatesDestination(shouldLoadGlobally: shouldLoadGlobally)
        let files = try downloadFiles(from: githubPath, destination: destination)
        try customizationHandler?(files)
        displayResult(files)
    }

    // MARK: - Private

    private func downloadFiles(from path: String, destination: URL) throws -> [FileInfo] {
        var path = path
        if let linkedPath = dependencies.configFactory.shared?.templatesRepos[path] {
            path = linkedPath
        }
        print("Loading setup files from \(path)...")
        var downloadedFiles = [FileInfo]()
        try dependencies.githubService.downloadFiles(at: path) { files in
            if let file = try updatedSpec(with: files) {
                downloadedFiles.append(file)
            }
            downloadedFiles.append(contentsOf: try updatedTemplates(with: files))
        }
        return downloadedFiles
    }

    private func updatedSpec(with files: [FileInfo]) throws -> FileInfo? {
        guard let file = files.first(where: isGeneralSpec) else {
            return nil
        }
        let destination = Constants.relativeCurrentPath + file.url.lastPathComponent
        let destinationFile = try dependencies.fileHelper.fileInfo(with: .init(fileURLWithPath: destination))
        guard !destinationFile.isExists ||
               askBool(question: "General spec already exists. Do you want to replace it? (Yes, No)") else {
            return nil
        }
        if destinationFile.isExists {
            try dependencies.fileHelper.removeFile(at: destinationFile.url)
        }
        try dependencies.fileHelper.moveFile(at: file.url, to: destinationFile.url)
        return destinationFile
    }

    private func updatedTemplates(with files: [FileInfo]) throws -> [FileInfo] {
        var downloadedFiles = [FileInfo]()
        guard let folder = files.first(where: isTemplatesFolder),
              let templates = try? dependencies.fileHelper.contentsOfDirectory(at: folder.url) else {
            return downloadedFiles
        }
        let path = Constants.relativeCurrentPath + Constants.templatesFolderName
        let destination = try dependencies.fileHelper.fileInfo(with: .init(fileURLWithPath: path))
        try templates.forEach { template in
            let templateURL = template.url
            let templateDestination = destination.url + template.url.lastPathComponent
            let destinationFile = try dependencies.fileHelper.fileInfo(with: templateDestination)
            if destinationFile.isExists {
                guard shouldUpdateTemplate(destinationFile, with: template) else {
                    return
                }
                try dependencies.fileHelper.removeFile(at: destinationFile.url)
            }
            try dependencies.fileHelper.moveFile(at: templateURL, to: destinationFile.url)
            downloadedFiles.append(destinationFile)
        }
        return downloadedFiles
    }

    private func displayResult(_ files: [FileInfo]) {
        print()
        if files.isEmpty {
            print(yellow("No files modified 🤷‍♂️"))
        }
        else {
            print("✨ Updated files:")
            files.forEach { file in
                print(green(file.url.lastPathComponent))
            }
        }
    }

    private func getTemplatesDestination(shouldLoadGlobally: Bool) -> URL {
        if shouldLoadGlobally {
            return dependencies.fileHelper.fileManager.homeDirectoryForCurrentUser
        }
        else {
            return URL(fileURLWithPath: Constants.relativeCurrentPath)
        }
    }

    private func isGeneralSpec(_ file: FileInfo) -> Bool {
        file.url.lastPathComponent == Constants.generalSpecName
    }

    private func isTemplatesFolder(_ file: FileInfo) -> Bool {
        file.url.lastPathComponent == Constants.templatesFolderName
    }

    private func shouldUpdateTemplate(_ destination: FileInfo, with file: FileInfo) -> Bool {
        guard let lhs = try? modificationDateOfFile(destination),
              let rhs = try? modificationDateOfFile(file) else {
                return askBool(question: "Could not compare downloaded template" +
                                         green(destination.url.lastPathComponent) +
                                         " with installed one. Do you want to replace it? (Yes, No)")
        }
        return rhs > lhs
    }

    private func modificationDateOfFile(_ file: FileInfo) throws -> Date? {
        guard file.isDirectory else {
            return file.contentModificationDate
        }
        let files = try dependencies.fileHelper.contentsOfDirectory(at: file.url)
        var date: Date?
        for file in files {
            guard let fileDate = try modificationDateOfFile(file) else {
                continue
            }
            guard let lastDate = date else {
                date = fileDate
                continue
            }
            if fileDate > lastDate {
                date = fileDate
            }
        }
        return date
    }
}
