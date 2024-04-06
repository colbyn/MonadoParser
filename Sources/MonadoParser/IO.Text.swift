//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation
import ExtraMonadoUtils
import PrettyTree

extension IO {
    public indirect enum Text {
        case empty, cons(FatChar, Text)
    }
    public typealias TextParser = Parser<Text>
}

extension IO.Text {
    public init(from string: [FatChar]) {
        self = string
            .reversed()
            .reduce(IO.Text.empty) { (rest, next) in IO.Text.cons(next, rest) }
    }
    /// Initializes a `Tape` with a single character, creating a singleton list.
    public init(singleton head: FatChar) {
        self = .cons(head, .empty)
    }
    public init(flatten segments: [IO.Text]) {
        self = segments
            .flatMap { $0.chars }
            .reversed()
            .reduce(IO.Text.empty) { (rest, next) in IO.Text.cons(next, rest) }
    }
    /// Initializes a `Tape` from a `String`, annotating each character with its position index.
    public init(initalize string: String) {
        var position = PositionIndex.zero
        let chars = string.map {
            let result = FatChar(value: $0, index: position)
            position = position.advance(for: $0)
            return result
        }
        self = .init(from: chars)
    }
    /// Appends another `Tape` to this one.
    public func with(append tail: IO.Text?) -> IO.Text {
        if let tail = tail {
            let xs = self.chars
            let ys = tail.chars
            return IO.Text(from: xs.with(append: ys))
        }
        return self
    }
    public func with(append char: IO.Text.FatChar) -> IO.Text {
        let xs = self.chars.with(append: [char])
        return IO.Text(from: xs)
    }
    func filter(_ predicate: @escaping (FatChar) -> Bool) -> IO.Text {
        IO.Text(from: chars.filter(predicate))
    }
    /// Attempts to consume the next character, returning it along with the rest of the `Tape`.
    public var uncons: (FatChar, IO.Text)? {
        switch self {
        case .empty: return nil
        case .cons(let char, let tape): return (char, tape)
        }
    }
    /// Attempts to consume a specified number of characters, returning them and the remaining `Tape`.
    public func take(count: UInt) -> ([FatChar], IO.Text) {
        if count == 0 {
            return ([], self)
        }
        switch self {
        case .empty: return ([], .empty)
        case .cons(let char, let tape):
            let (xs, rest) = tape.take(count: count - 1)
            return ([char].with(append: xs), rest)
        }
    }
    /// Splits the `Tape` at a prefix string, returning the matched segment and the rest.
    public func split(prefix: String) -> (IO.Text, IO.Text)? {
        let (tokens, rest) = self.take(count: UInt(prefix.count))
        if tokens.count == prefix.count {
            let isMatch = zip(prefix, tokens).allSatisfy { (l, r) in l == r.value }
            if isMatch {
                return (IO.Text(from: tokens), rest)
            }
        }
        return nil
    }
    /// Attempts to consume a character matching a specific pattern.
    public func uncons(pattern: Character) -> (FatChar, IO.Text)? {
        guard let (head, rest) = self.uncons else { return nil }
        guard head.value == pattern else { return nil }
        return (head, rest)
    }
    /// Attempts to consume a character satisfying a given predicate.
    public func unconsIf(predicate: @escaping (IO.Text.FatChar) -> Bool) -> (FatChar, IO.Text)? {
        guard let (head, rest) = self.uncons else { return nil }
        guard predicate(head) else { return nil }
        return (head, rest)
    }
    func transformLines(_ f: @escaping (IO.Text) -> IO.Text) -> IO.Text {
        var lines: [[FatChar]] = []
        var current: [FatChar] = []
        for x in chars {
            if x.value.isNewline {
                lines.append(current.with(append: x))
                current = []
                continue
            }
            current.append(x)
        }
        let all = lines.with(append: current)
        let newLines = all.map { line in
            f(IO.Text(from: line))
        }
        return IO.Text.init(flatten: newLines)
    }
}

extension IO.Text {
    public var chars: [ FatChar ] {
        switch self {
        case .empty: return []
        case .cons(let fatChar, let text): return [fatChar].with(append: text.chars)
        }
    }
    public var isEmpty: Bool {
        switch self {
        case .empty: return true
        case .cons: return false
        }
    }
    public var asString: String {
        String(chars.map { $0.value })
    }
}

extension IO.Text: CustomDebugStringConvertible {
    public var debugDescription: String {
        self.asString.debugDescription
    }
}

extension IO.TextParser {
    /// Creates a parser that consumes a specific string pattern from the input.
    ///
    /// This parser matches and consumes the exact sequence of characters defined by the given pattern. It's particularly useful for recognizing specific keywords, symbols, or other fixed sequences within a larger text stream.
    ///
    /// - Parameter pattern: The exact string sequence to match and consume.
    /// - Returns: A parser that consumes the specified string pattern if it matches the beginning of the input.
    ///
    /// Example:
    /// ```swift
    /// let keywordParser = TapeParser.pop("func")
    /// // Consumes the keyword "func" from the input, if present.
    /// ```
    public static func token(_ pattern: String) -> Self {
        Self {
            guard let (head, rest) = $0.text.split(prefix: pattern) else {
                return $0.break()
            }
            return $0.set(text: rest).continue(value: head)
        }
    }
    public static var spaces: Self {
        IO.CharParser.char { $0.isWhitespace && !$0.isNewline }
            .many
            .map { IO.Text(from: $0) }
    }
}

// MARK: - DEBUG -
extension IO.Text: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree.string(asString)
    }
}
extension IO.Text.PositionIndex: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Text.PositionIndex", children: [
            PrettyTree(key: "character", value: character),
            PrettyTree(key: "column", value: column),
            PrettyTree(key: "line", value: line),
        ])
    }
}
