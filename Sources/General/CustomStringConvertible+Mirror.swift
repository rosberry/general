//
//  Copyright © 2020 Rosberry. All rights reserved.
//

extension CustomStringConvertible {

    var description: String {
        var description = "\(type(of: self))\n"
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let label = child.label {
                description += "\t\(label): \(child.value)\n"
            }
        }
        return description
    }
}
