//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import PathKit

public struct File: Codable, CustomStringConvertible {
    public let template: String
    public let name: String?
    public let output: String?
    public let folder: String?

    public init(template: String, name: String? = nil, output: String? = nil, folder: String? = nil) {
        self.template = template
        self.name = name
        self.output = output
        self.folder = folder
    }
}

public extension File {
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
