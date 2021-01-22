//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import ArgumentParser

final class General: ParsableCommand {

    static let configuration: CommandConfiguration = .init(abstract: "Generates code from templates.",
                                                           version: "0.3",
                                                           subcommands: [Generate.self,
                                                                         Create.self,
                                                                         Spec.self,
                                                                         List.self,
                                                                         Setup.self],
                                                           defaultSubcommand: Generate.self)
}
