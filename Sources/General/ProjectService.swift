//
//  Created by Artem Novichkov on 07.06.2020.
//

import PathKit
import xcodeproj

final class ProjectService {

    enum Error: Swift.Error {
        case noProject
        case noGroup
    }

    /// Adds a file to the project
    /// - Parameters:
    ///   - path: The path to the project folder.
    ///   - projectName: The name of the Xcode project. Must contain .xcodeproj or .xcworkspace extension.
    ///   - filePath: the whole path to the file.
    /// - Throws: If the are no projects in pbxproj file of fails to create groups.
    func addFile(path: Path, projectName: String, filePath: Path) throws {
        let xcodeprojPath = path + Path(projectName)
        let xcodeproj = try XcodeProj(path: xcodeprojPath)
        guard let project = xcodeproj.pbxproj.projects.first else {
            throw Error.noProject
        }

        var components = filePath.components
        components.removeLast()
        let groupPath = Path(components: components)
        guard let group = try addGroupsIfNeeded(for: project, path: groupPath) else {
            throw Error.noGroup
        }

        let fullPath = path + filePath
        let file = try group.addFile(at: fullPath, sourceTree: .sourceRoot, sourceRoot: path)
        xcodeproj.pbxproj.add(object: file)
        let _ = try xcodeproj.pbxproj.sourcesBuildPhases[0].add(file: file)
        try xcodeproj.write(path: xcodeprojPath)
    }

    // MARK: - Private

    private func addGroupsIfNeeded(for project: PBXProject, path: Path) throws -> PBXGroup? {
        var currentGroup = project.mainGroup

        for path in path.components {
            if let group = currentGroup?.group(withPath: path) {
                currentGroup = group
            }
            else {
                currentGroup = try currentGroup?.addGroup(named: path).first
            }
        }
        return currentGroup
    }
}
