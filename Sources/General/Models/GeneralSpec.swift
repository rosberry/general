//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct GeneralSpec: Codable {

    let project: String?
    let target: String? = nil
    let company: String?
    let outputs: [Output] = []

    func path(forTemplateName templateName: String) -> String? {
        var path: String?
        for output in outputs where output.templateName == templateName {
            path = output.path
        }
        return path
    }
}
