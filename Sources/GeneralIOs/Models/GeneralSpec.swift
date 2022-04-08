//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

struct GeneralSpec: Codable {
    public var xcode: XcodeSpec
    public var font: FontSpec
    public var outputs: [Output]

    public init(xcode: XcodeSpec, font: FontSpec, outputs: [Output] = []) {
        self.font = font
        self.xcode = xcode
        self.outputs = outputs
    }

    public func output(forTemplateName templateName: String) -> Output? {
        outputs.first { output in
            output.templateName == templateName
        }
    }
}
