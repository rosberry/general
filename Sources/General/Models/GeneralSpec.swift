//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct GeneralSpec: Codable, CustomStringConvertible {

    let project: String?
    let target: String?
    let testTarget: String?
    let company: String?
    let outputs: [Output]

    init(project: String?, target: String? = nil, testTarget: String? = nil, company: String?, outputs: [Output] = []) {
        self.project = project
        self.target = target
        self.testTarget = testTarget
        self.company = company
        self.outputs = outputs
    }

    func output(forTemplateName templateName: String) -> Output? {
        outputs.first { output in
            output.templateName == templateName
        }
    }
}
