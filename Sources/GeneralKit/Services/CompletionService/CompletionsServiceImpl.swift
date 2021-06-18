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
        case "zsh":
            return .zsh
        case "fish":
            return .fish
        default:
            return .bash
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
        filterPluginCases(script: pluginScript, config: config).forEach { commandName, content in
            guard let caseIndex = caseIndex(of: commandName, script: script) else {
                return
            }
            let caseName = script.cases[caseIndex].0
            script.cases[caseIndex] = (caseName, content)
        }
    }

    private func filterPluginCases(script: CompletionScript, config: CompletionConfig) -> [(String, String)] {
        var result = [(String, String)]()
        script.cases.forEach { name, content in
            guard let (pluginName, commands) = dependencies.completionScriptParser.parseCaseName(name: name, shell: config.shell),
                  let command = commands.first else {
                return
            }
            let isOverridenCommand = config.overrides.contains { overridenCommand, overridenPluginName in
                overridenCommand.lowercased() == command.lowercased() &&
                    overridenPluginName.lowercased() == pluginName.lowercased()
            }
            if isOverridenCommand {
                result.append((command, content))
            }
        }
        return result
    }

    private func caseIndex(of commandName: String, script: CompletionScript) -> Int? {
        guard let name = dependencies.completionScriptParser.makeCaseName(name: commandName, script: script) else {
            return nil
        }
        return script.cases.firstIndex { caseName, _ in
            caseName == name
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
