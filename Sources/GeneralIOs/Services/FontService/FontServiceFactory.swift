//
//  Copyright © 2021 Rosberry. All rights reserved.
//


import Foundation
import PathKit

public protocol HasFontServiceFactory {
    var fontServiceFactory: FontServiceFactory { get }
}

public class FontServiceFactory {
    func makeFontService(directoryPath: String) -> FontService {
        return .init(directoryPath: directoryPath)
    }
}
