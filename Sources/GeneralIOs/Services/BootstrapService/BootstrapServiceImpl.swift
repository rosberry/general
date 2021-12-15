//
//  Copyright © 2021 Rosberry. All rights reserved.
//
import UmalerKit
import GeneralKit
import Stencil
import Foundation

public final class BootstrapServiceImpl: BootstrapService {

    private lazy var configPath: String = "\(Constants.generalHomePath)/.bootstrap"

    typealias Dependencies = HasFileHelper

    private var dependencies: Dependencies

    public var config: [String : Any] {
        get {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
                  let config = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                return [:]
            }
            return config
        }
        set {
            guard let data = try? JSONSerialization.data(withJSONObject: newValue, options: .fragmentsAllowed) else {
                return
            }
            try? data.write(to: URL(fileURLWithPath: configPath))
        }
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    

    public func bootstrap(with config: BootstrapConfig) throws {
        let bootsraper = UMLBootstraper(dependencies: dependencies)
        try bootsraper.bootstrap(with: config)
    }
}
