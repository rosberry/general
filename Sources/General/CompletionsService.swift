//
// Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import XcodeProj
import ArgumentParser

final class CompletionsService {

    static func templates() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: "./\(Constants.templatesFolderName)")) ?? []
    }

    static func targets() -> [String] {
        (try? XcodeProj(path: "./General.xcodeproj").pbxproj.nativeTargets.map { $0.name }) ?? []
    }
}

extension CompletionKind {
    static var templates: CompletionKind {
        .custom { _ in
            CompletionsService.templates()
        }
    }
    
    static var targets: CompletionKind {
        .custom { _ in
            CompletionsService.targets()
        }
    }
}
