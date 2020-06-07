//
//  Created by Artem Novichkov on 07.06.2020.
//

import Foundation

func +(url: URL, pathComponent: String) -> URL {
    return url.appendingPathComponent(pathComponent)
}
