//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public struct Help {
    let overview: String
    let usage: String
    let arguments: [HelpArgument]
    let options: [HelpOption]
    let subcommands: [Help]
}
