//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct FileInfo: Hashable {
    let url: URL
    let isDirectory: Bool
    let isExists: Bool
    let contentModificationDate: Date?
}
