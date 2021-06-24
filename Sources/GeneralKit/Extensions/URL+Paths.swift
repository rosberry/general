//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public func + (url: URL, pathComponent: String) -> URL {
    return url.appendingPathComponent(pathComponent)
}

extension URL {
    public static func tempFolderWithRandomName() throws -> URL {
        let folderName = "\(Constants.generalTmpFolderPrefix).\(UUID().uuidString)"
        let url = URL(fileURLWithPath: Constants.tmpFolderPath) + folderName
        try Services.fileHelper.createDirectory(at: url)
        return url
    }
}
