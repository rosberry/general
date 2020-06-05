//
//  Created by Artem Novichkov on 05.06.2020.
//

import ArgumentParser

final class ModuleGen: ParsableCommand {

    static let configuration: CommandConfiguration = .init(abstract: "Generates modules from templates.",
                                                           subcommands: [Generate.self, Create.self])
}
