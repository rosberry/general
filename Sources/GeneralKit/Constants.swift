//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation

public enum Constants {
    public static let version = "3.0"
    public static let shell = "/bin/bash"
    public static let generalHomePath = "\(NSHomeDirectory())/.general"
    public static let configPath = "\(generalHomePath)/.config"
    public static let pluginsPath = "\(generalHomePath)//plugins"
    public static let downloadedSourcePath = "\(generalHomePath)/source"
    public static let specFilename = "spec.yml"
    public static let templatesFolderName = ".templates"
    public static let commonTemplatesFolderName = "common"
    public static let filesFolderName = "Code"
    public static let templateFilename = "template.stencil"
    public static let template = "{{ name }}"
    public static let projectName = "Project.xcodeproj"
    public static let generalSpecName = ".general.yml"
    public static let appFolderName = ".general"
    public static let stencilPathExtension = "stencil"
    public static let xcodeProjectPathExtension = "xcodeproj"
    public static let relativeCurrentPath = "./"
    public static let tmpFolderPath = "/tmp"
    public static let generalTmpFolderPrefix = "general"
    public static let defaultGithubBranch = "master"
    public static let githubRepo = "rosberry/general"
    public static let githubArchivePath: ((String, String) -> String) = { name, branch in
        "https://github.com/\(name)/archive/\(branch).zip"
    }
}

enum ColorChars {
    static let yellow = "\u{001B}[0;33m"
    static let green = "\u{001B}[0;32m"
    static let red = "\u{001B}[0;31m"
    static let `default` = "\u{001B}[0;0m"
}
