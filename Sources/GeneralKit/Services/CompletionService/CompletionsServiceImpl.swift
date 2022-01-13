//
//  Copyright © 2020 Rosberry. All rights reserved.
//

import Foundation
import ArgumentParser

public final class CompletionsServiceImpl: CompletionsService {

    public typealias Dependencies = HasFileHelper & HasConfigFactory & HasCompletionScriptParser

    private let dependencies: Dependencies

    public let generateOptionName: String = "--generate-completion-script"

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func templates() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: "./\(Constants.templatesFolderName)")) ?? []
    }

    public func installedPlugins() -> [String] {
        guard let files = try? dependencies.fileHelper.contentsOfDirectory(at: Constants.pluginsPath) else {
            return []
        }
        return files.map { file in
            file.url.lastPathComponent
        }
    }

    public func executables() -> [String] {
        ["general"] + installedPlugins()
    }

    public func templatesRepos() -> [String] {
        guard let config = dependencies.configFactory.shared else {
            return []
        }
        return Array(config.templatesRepos.keys)
    }

    public func versions() -> [String] {
        return ["master", "0.3", "0.3.2", "0.3.3"]
    }

    public func defineCompletionShell() -> CompletionShell? {
        var arguments = CommandLine.arguments.dropFirst()
        let option = generateOptionName
        guard arguments.contains(option) else {
            return nil
        }
        arguments.removeAll { argument in
            argument == option
        }
        switch arguments.first {
        case "bash":
            return .bash
        case "fish":
            return .fish
        default:
            return .zsh
        }
    }

    public func overrideCompletionScript(config: CompletionConfig) -> String {
        guard let script = parseMainScript(config: config),
              let pluginsScripts = parsePluginsScripts(config: config) else {
            return config.command.completionScript(for: config.shell)
        }
        overrideMainScriptIfNeeded(script: script, pluginsScripts: pluginsScripts, config: config)
        return script.description
    }

    private func parseMainScript(config: CompletionConfig) -> CompletionScript? {
        let scriptString = config.command.completionScript(for: config.shell)
        return parse(script: scriptString, config: config)
    }

    private func parsePluginsScripts(config: CompletionConfig) -> [String: CompletionScript]? {
        var plugins = [String: CompletionScript]()
        config.plugins.forEach { key, scriptString in
            plugins[key] = dependencies.completionScriptParser.parse(script: scriptString, shell: config.shell)
        }
        guard plugins.isEmpty == false else {
            return nil
        }
        return plugins
    }

    private func parse(script: String, config: CompletionConfig) -> CompletionScript? {
        dependencies.completionScriptParser.parse(script: script, shell: config.shell)
    }

    private func overrideMainScriptIfNeeded(script: CompletionScript,
                                            pluginsScripts: [String: CompletionScript],
                                            config: CompletionConfig) {
        pluginsScripts.forEach { name, pluginScript in
            overrideMainScriptIfNeeded(script: script, pluginName: name, pluginScript: pluginScript, config: config)
        }
    }

    private func overrideMainScriptIfNeeded(script: CompletionScript,
                                            pluginName: String,
                                            pluginScript: CompletionScript,
                                            config: CompletionConfig) {
        let scriptCaseNames = mapCaseNames(script: script)
        let pluginCaseNames = mapCaseNames(script: pluginScript)

        func findMainCaseIndex(of subcommand: String) -> Int? {
            scriptCaseNames.firstIndex { name, subcommands in
                guard subcommands.count == 1,
                      let mainSubcommand = subcommands.first else {
                    return false
                }
                return subcommand == mainSubcommand
            }
        }

        pluginCaseNames.enumerated().forEach { index, caseName in
            let pluginName = caseName.0
            let subcommands = caseName.1
            let pluginCase = pluginScript.cases[index]

            guard subcommands.count == 1,
                  let subcommand = subcommands.first,
                  let pluginCaseContent = dependencies.completionScriptParser.overridePluginConent(pluginCase.1, script: script, pluginScript: pluginScript)  else {
                return
            }
            if let index = findMainCaseIndex(of: subcommand) {
                if isOverriden(subcommand: subcommand, pluginName: pluginName, config: config) {
                    let mainCaseName = script.cases[index].0
                    script.cases[index] = (mainCaseName, pluginCaseContent)
                }
            }
            else if let name = dependencies.completionScriptParser.makeCaseName(name: subcommand, script: script) {
                script.cases.append((name, pluginCaseContent))
            }
        }
    }

    private func isOverriden(subcommand: String, pluginName: String, config: CompletionConfig) -> Bool {
        config.overrides.contains { overridenCommand, overridenPluginName in
            overridenCommand.lowercased() == subcommand.lowercased() &&
                overridenPluginName.lowercased() == pluginName.lowercased()
        }
    }

    private func mapCaseNames(script: CompletionScript) -> [(String, [String])] {
        script.cases.compactMap { name, _ in
            dependencies.completionScriptParser.parseCaseName(name: name, shell: script.shell)
        }
    }
}

public extension CompletionKind {

    static var dependencies: HasCompletionsService = Services

    static var templates: CompletionKind {
        .custom { _ in
            dependencies.completionsService.templates()
        }
    }

    static var installedPlugins: CompletionKind {
        .custom { _ in
            dependencies.completionsService.installedPlugins()
        }
    }

    static var versions: CompletionKind {
        .custom { _ in
            dependencies.completionsService.versions()
        }
    }

    static var templatesRepos: CompletionKind {
        .custom { _ in
            dependencies.completionsService.templatesRepos()
        }
    }

    static var executables: CompletionKind {
        .custom { _ in
            dependencies.completionsService.executables()
        }
    }
}
