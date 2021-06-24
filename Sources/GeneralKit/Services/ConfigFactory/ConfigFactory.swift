//
//  Copyright © 2021 Rosberry. All rights reserved.
//

public protocol HasConfigFactory {
    var configFactory: ConfigFactory { get }
}

public protocol ConfigFactory {
    var `default`: GeneralConfig? { get set }
    var shared: GeneralConfig? { get }
    func update( _ handler: (GeneralConfig) throws -> GeneralConfig) throws
}
