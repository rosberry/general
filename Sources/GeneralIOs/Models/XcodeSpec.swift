//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public struct XcodeSpec: Codable {
    public let name: String?
    public let target: String?
    public let company: String?

    public init(name: String? = nil, target: String? = nil, company: String? = nil) {
        self.name = name
        self.target = target
        self.company = company
    }
}
