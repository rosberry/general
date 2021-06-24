//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public struct FileInfo: Hashable {
    public let url: URL
    public let isDirectory: Bool
    public let isExists: Bool
    public let contentModificationDate: Date?
}
