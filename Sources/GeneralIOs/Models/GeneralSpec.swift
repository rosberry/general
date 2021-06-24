//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

struct GeneralSpec: Codable {
    public var xcode: XcodeSpec
    public var outputs: [Output]

    public init(xcode: XcodeSpec, outputs: [Output] = []) {
        self.xcode = xcode
        self.outputs = outputs
    }

    public func output(forTemplateName templateName: String) -> Output? {
        outputs.first { output in
            output.templateName == templateName
        }
    }
}
