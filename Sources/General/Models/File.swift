//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import PathKit

struct File: Codable, CustomStringConvertible {
    let template: String
    let name: String?
    let output: String?
    let folder: String?
}

extension File {
    func fileName(in module: String) -> String {
        if let name = self.name {
            return name
        }
        if let output = self.output {
            return Path(output).lastComponent
        }
        var relativeFileURL = URL(fileURLWithPath: template)
        if relativeFileURL.pathExtension == "stencil" {
            relativeFileURL.deletePathExtension()
        }
        return module + relativeFileURL.lastPathComponent
    }
}
