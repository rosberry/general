//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public struct GeneralSpec: Codable, CustomStringConvertible {
    public let outputs: [Output]

    public init(outputs: [Output] = []) {
        self.outputs = outputs
    }

    public func output(forTemplateName templateName: String) -> Output? {
        outputs.first { output in
            output.templateName == templateName
        }
    }
}
