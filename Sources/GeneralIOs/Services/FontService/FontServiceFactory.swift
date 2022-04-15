//
//  Created by Evgeny Schwarzkopf on 08.04.2022.
//

import Foundation
import PathKit

public protocol HasFontServiceFactory {
    var fontServiceFactory: FontServiceFactory { get }
}

public class FontServiceFactory {
    func makeFontService( directoryPath: String) -> FontService {
        return .init(directoryPath: directoryPath)
    }
}

