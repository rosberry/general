//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

struct GeneralSpec: Codable, CustomStringConvertible {

    var xcodeproj: XcodeprojSpec?
    let outputs: [Output]

    init(xcodeproj: XcodeprojSpec?, outputs: [Output] = []) {
        self.xcodeproj = xcodeproj
        self.outputs = outputs
    }

    func output(forTemplateName templateName: String) -> Output? {
        outputs.first { output in
            output.templateName == templateName
        }
    }
}
