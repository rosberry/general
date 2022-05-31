//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

extension ServiceFactory: HasProjectServiceFactory, HasBootstrapService, HasFontServiceFactory {
    public var projectServiceFactory: ProjectServiceFactory {
        .init()
    }

    public var bootstrapService: BootstrapService {
        BootstrapServiceImpl(dependencies: self)
    }

    public var fontServiceFactory: FontServiceFactory {
        .init()
    }
}
