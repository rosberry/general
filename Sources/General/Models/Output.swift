//
//  Copyright © 2020 Rosberry. All rights reserved.
//
import Foundation

struct Output: Codable, CustomStringConvertible {

    let templateName: String
    let path: String
    let testPath: String?
}
