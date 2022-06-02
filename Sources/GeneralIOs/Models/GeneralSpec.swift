//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

struct GeneralSpec: Codable {
    public var xcode: XcodeSpec
    public var font: FontSpec
    public var services: ServicesSpec
    public var outputs: [Output]

    public init(xcode: XcodeSpec, font: FontSpec, services: ServicesSpec, outputs: [Output] = []) {
        self.font = font
        self.xcode = xcode
        self.services = services
        self.outputs = outputs
    }

    public func output(forTemplateName templateName: String) -> Output? {
        outputs.first { output in
            output.templateName == templateName
        }
    }
}

struct ServicesSpec: Codable, CustomStringConvertible {
    public let serviceMark: String
    public let serviceMarkName: String

    public init(serviceMark: String, serviceMarkName: String) {
        self.serviceMark = serviceMark
        self.serviceMarkName = serviceMarkName
    }
}
