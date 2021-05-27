//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import PathKit
import Foundation

public final class UpgradeServiceImpl: UpgradeService {

    public enum Error: Swift.Error, CustomStringConvertible {
        case build
        case copyBinary

        public var description: String {
            switch self {
            case .build:
                return "Could not build app from source code"
            case .copyBinary:
                return "Could not copy updeted binary to system location"
            }
        }
    }

    public typealias Dependencies = HasGithubService & HasShell & HasConfigFactory

    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func upgrade(to version: UpgradeVersion, customizationHandler: (() throws -> Void)?) throws {
        try cloneGeneralIfNeeded(version: version)
        try customizationHandler?()
        try buildGeneral()
    }

    public func fetchConcreteVersion(from version: UpgradeVersion) -> String {
        switch version {
        case let .concrete(version):
            return version
        case .latest:
            return Constants.defaultGithubBranch
        case .current:
            return dependencies.configFactory.shared?.version ?? Constants.defaultGithubBranch
        }
    }

    // MARK: - Private

    private func cloneGeneralIfNeeded(version: UpgradeVersion) throws {
        let version = fetchConcreteVersion(from: version)
        let repo = Constants.githubRepo
        let destination = Constants.downloadedSourcePath
        try dependencies.githubService.downloadFiles(at: "\(repo) \(version)", to: destination)
    }

    private func buildGeneral() throws {
        try dependencies.shell(loud: "cd \(Constants.downloadedSourcePath) && make install")
    }
}
