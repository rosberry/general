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
    public let servicesPath: String
    public let serviceMarks: [String: String]

    public init(servicesPath: String, serviceMarks: [String: String]) {
        self.servicesPath = servicesPath
        self.serviceMarks = serviceMarks
    }
}
