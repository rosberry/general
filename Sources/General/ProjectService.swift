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

    func addFile(path: Path, projectName: String, templatePath: Path, filename: String) throws {
        let xcodeprojPath = path + Path(projectName)
        let xcodeproj = try XcodeProj(path: xcodeprojPath)
        guard let project = xcodeproj.pbxproj.projects.first else {
            throw Error.noProject
        }

        guard let group = try addGroupsIfNeeded(for: project, path: templatePath) else {
            throw Error.noGroup
        }

        let filePath = path + templatePath + Path(filename)
        let file = try group.addFile(at: filePath, sourceTree: .sourceRoot, sourceRoot: path)
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
