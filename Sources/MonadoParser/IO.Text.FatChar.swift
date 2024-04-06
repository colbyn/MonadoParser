//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation
import PrettyTree

extension IO.Text {
    /// A `FatChar` is a Swift `Character` with metadata denoting its original source code position.
    ///
    /// Represents an annotated character within the `Tape`, including its value and position in the original input.
    public struct FatChar {
        public let value: Character
        public let index: PositionIndex
    }
    /// Models the position of a character in the input, supporting detailed parsing error messages and context analysis.
    public struct PositionIndex {
        public let character: UInt
        public let column: UInt
        public let line: UInt
        public static let zero = Self(character: 0, column: 0, line: 0)
        /// Advances the position index based on the given character, accommodating line breaks.
        internal func advance(for character: Character) -> Self {
            if character.isNewline {
                return Self(character: self.character + 1, column: 0, line: line + 1)
            }
            return Self(character: self.character + 1, column: column + 1, line: line)
        }
    }
}
extension IO {
    public typealias CharParser = IO.Parser<IO.Text.FatChar>
}

extension IO.Text.FatChar {
    public var singleton: IO.Text {
        IO.Text(singleton: self)
    }
}

extension IO.CharParser {
    /// A parser that consumes and returns the next character from the input stream, if available.
    ///
    /// This parser is useful when you need to consume a single character regardless of what it is, often used in scenarios where the specific character is not important or is handled dynamically.
    ///
    /// - Returns: A parser that consumes the next available character.
    public static var next: IO.CharParser {
        Self {
            guard let (first, rest) = $0.text.uncons else {
                return $0.break()
            }
            return $0.set(text: rest).continue(value: first)
        }
    }
    /// Parses the next character if it matches the given pattern.
    ///
    /// - Parameter pattern: The character to match.
    /// - Returns: A parser that succeeds if the next character matches the pattern.
    ///
    /// Example:
    /// ```swift
    /// let aParser = CharParser.char("a")
    /// ```
    public static func char(_ pattern: Character) -> Self {
        Self {
            guard let (head, rest) = $0.text.uncons(pattern: pattern) else {
                return $0.break()
            }
            return $0.set(text: rest).continue(value: head)
        }
    }
    /// Parses the next character if it satisfies the given predicate.
    ///
    /// - Parameter predicate: A closure that takes a character and returns true if it should be parsed.
    /// - Returns: A parser that succeeds if the next character satisfies the predicate.
    ///
    /// Example:
    /// ```swift
    /// let digitParser = CharParser.pop { $0.isNumber }
    /// ```
    public static func char(_ predicate: @escaping (Character) -> Bool) -> Self {
        Self.pop { predicate($0.value) }
    }
    /// Parses the next character if it satisfies the given predicate.
    public static func pop(_ predicate: @escaping (IO.Text.FatChar) -> Bool) -> Self {
        Self {
            guard let (head, rest) = $0.text.unconsIf(predicate: predicate) else {
                return $0.break()
            }
            return $0.set(text: rest).continue(value: head)
        }
    }
    /// A parser that specifically consumes and returns a newline character from the input stream, if it is the next character.
    ///
    /// This parser is particularly useful in text processing tasks, such as parsing log files, configuration files, or other text data where newlines signify the end of a line or entry.
    ///
    /// - Returns: A parser that succeeds if the next character is a newline, consuming it.
    public static var newline: Self {
        Self.char { $0.isNewline }
    }
    public static var space: Self {
        Self.char { $0.isWhitespace && !$0.isNewline }
    }
    public static var anyWhitespace: Self {
        Self.char { $0.isWhitespace }
    }
    public static var number: Self {
        Self.char { $0.isNumber }
    }
}



// MARK: - DEBUG -
extension IO.Text.FatChar: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .value("Text.FatChar(\(value.debugDescription))")
    }
}
