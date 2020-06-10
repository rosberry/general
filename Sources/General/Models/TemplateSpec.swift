//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct TemplateSpec: Codable, CustomStringConvertible {

    let files: [File]
    let testFiles: [File]?
}
