//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import PathKit
import XcodeProj

final class ProjectService {

    enum Error: Swift.Error {
        case noProject(path: String)
        case noGroup
    }

    var path: Path

    private var xcodeprojPath: Path?
    private var xcodeproj: XcodeProj?

    init(path: Path) {
        self.path = path
    }

    func createProject(projectName: String) throws {
        let xcodeprojPath = path + Path(projectName)
        xcodeproj = try XcodeProj(path: xcodeprojPath)
        self.xcodeprojPath = xcodeprojPath
    }

    func addFile(targetName: String?, isTestTarget: Bool, filePath: Path) throws {
        guard let project = xcodeproj?.pbxproj.projects.first else {
            throw Error.noProject(path: path.string)
        }

        var components = filePath.components
        components.removeLast()
        let groupPath = Path(components: components)
        guard let group = try addGroupsIfNeeded(for: project, path: groupPath) else {
            throw Error.noGroup
        }

        let fullPath = path + filePath
        let file = try group.addFile(at: fullPath, sourceTree: .sourceRoot, sourceRoot: path)
        xcodeproj?.pbxproj.add(object: file)
        let targets = xcodeproj?.pbxproj.nativeTargets
        let target: PBXNativeTarget?
        if let name = targetName {
            target = targets?.first { target in
                target.name == name
            }
        }
        else {
            let productType: PBXProductType = isTestTarget ? .unitTestBundle : .application
            target = targets?.first { target in
                target.productType == productType
            }
        }
        let buildPhase = target?.buildPhases.first { buildPhase in
            buildPhase.buildPhase == .sources
        }
        _ = try buildPhase?.add(file: file)
    }

    func readAttributes() throws -> [String: Any] {
        guard let rootProject = try xcodeproj?.pbxproj.rootProject() else {
            return [:]
        }
        return rootProject.attributes
    }

    func write() throws {
        guard let xcodeprojPath = xcodeprojPath else {
            return
        }
        try xcodeproj?.write(path: xcodeprojPath)
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

extension ProjectService.Error: CustomStringConvertible {

    var description: String {
        switch self {
            case .noProject(let path):
                return "There is no pbxproj at " + path
            case .noGroup:
                return "Fail to add groups to Xcode project."
        }
    }
}
