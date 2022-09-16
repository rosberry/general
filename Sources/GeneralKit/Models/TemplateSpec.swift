//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public struct TemplateSpec: Codable, CustomStringConvertible {
    public let files: [File]
    public let mark: String?
    public let suffix: String?

    public init(files: [File], mark: String? = nil, suffix: String? = nil) {
        self.files = files
        self.suffix = suffix
        self.mark = mark
    }
}
