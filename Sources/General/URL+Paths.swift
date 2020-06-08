//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

func + (url: URL, pathComponent: String) -> URL {
    return url.appendingPathComponent(pathComponent)
}
