//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation
import PathKit

public protocol HasProjectServiceFactory {
    var projectServiceFactory: ProjectServiceFactory { get }
}

public class ProjectServiceFactory {
    func makeProjectService(path: Path) -> ProjectService {
        return .init(path: path)
    }
}
