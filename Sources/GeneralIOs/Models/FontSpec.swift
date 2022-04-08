//
//  Created by Evgeny Schwarzkopf on 08.04.2022.
//

import Foundation

public class FontSpec: Codable, CustomStringConvertible {
    public var extensionFolderPath: String
    public var extensionFontPath: String
    public var commonTemplatePath: String
    public var commandTemplatePath: String
    public var fontsFolderPath: String
    public var fontsTemplatePath: String
    public var fontValue: String
    public var fontTemplateName: String

    public init(extensionFolderPath: String,
                extensionFontPath: String,
                commonTemplatePath: String,
                commandTemplatePath: String,
                fontsFolderPath: String,
                fontsTemplatePath: String,
                fontValue: String,
                fontTemplateName: String,
                notFoundTemplate: String) {
        self.extensionFolderPath = extensionFolderPath
        self.extensionFontPath = extensionFontPath
        self.commonTemplatePath = commonTemplatePath
        self.commandTemplatePath = commandTemplatePath
        self.fontsFolderPath = fontsFolderPath
        self.fontsTemplatePath = fontsTemplatePath
        self.fontValue = fontValue
        self.fontTemplateName = fontTemplateName
    }
}
