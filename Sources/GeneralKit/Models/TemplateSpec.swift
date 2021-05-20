//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public struct TemplateSpec: Codable, CustomStringConvertible {
    public let files: [File]
    public let suffix: String?

    public init(files: [File], suffix: String? = nil) {
        self.files = files
        self.suffix = suffix
    }
}
