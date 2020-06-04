//
//  Created by Artem Novichkov on 04.06.2020.
//

import Foundation
import ArgumentParser
import Stencil

final class ModuleGen: ParsableCommand {

    static let configuration: CommandConfiguration = .init(abstract: "Generates modules from templates.")

    @Option(name: [.short, .long], help: "The name of the module.")
    var name: String

    private var context: [String: Any] {
        ["name": name]
    }

    func run() throws {
        let url = URL(fileURLWithPath: "/Users/artemnovichkov/Documents/Projects/ModuleGen/templates/Controller.swift")
        let environment = Environment(loader: FileSystemLoader(paths: ["/Users/artemnovichkov/Documents/Projects/ModuleGen/templates/"]))
        let rendered = try environment.renderTemplate(name: "template.stencil", context: context)
        try rendered.write(to: url, atomically: true, encoding: .utf8)
        print(rendered)
    }
}
