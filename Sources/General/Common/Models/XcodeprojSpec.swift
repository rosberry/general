//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public struct XcodeprojSpec: Codable, CustomStringConvertible {

    var project: String?
    var target: String?
    var testTarget: String?
    var company: String?

    init(project: String?, target: String?, testTarget: String?, company: String?) {
        self.project = project
        self.target = target
        self.testTarget = testTarget
        self.company = company
    }
}
