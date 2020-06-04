//
//  Created by Artem Novichkov on 04.06.2020.
//

import Foundation
import ArgumentParser
import Stencil
import Yams
import xcodeproj
import PathKit

struct File: Decodable {

    let template: String
    let name: String?
}

struct Spec: Decodable {

    let files: [File]
}

final class ModuleGen: ParsableCommand {

    static let configuration: CommandConfiguration = .init(abstract: "Generates modules from templates.")

    @Option(name: [.short, .long], help: "The name of the module.")
    var name: String

    @Option(name: [.short, .long], help: "The name of the template.")
    var template: String

    @Option(name: [.short, .long], default: FileManager.default.currentDirectoryPath, help: "The name of the template.")
    var output: String

    private var context: [String: Any] {
        ["name": name]
    }

    func run() throws {
        let templatesURL = URL(fileURLWithPath: "/Users/artemnovichkov/.templates")
        let commonTemplatesURL = templatesURL.appendingPathComponent("common")
        let templateURL = templatesURL.appendingPathComponent(template)
        let specURL = templateURL.appendingPathComponent("spec.yml")
        let specString = try String(contentsOf: specURL)
        let decoder = YAMLDecoder()
        let spec = try decoder.decode(Spec.self, from: specString)
        let outputURL = URL(fileURLWithPath: output)
        for file in spec.files {
            let codeURL = templateURL.appendingPathComponent("Code")
            let environment = Environment(loader: FileSystemLoader(paths: [.init(codeURL.path),
                                                                           .init(commonTemplatesURL.path)]))
            let rendered = try environment.renderTemplate(name: file.template, context: context)
            let fileName = file.name ?? file.template.removingStencilExtension
            let fileURL = outputURL.appendingPathComponent(fileName)
            try rendered.write(to: fileURL, atomically: true, encoding: .utf8)
            print(rendered)

            let path = Path("/Users/artemnovichkov/Library/Developer/Xcode/DerivedData/ModuleGen-erkdnzflxbigfxbnxzsjrihxxpxj/Build/Products/Debug/Module/Module.xcodeproj")
            let xcodeproj = try XcodeProj(path: path)
            let project = xcodeproj.pbxproj.projects.first!
            let mainGroup = project.mainGroup
            try mainGroup?.addGroup(named: "MyGroup")
            try xcodeproj.write(path: path)
        }
    }
}

extension String {

    var removingStencilExtension: String {
        replacingOccurrences(of: ".stencil", with: "")
    }
}
