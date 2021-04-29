//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser
import Foundation
import GeneralKit
import GeneralIOs
// {% PluginImport %}


final class General: ParsableCommand {

    enum CodingKeys: CodingKey {
         case template
         case dynamic(String)

         init?(stringValue: String) {
             switch stringValue {
             case "template":
                 self = .template
             case stringValue where General.attributes.contains(stringValue):
                 self = .dynamic(stringValue)
             default:
                 return nil
             }
         }

         var stringValue: String {
             switch self {
             case .template:
                 return "template"
             case let .dynamic(name):
                 return name
             }
         }

         // Not used
         var intValue: Int? { nil }
         init?(intValue _: Int) { nil }
    }

    @Argument()
    var template: String

    static var attributes: [String] = []

    static func preprocess(_ arguments: [String]) throws {
        let templateName = arguments[1]
        // TODO: Load arguments for template name
        let attributes: [String] = ["argument", "second_argument"]
        General.attributes = attributes
    }

    static var configuration: CommandConfiguration = .init(commandName: "general", abstract: "Generates modules from templates.")

    var attributes: [String: String] = [:]

    init() {

    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        template = try container.decode(String.self, forKey: .template)
        try General.attributes.forEach { name in
            attributes[name] = try container.decode(String.self, forKey: .dynamic(name))
        }
    }

    func run() throws {
        print(template)
        print(attributes)
    }
}

extension General: CustomReflectable {
    var customMirror: Mirror {
        let attributesChildren: [Mirror.Child] = General.attributes.map { name in
            let option = Option<String>(name: .shortAndLong)
            let child = Mirror.Child(label: name, value: option)
            return child
        }
        let children = [
            Mirror.Child(label: "template", value: _template)
        ]
        return Mirror(General(), children: children + attributesChildren)
    }
}
