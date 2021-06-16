//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import ArgumentParser

public protocol HasPluginService {
    var pluginService: PluginService { get }
}

public protocol PluginService {
    func main(command: ParsableCommand.Type) throws
}
