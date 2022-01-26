//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

let version = "0.5.1"
Services.configFactory.default = .init(version: version)
try Services.pluginService.main(command: General.self)
