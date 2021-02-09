//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import XcodeProj

public extension PBXGroup {

    func group(withPath path: String) -> PBXGroup? {
        children.first { element in
            element.path == path
        } as? PBXGroup
    }
}
