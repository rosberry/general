//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public enum Constants {
    static let version = "3.0"
    static let shell = "/bin/bash"
    static let generalHomePath = "\(NSHomeDirectory())/.general"
    static let configPath = "\(generalHomePath)/.config"
    static let pluginsPath = "\(generalHomePath)//plugins"
    static let downloadedSourcePath = "\(generalHomePath)/source"
    static let specFilename = "spec.yml"
    static let templatesFolderName = ".templates"
    static let commonTemplatesFolderName = "common"
    static let filesFolderName = "Code"
    static let templateFilename = "template.stencil"
    static let template = "{{ name }}"
    static let projectName = "Project.xcodeproj"
    static let generalSpecName = ".general.yml"
    static let appFolderName = ".general"
    static let stencilPathExtension = "stencil"
    static let xcodeProjectPathExtension = "xcodeproj"
    static let relativeCurrentPath = "./"
    static let tmpFolderPath = "/tmp"
    static let generalTmpFolderPrefix = "general"
    static let defaultGithubBranch = "master"
    static let githubRepo = "rosberry/general"
    static let githubArchivePath: ((String, String) -> String) = { name, branch in
        "https://github.com/\(name)/archive/\(branch).zip"
    }
}

enum ColorChars {
    static let yellow = "\u{001B}[0;33m"
    static let green = "\u{001B}[0;32m"
    static let red = "\u{001B}[0;31m"
    static let `default` = "\u{001B}[0;0m"
}
