//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

extension ServiceFactory: HasProjectServiceFactory, HasFontServiceFactory {
    public var projectServiceFactory: ProjectServiceFactory {
        .init()
    }

    public var fontServiceFactory: FontServiceFactory {
        .init()
    }
}
