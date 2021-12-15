//
//  Bootstraper.swift
//  GeneralIOs
//
//  Created by Nick Tyunin on 28.10.2021.
//

import UmalerKit
import GeneralKit
import Stencil
import StencilSwiftKit
import Yams
import PathKit
import Foundation

final class UMLBootstraper {

    enum Error: LocalizedError {
        case architecture(String)

        var errorDescription: String? {
            switch self {
            case let .architecture(path):
                return "Could not parse architecture using specified uml path \(path)"
            }
        }
    }

    enum StringResolve {
        case resolved(String)
        case unresolved([ArchitectureTemplateItem.MatchToken])
        case renderFailure
    }

    enum Resolve {
        case resolvedDirectory(String)
        case unresolvedDirectoryName(StringResolve)
        case resolvedFile(String, String)
        case unresolvedFile
        case unresolvedFileName(StringResolve)
        case renderFailure
    }

    var context: [String: Any] = [:]
    private lazy var environment: Environment = {
        let environment = Environment(loader: nil, extensions: [], templateClass: VariablesTemplate.self)
        environment.extensions.forEach { ext in
            ext.registerStencilSwiftExtensions()
        }
        return environment
    }()

    private lazy var architectureParser = ArchitectureUMLParser()
    private lazy var diagramsParser = PlantUMLParser()
    private lazy var plantuml = Plantuml()

    typealias Dependencies = HasFileHelper

    private var dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func bootstrap(with config: BootstrapConfig) throws {
        initContext(with: config)
        guard let template = try createProjectFiles(template: config.template, destination: ".") else {
            return
        }
        let diagrams = try parseDiagrams(path: config.diagrams)
        guard let architecture = try parseArchitecture(
                diagrams: diagrams,
                template: template,
                methodsExcepts: [
                    "success",
                    "failure",
                    "finish"
                ]) else {
            throw Error.architecture(config.diagrams)
        }
        try bootstrap(item: architecture, destination: ".")
        try dependencies.fileHelper.removeFile(at: .init(fileURLWithPath: "./.boot"))
    }

    private func initContext(with config: BootstrapConfig) {
        context = config.context
    }

    private func createProjectFiles(template: String, destination: String) throws -> (ArchitectureTemplateItem?) {
        let fileInfo = try dependencies.fileHelper.fileInfo(with: URL(fileURLWithPath: expandingTildeInPath(template)))
        let status = resolve(fileInfo)

        switch status {
        case let .resolvedDirectory(name):
            return try composeFolder(fileInfo: fileInfo, tokens: [.concrete(name)], name: name, destination: destination)
        case let .resolvedFile(name, content):
            try content.write(toFile: "\(destination)/\(name)", atomically: true, encoding: .utf8)
        case let .unresolvedDirectoryName(resolve):
            switch resolve {
            case .resolved:
                print("Invalid resolved status for template at \(fileInfo.url)")
            case let .unresolved(tokens):
                return try composeFolder(fileInfo: fileInfo, tokens: tokens, name: nil, destination: destination)
            case .renderFailure:
                print("Could not render file name of template \(fileInfo.url)")
            }
        case let .unresolvedFileName(resolve):
            switch resolve {
            case .resolved:
                print("Invalid resolved status for template at \(fileInfo.url)")
            case let .unresolved(tokens):
                return try makeTemplateFile(fileInfo: fileInfo, tokens: tokens, destination: destination)
            case .renderFailure:
                return try makeTemplateFile(fileInfo: fileInfo, tokens: [], destination: destination)
            }
        case .unresolvedFile:
            return try makeTemplateFile(fileInfo: fileInfo, tokens: [], destination: destination)
        case .renderFailure:
            return try makeTemplateFile(fileInfo: fileInfo, tokens: [], destination: destination)
        }
        return nil
    }

    private func composeFolder(fileInfo: FileInfo, tokens: [ArchitectureTemplateItem.MatchToken], name: String?, destination: String) throws -> ArchitectureTemplateItem? {
        if let name = name {
            try dependencies.fileHelper.createDirectory(at: "\(destination)/\(name)")
        }
        let folder = bootPath(destination: destination, name: name ?? fileInfo.url.lastPathComponent)
        try dependencies.fileHelper.createDirectory(at: folder)
        let filesDestination = "\(destination)/\(name ?? fileInfo.url.lastPathComponent)"
        let items = try dependencies.fileHelper.contentsOfDirectory(at: fileInfo.url).compactMap { fileInfo in
            try createProjectFiles(template: fileInfo.url.path, destination: filesDestination)
        }
        guard items.isEmpty == false else {
            let url = URL(fileURLWithPath: folder)
            try dependencies.fileHelper.removeFile(at: url)
            return nil
        }
        return .folder(tokens, items)
    }

    private func makeTemplateFile(fileInfo: FileInfo, tokens: [ArchitectureTemplateItem.MatchToken], destination: String) throws -> ArchitectureTemplateItem? {
        guard fileInfo.url.lastPathComponent != ".DS_Store" else {
            return nil
        }
        let floder = ".boot/\(destination)"
        try dependencies.fileHelper.createDirectory(at: floder)
        let path = "\(floder)/\(fileInfo.url.lastPathComponent)"
        guard let data = try? Data(contentsOf: fileInfo.url) else {
            print("Could not read template file at \(fileInfo.url)")
            return nil
        }
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        let name = fileInfo.url.deletingPathExtension().lastPathComponent
        switch resolveVariables(string: name) {
        case let .unresolved(tokens):
            return .file(tokens)
        default:
            return .file([.concrete(name)])
        }
    }

    private func resolve(_ fileInfo: FileInfo) -> Resolve {
        let fileNameResolve = resolveFileName(fileInfo)
        switch fileNameResolve {
        case let .resolved(fileName):
            guard fileInfo.isDirectory == false else {
                return .resolvedDirectory(fileName)
            }
            return resolveFile(with: fileName, fileInfo: fileInfo)
        case .unresolved:
            return fileInfo.isDirectory ? .unresolvedDirectoryName(fileNameResolve) : .unresolvedFileName(fileNameResolve)
        case .renderFailure:
            return .renderFailure
        }
    }

    private func resolveFile(with fileName: String, fileInfo: FileInfo) -> Resolve {
        guard let data = try? Data(contentsOf: fileInfo.url),
              let string = String(data: data, encoding: .utf8) else {
            return .renderFailure
        }
        let template = VariablesTemplate(templateString: string)
        let unresolvedVariables = self.unresolvedVariables(in: template)
        guard unresolvedVariables.isEmpty else {
            return .unresolvedFile
        }
        guard let content = try? environment.renderTemplate(string: string, context: context) else {
            return .renderFailure
        }
        return .resolvedFile(fileName, content)
    }

    private func resolveFileName(_ fileInfo: FileInfo) -> StringResolve {
        let fileName = fileInfo.url.lastPathComponent.trimmingCharacters(in: .whitespaces)
        return resolveVariables(string: fileName)
    }

    private func resolveVariables(string: String) -> StringResolve {
        let template = VariablesTemplate(templateString: string)
        let unresolvedVariables = self.unresolvedVariables(in: template)
        guard unresolvedVariables.isEmpty else {
            return .unresolved(tokenize(string: string, variables: unresolvedVariables, template: template))
        }
        guard let value = try? template.render(context) else {
            return .renderFailure
        }
        return .resolved(value)
    }

    private func tokenize(string: String, variables: [String], template: VariablesTemplate) -> [ArchitectureTemplateItem.MatchToken] {
        let pattern = "\\{\\{\\s*([a-zA-Z][a-zA-Z0-9.]*)\\s*\\}\\}"
        let matches = parseAllRegexMatches(pattern: pattern, rangeIndex: 0, string: string)
        var tokens = [ArchitectureTemplateItem.MatchToken]()
        var startIndex = string.startIndex

        func unresolved(match: String) -> String? {
            variables.first { string in
                match.contains(string)
            }
        }

        matches.forEach { match in
            guard let range = string.range(of: match) else {
                return
            }
            let prefix = String(string[startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)

            if prefix.isEmpty == false {
                tokens.append(.concrete(prefix))
            }
            if let name = unresolved(match: match) {
                tokens.append(.variable(name))
            }
            else if let name = try? VariablesTemplate(templateString: match).render(context) {
                tokens.append(.concrete(name))
            } else {
                tokens.append(.any)
            }
            startIndex = range.upperBound
        }
        let suffix =  String(string[startIndex..<string.endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        if suffix.isEmpty == false {
            tokens.append(.concrete(suffix))
        }
        return tokens
    }

    private func unresolvedVariables(in template: VariablesTemplate) -> [String] {
        template.variables.compactMap { variable -> String? in
            hasValue(for: variable) ? nil : variable
        }
    }

    private func hasValue(for variable: String) -> Bool {
        hasValue(for: variable.split(separator: ".").map({ String($0) }), in: context)
    }

    private func hasValue(for components: [String], in dictionary: [String: Any]) -> Bool {
        guard let key = components.first?.trimmingCharacters(in: .whitespacesAndNewlines),
              let anyValue = dictionary[key] else {
            return false
        }
        guard components.count > 1 else {
            return true
        }
        guard let dictionary = anyValue as? [String: Any] else {
            return false
        }
        return hasValue(for: Array(components.dropFirst()), in: dictionary)
    }

    private func expandingTildeInPath(_ path: String) -> String {
        return path.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
    }

    private func parseDiagrams(path: String) throws -> [Diagram] {
        let preprocessedPath = try plantuml.preprocessed(path: path, mode: "ios")
        let diagrams = try diagramsParser.parse(path: preprocessedPath)
        return diagrams
    }

    private func parseArchitecture(diagrams: [Diagram],
                                   template: ArchitectureTemplateItem,
                                   methodsExcepts: [String]) throws -> ArchitectureItem? {
        try architectureParser.parse(diagrams: diagrams, using: [template] + methodsExcepts.map { name in
            .except(.method([.concrete(name)]))
        }).first
    }

    private func bootstrap(item: ArchitectureItem, destination: String) throws {
        switch item {
        case let .folder(folder):
            try bootstrap(folder: folder, destination: destination)
        case let .object(object):
            try bootstrap(object: object, destination: destination)
        }
    }

    private func bootstrap(folder: ArchitectureItem.Folder, destination: String) throws {
        let path = "\(destination)/\(folder.name)"
        try dependencies.fileHelper.createDirectory(at: path)
        guard let template = self.template(for: destination, name: folder.name),
              let files = try? dependencies.fileHelper.contentsOfDirectory(at: template.url) else {
            try folder.items.forEach { item in
                try bootstrap(item: item, destination: path)
            }
            return
        }

        func item(for file: FileInfo) -> ArchitectureItem? {
            let fileName = fileNameBase(from: file)
            return folder.items.first { item in
                return isMatch(pattern: fileName, using: name(of: item))
            }
        }

        func bootstrapMissingFile(_ file: FileInfo, destination: String) throws {
            guard file.url.lastPathComponent.lowercased() != ".ds_store" else {
                return
            }
            switch resolve(file) {
            case let .resolvedFile(name, content):
                let path = "\(destination)/\(name)"
                try content.write(toFile: path, atomically: true, encoding: .utf8)
            case let .resolvedDirectory(name):
                let path = "\(destination)/\(name)"
                try dependencies.fileHelper.createDirectory(at: path)
                try dependencies.fileHelper.contentsOfDirectory(at: file.url).forEach { file in
                    try bootstrapMissingFile(file, destination: path)
                }
            default:
                break
            }
        }

        let fileName = fileNameBase(from: template)
        let variables = resolveContext(pattern: fileName, using: folder.name)

        try folder.items.forEach { item in
            try bootstrap(item: item, destination: path)
        }

        try files.forEach { file in
            guard item(for: file) == nil else {
                return
            }
            try bootstrapMissingFile(file, destination: path)
        }

        variables.forEach { name in
            context = clean(context: context, name: name) ?? context
        }
    }
    private func bootstrap(object: ArchitectureItem.Object, destination: String) throws {
        guard let template = self.template(for: destination, name: object.name) else {
            return
        }
        let fileName = fileNameBase(from: template)
        resolveContext(pattern: fileName, using: object.name)
        switch resolve(template) {
        case let .resolvedFile(name, content):
            let path = "\(destination)/\(name)"
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        default:
            break
        }
    }

    private func template(for destination: String, name: String?) -> FileInfo? {
        let bootUrl = URL(fileURLWithPath: bootPath(destination: destination))

        guard let fileInfo = try? dependencies.fileHelper.fileInfo(with: bootUrl) else {
            return nil
        }

        func findMatchFile(folder: FileInfo, name: String?) -> FileInfo? {
            guard let name = name else {
                return folder
            }
            guard let files = try? dependencies.fileHelper.contentsOfDirectory(at: folder.url) else {
                return nil
            }
            return files.first { file in
                let fileName = fileNameBase(from: file)
                guard fileName != name else {
                    return true
                }
                return isMatch(pattern: fileName, using: name)
            }
        }

        guard fileInfo.isExists == false else {
            return findMatchFile(folder: fileInfo, name: name)
        }
        var parentFolderPath = URL(fileURLWithPath: destination).deletingLastPathComponent().path
        let rootPath = URL(fileURLWithPath: "./").path
        parentFolderPath.removeFirst(rootPath.count)
        parentFolderPath = "." + parentFolderPath
        guard let parentFolderTemplate = template(for: parentFolderPath, name: nil),
              let thisFolderTemplate = findMatchFile(folder: parentFolderTemplate, name: fileInfo.url.lastPathComponent) else {
            return nil
        }
        return findMatchFile(folder: thisFolderTemplate, name: name)
    }

    private func isMatch(pattern: String, using resolved: String) -> Bool {
        let (isSuccess, _) = parseMatch(pattern: pattern, using: resolved, parseHandler: nil)
        return isSuccess
    }

    @discardableResult
    private func resolveContext(pattern: String, using resolved: String) -> [String] {
        let (isSuccess, values) = parseMatch(pattern: pattern, using: resolved) { name, value in
            self.context = self.update(context: self.context, name: name, value: value) ?? self.context
        }
        guard isSuccess else {
            return []
        }
        return values
    }

    private func parseMatch(pattern: String, using resolved: String, parseHandler: ((String, String) -> Void)?) -> (Bool, [String]) {
        guard pattern != resolved else {
            return (true, [])
        }
        var values = [String]()
        let variablesResolve = resolveVariables(string: pattern)
        let tokens: [ArchitectureTemplateItem.MatchToken]
        switch variablesResolve {
        case let .resolved(resolvedPattern):
            return (resolvedPattern == resolved, [])
        case let .unresolved(missingTokens):
            tokens = missingTokens
        case .renderFailure:
            return (false, [])
        }
        let regex = tokens.map { token -> String in
            switch token {
            case let .concrete(name):
                return name
            default:
                return "([a-zA-Z][a-zA-Z0-9]*)"
            }
        }.joined()
        var matches = parseAllRegexMatches(pattern: regex, rangeIndex: 1, string: resolved)
        guard matches.isEmpty == false else {
            return (false, [])
        }
        var string = resolved
        for token in tokens {
            switch token {
            case let .concrete(substing):
                guard string.starts(with: substing) else {
                    return (false, [])
                }
                string.removeFirst(substing.count)
            case let .variable(name):
                guard matches.isEmpty == false else {
                    return (false, [])
                }
                let value = matches.removeFirst()
                string.removeFirst(value.count)
                parseHandler?(name, value)
                values.append(name)
            case .any:
                guard matches.isEmpty == false else {
                    continue
                }
                let value = matches.removeFirst()
                string.removeFirst(value.count)
            }
        }
        return (true, values)
    }

    private func update(context: [String: Any]?, name: String, value: String) -> [String: Any]? {
        update(context: context, path: name.split(separator: ".").map{ String($0)}, value: value)
    }

    private func update(context: [String: Any]?, path: [String], value: String) -> [String: Any]? {
        guard let key = path.first else {
            return nil
        }
        var path = path
        path.removeFirst()

        var context = context ?? [:]
        if path.isEmpty {
            context[key] = value
        } else {
            context[key] = update(context: context[key] as? [String:Any], path: path, value: value)
        }
        return context
    }

    private func clean(context: [String: Any]?, name: String) -> [String: Any]? {
        guard let rootKey = name.split(separator: ".").first else {
            return context
        }
        var context = context
        context?.removeValue(forKey: String(rootKey))
        return context
    }

    private func fileNameBase(from fileInfo: FileInfo) -> String {
        if fileInfo.isDirectory {
            return fileInfo.url.lastPathComponent
        }
        else {
            return fileInfo.url.deletingPathExtension().lastPathComponent
        }
    }

    private func bootPath(destination: String) -> String {
        let path: String
        if let prefix = [".//", "./", "."].first { destination.contains($0) } {
            var destination = destination
            destination.removeFirst(prefix.count)
            if destination.isEmpty {
                path = ".boot"
            } else {
                path = ".boot/\(destination)"
            }
        } else {
            path = ".boot/\(destination)"
        }
        return path
    }

    private func bootPath(destination: String, name: String) -> String {
        "\(bootPath(destination: destination))/\(name)"
    }

    private func name(of item: ArchitectureItem) -> String {
        switch item {
        case let .folder(folder):
            return folder.name
        case let .object(object):
            return object.name
        }
    }
}
