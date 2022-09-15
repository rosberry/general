//
//  BootstrapConfig.swift
//  GeneralIOs
//
//  Created by Nick Tyunin on 11.11.2021.
//

public struct BoostrapShellCommand {
    let name: String
    let arguments: String
    let missingFiles: [String]
}

public struct BootstrapConfig {
    let name: String
    let context: [String: Any]
    let template: String
    let diagrams: String?
    let shell: [BoostrapShellCommand]
}
