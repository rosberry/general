//
//  Copyright © 2021 Rosberry. All rights reserved.
//

import Foundation

public class FontSpec: Codable, CustomStringConvertible {
    public var extensionFolderPath: String
    public var extensionFontPath: String
    public var commonTemplatePath: String
    public var commandTemplatePath: String
    public var fontsFolderPath: String
    public var fontsTemplatePath: String
    public var infoFontName: String
    public var fontTemplateName: String

    public init(extensionFolderPath: String,
                extensionFontPath: String,
                commonTemplatePath: String,
                commandTemplatePath: String,
                fontsFolderPath: String,
                fontsTemplatePath: String,
                infoFontName: String,
                fontTemplateName: String,
                notFoundTemplate: String) {
        self.extensionFolderPath = extensionFolderPath
        self.extensionFontPath = extensionFontPath
        self.commonTemplatePath = commonTemplatePath
        self.commandTemplatePath = commandTemplatePath
        self.fontsFolderPath = fontsFolderPath
        self.fontsTemplatePath = fontsTemplatePath
        self.infoFontName = infoFontName
        self.fontTemplateName = fontTemplateName
    }
}
