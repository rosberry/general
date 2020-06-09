//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct GeneralSpec: Codable, CustomStringConvertible {

    let project: String?
    let target: String?
    let company: String?
    let outputs: [Output]

    init(project: String?, target: String? = nil, company: String?, outputs: [Output] = []) {
        self.project = project
        self.target = target
        self.company = company
        self.outputs = outputs
    }

    func path(forTemplateName templateName: String) -> String? {
        var path: String?
        for output in outputs where output.templateName == templateName {
            path = output.path
        }
        return path
    }
}
