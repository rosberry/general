//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

func tempFolderWithRandomName() throws -> URL {
    let folderName = "\(Constants.generalTmpFolderPrefix).\(UUID().uuidString)"
    let url = URL(fileURLWithPath: Constants.tmpFolderPath) + folderName
    try FileHelper.default.createDirectory(at: url)
    return url
}

