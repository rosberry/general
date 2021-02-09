//
//  Copyright © 2021 Rosberry. All rights reserved.
//


public struct Plugin: Codable, Equatable, CustomStringConvertible {
    let name: String
    public let description: String
    let repo: String
    let files: [String]
    let dependencies: [String]
}
