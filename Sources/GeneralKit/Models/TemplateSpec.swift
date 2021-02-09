//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public struct TemplateSpec: Codable, CustomStringConvertible {
    let files: [File]
    let suffix: String?
}
