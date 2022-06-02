//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public struct TemplateSpec: Codable, CustomStringConvertible {
    public let files: [File]
    public let marked: String?
    public let suffix: String?

    public init(files: [File], marked: String? = nil, suffix: String? = nil) {
        self.files = files
        self.suffix = suffix
        self.marked = marked
    }
}
