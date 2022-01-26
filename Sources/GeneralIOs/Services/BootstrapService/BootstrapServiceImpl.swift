//
//  Copyright © 2021 Rosberry. All rights reserved.
//
import UmalerKit
import GeneralKit
import Stencil
import Foundation

public final class BootstrapServiceImpl: BootstrapService {

    private lazy var configPath: String = "\(Constants.generalHomePath)/.bootstrap"

    typealias Dependencies = HasFileHelper & HasProjectServiceFactory & HasShell

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
        if config.diagrams != nil {
            let bootsraper = UMLBootstraper(dependencies: dependencies)
            try bootsraper.bootstrap(with: config)
        }
        else {
            try bootstrapProject(with: config)
        }
    }

    private func bootstrapProject(with config: BootstrapConfig) throws {
        var arguments = ["--no-input", config.template]
        arguments.append(contentsOf: config.context.map { key, value in
            "\(key)=\(value)"
        })
        try dependencies.shell(path: "/usr/local/bin/cookiecutter", arguments: arguments)
    }
}
