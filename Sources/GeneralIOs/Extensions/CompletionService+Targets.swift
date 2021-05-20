//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit
import XcodeProj
import ArgumentParser

public extension CompletionsService {
    func targets() -> [String] {
        guard let projectPath = try? ProjectService.findProject() else {
            return []
        }
        return (try? XcodeProj(path: projectPath).pbxproj.nativeTargets.map { $0.name }) ?? []
    }
}

public extension CompletionKind {
    static var targets: CompletionKind {
        .custom { _ in
            dependencies.completionsService.targets()
        }
    }
}
