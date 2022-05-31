//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import GeneralKit

extension ServiceFactory: HasProjectServiceFactory, HasBootstrapService {
    public var projectServiceFactory: ProjectServiceFactory {
        .init()
    }

    public var bootstrapService: BootstrapService {
        BootstrapServiceImpl(dependencies: self)
    }
}
