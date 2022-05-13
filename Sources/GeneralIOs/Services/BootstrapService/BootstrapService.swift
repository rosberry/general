//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public protocol HasBootstrapService: AnyObject {
    var bootstrapService: BootstrapService { get }
}

public protocol BootstrapService: AnyObject {
    var config: [String: Any] { get set }
    func bootstrap(with config: BootstrapConfig) throws
}
