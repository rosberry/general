//
//  CustomLexer.swift
//  GeneralKit
//
//  Created by Nick Tyunin on 27.12.2021.
//

import Foundation
import Stencil

typealias Line = (content: String, number: UInt, range: Range<String.Index>)

public struct CustomSourceMap: Equatable {
  public let filename: String?
  public let location: ContentLocation

  init(filename: String? = nil, location: ContentLocation = ("", 0, 0)) {
    self.filename = filename
    self.location = location
  }

  static let unknown = CustomSourceMap()

  public static func == (lhs: CustomSourceMap, rhs: CustomSourceMap) -> Bool {
    return lhs.filename == rhs.filename && lhs.location == rhs.location
  }
}

public class CustomToken: Equatable {
  public enum Kind: Equatable {
    /// A token representing a piece of text.
    case text
    /// A token representing a variable.
    case variable
    /// A token representing a comment.
    case comment
    /// A token representing a template block.
    case block
  }

  public let contents: String
  public let kind: Kind
  public let sourceMap: CustomSourceMap

  /// Returns the underlying value as an array seperated by spaces
  public private(set) lazy var components: [String] = self.contents.smartSplit()

  init(contents: String, kind: Kind, sourceMap: CustomSourceMap) {
    self.contents = contents
    self.kind = kind
    self.sourceMap = sourceMap
  }

  /// A token representing a piece of text.
  public static func text(value: String, at sourceMap: CustomSourceMap) -> CustomToken {
    return CustomToken(contents: value, kind: .text, sourceMap: sourceMap)
  }

  /// A token representing a variable.
  public static func variable(value: String, at sourceMap: CustomSourceMap) -> CustomToken {
    return CustomToken(contents: value, kind: .variable, sourceMap: sourceMap)
  }

  /// A token representing a comment.
  public static func comment(value: String, at sourceMap: CustomSourceMap) -> CustomToken {
    return CustomToken(contents: value, kind: .comment, sourceMap: sourceMap)
  }

  /// A token representing a template block.
  public static func block(value: String, at sourceMap: CustomSourceMap) -> CustomToken {
    return CustomToken(contents: value, kind: .block, sourceMap: sourceMap)
  }

  public static func == (lhs: CustomToken, rhs: CustomToken) -> Bool {
    return lhs.contents == rhs.contents && lhs.kind == rhs.kind && lhs.sourceMap == rhs.sourceMap
  }
}

struct CustomLexer {
  let templateName: String?
  let templateString: String
  let lines: [Line]

  /// The potential token start characters. In a template these appear after a
  /// `{` character, for example `{{`, `{%`, `{#`, ...
  private static let tokenChars: [Unicode.Scalar] = ["{", "%", "#"]

  /// The token end characters, corresponding to their token start characters.
  /// For example, a variable token starts with `{{` and ends with `}}`
  private static let tokenCharMap: [Unicode.Scalar: Unicode.Scalar] = [
    "{": "}",
    "%": "%",
    "#": "#"
  ]

  init(templateName: String? = nil, templateString: String) {
    self.templateName = templateName
    self.templateString = templateString

    self.lines = templateString.components(separatedBy: .newlines).enumerated().compactMap {
      guard !$0.element.isEmpty,
        let range = templateString.range(of: $0.element) else { return nil }
      return (content: $0.element, number: UInt($0.offset + 1), range)
    }
  }

  /// Create a token that will be passed on to the parser, with the given
  /// content and a range. The content will be tested to see if it's a
  /// `variable`, a `block` or a `comment`, otherwise it'll default to a simple
  /// `text` token.
  ///
  /// - Parameters:
  ///   - string: The content string of the token
  ///   - range: The range within the template content, used for smart
  ///            error reporting
  func createToken(string: String, at range: Range<String.Index>) -> CustomToken {
    func strip() -> String {
      guard string.count > 4 else { return "" }
      let trimmed = String(string.dropFirst(2).dropLast(2))
        .components(separatedBy: "\n")
        .filter { !$0.isEmpty }
        .map { $0.trim(character: " ") }
        .joined(separator: " ")
      return trimmed
    }

    if string.hasPrefix("{{") || string.hasPrefix("{%") || string.hasPrefix("{#") {
      let value = strip()
      let range = templateString.range(of: value, range: range) ?? range
      let location = rangeLocation(range)
      let sourceMap = CustomSourceMap(filename: templateName, location: location)
      if string.hasPrefix("{{") {
        return .variable(value: value, at: sourceMap)
      } else if string.hasPrefix("{%") {
        return .block(value: value, at: sourceMap)
      } else if string.hasPrefix("{#") {
        return .comment(value: value, at: sourceMap)
      }
    }

    let location = rangeLocation(range)
    let sourceMap = CustomSourceMap(filename: templateName, location: location)
    return .text(value: string, at: sourceMap)
  }

  /// Transforms the template into a list of tokens, that will eventually be
  /// passed on to the parser.
  ///
  /// - Returns: The list of tokens (see `createToken(string: at:)`).
  func tokenize() -> [CustomToken] {
    var tokens: [CustomToken] = []

    let scanner = Scanner(templateString)
    while !scanner.isEmpty {
      if let (char, text) = scanner.scanForTokenStart(CustomLexer.tokenChars) {
        if !text.isEmpty {
          tokens.append(createToken(string: text, at: scanner.range))
        }

        guard let end = CustomLexer.tokenCharMap[char] else { continue }
        let result = scanner.scanForTokenEnd(end)
        tokens.append(createToken(string: result, at: scanner.range))
      } else {
        tokens.append(createToken(string: scanner.content, at: scanner.range))
        scanner.content = ""
      }
    }

    return tokens
  }

  /// Finds the line matching the given range (for a token)
  ///
  /// - Parameter range: The range to search for.
  /// - Returns: The content for that line, the line number and offset within
  ///            the line.
  func rangeLocation(_ range: Range<String.Index>) -> ContentLocation {
    guard let line = self.lines.first(where: { $0.range.contains(range.lowerBound) }) else {
      return ("", 0, 0)
    }
    let offset = templateString.distance(from: line.range.lowerBound, to: range.lowerBound)
    return (line.content, line.number, offset)
  }
}

class Scanner {
  let originalContent: String
  var content: String
  var range: Range<String.UnicodeScalarView.Index>

  /// The start delimiter for a token.
  private static let tokenStartDelimiter: Unicode.Scalar = "{"
  /// And the corresponding end delimiter for a token.
  private static let tokenEndDelimiter: Unicode.Scalar = "}"

  init(_ content: String) {
    self.originalContent = content
    self.content = content
    range = content.unicodeScalars.startIndex..<content.unicodeScalars.startIndex
  }

  var isEmpty: Bool {
    return content.isEmpty
  }

  /// Scans for the end of a token, with a specific ending character. If we're
  /// searching for the end of a block token `%}`, this method receives a `%`.
  /// The scanner will search for that `%` followed by a `}`.
  ///
  /// Note: if the end of a token is found, the `content` and `range`
  /// properties are updated to reflect this. `content` will be set to what
  /// remains of the template after the token. `range` will be set to the range
  /// of the token within the template.
  ///
  /// - Parameter tokenChar: The token end character to search for.
  /// - Returns: The content of a token, or "" if no token end was found.
  func scanForTokenEnd(_ tokenChar: Unicode.Scalar) -> String {
    var foundChar = false

    for (index, char) in content.unicodeScalars.enumerated() {
      if foundChar && char == Scanner.tokenEndDelimiter {
        let result = String(content.unicodeScalars.prefix(index + 1))
        content = String(content.unicodeScalars.dropFirst(index + 1))
        range = range.upperBound..<originalContent.unicodeScalars.index(range.upperBound, offsetBy: index + 1)
        return result
      } else {
        foundChar = (char == tokenChar)
      }
    }

    content = ""
    return ""
  }

  /// Scans for the start of a token, with a list of potential starting
  /// characters. To scan for the start of variables (`{{`), blocks (`{%`) and
  /// comments (`{#`), this method receives the characters `{`, `%` and `#`.
  /// The scanner will search for a `{`, followed by one of the search
  /// characters. It will give the found character, and the content that came
  /// before the token.
  ///
  /// Note: if the start of a token is found, the `content` and `range`
  /// properties are updated to reflect this. `content` will be set to what
  /// remains of the template starting with the token. `range` will be set to
  /// the start of the token within the template.
  ///
  /// - Parameter tokenChars: List of token start characters to search for.
  /// - Returns: The found token start character, together with the content
  ///            before the token, or nil of no token start was found.
  func scanForTokenStart(_ tokenChars: [Unicode.Scalar]) -> (Unicode.Scalar, String)? {
    var foundBrace = false

    range = range.upperBound..<range.upperBound
    for (index, char) in content.unicodeScalars.enumerated() {
      if foundBrace && tokenChars.contains(char) {
        let result = String(content.unicodeScalars.prefix(index - 1))
        content = String(content.unicodeScalars.dropFirst(index - 1))
        range = range.upperBound..<originalContent.unicodeScalars.index(range.upperBound, offsetBy: index - 1)
        return (char, result)
      } else {
        foundBrace = (char == Scanner.tokenStartDelimiter)
      }
    }

    return nil
  }
}

extension String {
  func findFirstNot(character: Character) -> String.Index? {
    var index = startIndex

    while index != endIndex {
      if character != self[index] {
        return index
      }
      index = self.index(after: index)
    }

    return nil
  }

  func findLastNot(character: Character) -> String.Index? {
    var index = self.index(before: endIndex)

    while index != startIndex {
      if character != self[index] {
        return self.index(after: index)
      }
      index = self.index(before: index)
    }

    return nil
  }

  func trim(character: Character) -> String {
    let first = findFirstNot(character: character) ?? startIndex
    let last = findLastNot(character: character) ?? endIndex
    return String(self[first..<last])
  }
}

public typealias ContentLocation = (content: String, lineNumber: UInt, lineOffset: Int)

extension String {
    /// Split a string by a separator leaving quoted phrases together
    func smartSplit(separator: Character = " ") -> [String] {
        var word = ""
        var components: [String] = []
        var separate: Character = separator
        var singleQuoteCount = 0
        var doubleQuoteCount = 0

        for character in self {
          if character == "'" {
            singleQuoteCount += 1
          } else if character == "\"" {
            doubleQuoteCount += 1
          }

          if character == separate {
            if separate != separator {
              word.append(separate)
            } else if (singleQuoteCount % 2 == 0 || doubleQuoteCount % 2 == 0) && !word.isEmpty {
              appendWord(word, to: &components)
              word = ""
            }

            separate = separator
          } else {
            if separate == separator && (character == "'" || character == "\"") {
              separate = character
            }
            word.append(character)
          }
        }

        if !word.isEmpty {
          appendWord(word, to: &components)
        }

        return components
    }

    private func appendWord(_ word: String, to components: inout [String]) {
        let specialCharacters = ",|:"

        if !components.isEmpty {
            if let precedingChar = components.last?.last, specialCharacters.contains(precedingChar) {
                components[components.count - 1] += word
            } else if specialCharacters.contains(word) {
                components[components.count - 1] += word
            } else if word != "(" && word.first == "(" || word != ")" && word.first == ")" {
                components.append(String(word.prefix(1)))
                appendWord(String(word.dropFirst()), to: &components)
            } else if word != "(" && word.last == "(" || word != ")" && word.last == ")" {
                appendWord(String(word.dropLast()), to: &components)
                components.append(String(word.suffix(1)))
            } else {
                components.append(word)
            }
        } else {
            components.append(word)
        }
    }
}
