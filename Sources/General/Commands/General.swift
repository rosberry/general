//
//  Created by Artem Novichkov on 05.06.2020.
//

import ArgumentParser

final class General: ParsableCommand {

    static let configuration: CommandConfiguration = .init(abstract: "Generates code from templates.",
                                                           subcommands: [Generate.self, Create.self, Spec.self])
}