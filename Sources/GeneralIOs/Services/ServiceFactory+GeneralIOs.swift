//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

extension ServiceFactory: HasProjectServiceFactory {
    public var projectServiceFactory: ProjectServiceFactory {
        .init()
    }
}
