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
        let bootsraper = UMLBootstraper(dependencies: dependencies)
        try bootsraper.bootstrap(with: config)
        try depo(with: config)
        swiftgen(with: config)
    }

    private func depo(with config: BootstrapConfig) throws {
        guard isInstalled(tool: "depo"),
              isExists(path: "\(config.name)/Depofile") else {
            return
        }
        let shell = dependencies.shell
        try shell(loud: "(cd \(config.name) && depo install)")
    }

    private func swiftgen(with config: BootstrapConfig) {
        guard isInstalled(tool: "swiftgen") else {
            return
        }
        let shell = dependencies.shell
        _ = try? shell(loud: "(cd \(config.name) && swiftgen)")
    }

    private func isExists(path: String) -> Bool{
        return dependencies.fileHelper.fileManager.fileExists(atPath: path)
    }

    private func isInstalled(tool: String) -> Bool {
        guard let path = try? dependencies.shell(silent: "command -v \(tool)"),
              path.isEmpty == false else {
            return false
        }
        return true
    }
}
