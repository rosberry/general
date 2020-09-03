//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct GeneralSpec: Codable, CustomStringConvertible {

    var project: String?
    var target: String?
    var testTarget: String?
    var company: String?
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
