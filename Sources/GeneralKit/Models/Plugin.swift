//
//  Copyright © 2021 Rosberry. All rights reserved.
//


public struct Plugin: Codable, Equatable, CustomStringConvertible {
    public let name: String
    public let repo: String
    public let package: String


    public init(name: String, repo: String, package: String) {
        self.name = name
        self.repo = repo
        self.package = package
    }
}
