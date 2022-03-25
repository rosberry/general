//
//  Bootstrap.swift
//  GeneralIOs
//
//  Created by Nick Tyunin on 15.10.2021.
//

import Foundation
import ArgumentParser
import Files
import UmalerKit
import GeneralKit
import Stencil

final class Bootstrap: ParsableCommand {
    static let configuration: CommandConfiguration = .init(abstract: "Allows to generate project from plant uml definition",
                                                           subcommands: [Make.self, Config.self],
                                                           defaultSubcommand: Make.self)

    enum Error: Swift.Error {
        case template
        case bundleId
        case github

        var description: String {
            switch self {
            case .template:
                return "No template path was specified. Please use `--template` option or specify it in reusable config " +
                       "with `bootsrap config update --template`"
            case .bundleId:
                return "No bundle id was specified. Please use --bundle_id option or provide company name using --company. " +
                       "You also can specify company in reusable config using `bootsrap config update --company`"
            case .github:
                return "Templates repo was not specified"
            }
        }
    }

    final class Config: ParsableCommand {

        enum Constants {
            static let template: String = "template"
            static let company: String = "company"
            static let firebase: String = "firebase"
            static let swiftgen: String = "swiftgen"
            static let licenseplist: String = "licenseplist"
        }

        static let configuration: CommandConfiguration = .init(abstract: "Allows read or modify reusable bootstrap config",
                                                               subcommands: [UpdateConfig.self, PrintConfig.self],
                                                               defaultSubcommand: UpdateConfig.self)


    }

    final class UpdateConfig: ParsableCommand {

        public typealias Dependencies = HasBootstrapService
        static let configuration: CommandConfiguration = .init(commandName: "update", abstract: "Allows to modify reusable bootstrap config")

        @Option(name: .shortAndLong, help: "The path to the project template", completion: .directory)
        var template: String?

        @Option(name: .shortAndLong, help: "The bundle identifier of new project")
        var company: String?

        @Option(name: .shortAndLong, help: "Enable or disable firebase")
        var firebase: Bool?

        @Option(name: .shortAndLong, help: "Enable or disable firebase")
        var swiftgen: Bool?

        @Option(name: .shortAndLong, help: "Enable or disable licenseplist")
        var licenseplist: Bool?

        @Option(name: .shortAndLong, help: "Set additional variable value. Format name=value ")
        var variable: String?

        var dependencies: Dependencies {
            Services
        }

        func run() throws {
            var config = dependencies.bootstrapService.config
            if let template = self.template {
                config[Config.Constants.template] = template
            }
            if let company = self.company {
                config[Config.Constants.company] = company
            }
            if let firebase = self.firebase {
                config[Config.Constants.firebase] = firebase
            }
            if let swiftgen = self.swiftgen {
                config[Config.Constants.swiftgen] = swiftgen
            }
            if let licenseplist = self.licenseplist {
                config[Config.Constants.licenseplist] = licenseplist
            }
            if let variable = self.variable {
                let components = variable.split(separator: "=").map { component in
                    String(component.trimmingCharacters(in: .whitespaces))
                }
                guard components.count == 2 else {
                    print(yellow("Invalid variable format provided: `\(variable)`. Missing `name=value`"))
                    return
                }
                let name = components[0]
                let value = components[1]
                config[name] = value
            }
            dependencies.bootstrapService.config = config
        }

    }

    final class PrintConfig: ParsableCommand {
        public typealias Dependencies = HasBootstrapService
        static let configuration: CommandConfiguration = .init(commandName: "print", abstract: "Displays reusable bootstrap config")

        var dependencies: Dependencies {
            Services
        }

        func run() throws {
            let config = dependencies.bootstrapService.config
            guard let data = try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted),
                  let string = String(data: data, encoding: .utf8) else {
                print(red("Could not parse stored config"))
                return
            }
            print(green(string))
        }
    }
    
    final class Make: ParsableCommand {
        public typealias Dependencies = HasBootstrapService

        static let configuration: CommandConfiguration = .init(abstract: "Generate project from plant uml definition")

        @Option(name: .shortAndLong, help: "The name of new project")
        var name: String

        @Option(name: .shortAndLong, help: "The path to uml diagrams file")
        var uml: String?

        @Option(name: .shortAndLong, help: "The path to the project template", completion: .directory)
        var template: String?

        @Option(name: .shortAndLong, help: "The bundle identifier of new project. If not specified will be composed using company and name values: `com.company.name`")
        var bundleId: String?

        @Option(name: .shortAndLong, help: "The bundle identifier of new project")
        var company: String?

        @Option(name: .shortAndLong, help: "Enable or disable firebase")
        var firebase: Bool?

        @Option(name: .shortAndLong, help: "Enable or disable swiftgen")
        var swiftgen: Bool?

        @Option(name: .shortAndLong, help: "Enable or disable licenseplist")
        var licenseplist: Bool?

    //    @Option(name: .shortAndLong, help: "Path to plant uml file", completion: .directory)
    //    var uml: String

        @Option(name: [.customLong("repo"), .customShort("r")],
                help: .init(stringLiteral:
                    "Fetch templates from specified github repo." +
                    " Format: \"<github>\\ [branch]\"."),
                completion: .templatesRepos)
        var githubPath: String?

        var dependencies: Dependencies {
            Services
        }

        func run() throws {
            let config = uml != nil ? try composeUMLConfig() : try composeProjectConfig()
            try dependencies.bootstrapService.bootstrap(with: config)
        }

        private func composeUMLConfig() throws -> BootstrapConfig {
            var projectConfig = dependencies.bootstrapService.config
            guard let template = self.template ?? projectConfig[Config.Constants.template] as? String else {
                throw Error.template
            }
            projectConfig.removeValue(forKey: Config.Constants.template)
            if let company = self.company {
                projectConfig[Config.Constants.company] = company
            }
            if let firebase = self.firebase {
                projectConfig[Config.Constants.company] = firebase
            }
            if let swiftgen = self.swiftgen {
                projectConfig[Config.Constants.swiftgen] = swiftgen
            }
            if let licenseplist = self.licenseplist {
                projectConfig[Config.Constants.licenseplist] = licenseplist
            }
            projectConfig["name"] = name
            projectConfig["year"] = "\(Calendar.current.component(.year, from: Date()))"
            if let bundleId = self.bundleId {
                projectConfig["bundle_identifier"] = bundleId
            } else if let company = self.company ?? projectConfig[Config.Constants.company] as? String {
                projectConfig["bundle_identifier"] = "com.\(company).\(name)".lowercased()
            } else {
                throw Error.bundleId
            }
            var context = [String: Any]()
            context["project"] = projectConfig
            return .init(name: name, context: context, template: template, diagrams: uml)
        }

        private func composeProjectConfig() throws -> BootstrapConfig {
            var projectConfig = dependencies.bootstrapService.config
            guard let template = self.template ?? projectConfig[Config.Constants.template] as? String else {
                throw Error.template
            }
            projectConfig.removeValue(forKey: Config.Constants.template)
            if let company = self.company ?? projectConfig[Config.Constants.company] as? String {
                projectConfig["organization_name"] = company
            }
            if let firebase = self.firebase ?? projectConfig[Config.Constants.firebase] as? Bool {
                projectConfig[Config.Constants.firebase] = firebase ? "Yes" : "No"
            }
            if let swiftgen = self.swiftgen ?? projectConfig[Config.Constants.swiftgen] as? Bool {
                projectConfig[Config.Constants.swiftgen] = swiftgen ? "Yes" : "No"
            }
            if let licenseplist = self.licenseplist ?? projectConfig[Config.Constants.licenseplist] as? Bool {
                projectConfig[Config.Constants.licenseplist] = licenseplist ? "Yes" : "No"
            }
            projectConfig["name"] = name
            if let bundleId = self.bundleId {
                projectConfig["bundle_identifier"] = bundleId
            } else if let company = self.company ?? projectConfig[Config.Constants.company] as? String {
                projectConfig["bundle_identifier"] = "com.\(company).\(name)".lowercased()
            } else {
                throw Error.bundleId
            }
            return .init(name: name, context: projectConfig, template: template, diagrams: nil)
        }
    }
}
