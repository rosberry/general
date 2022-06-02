//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

public func askProject() -> String? {
    let defaultValue = try? ProjectService.findProject()?.url.lastPathComponent
    return ask("Enter project name", default: defaultValue)
}

public func askCompany() -> String? {
    return ask("Enter company name", default: "Rosberry")
}
