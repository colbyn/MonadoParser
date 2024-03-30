//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation
import PrettyTree

/// A `Tape` is a linked list of annotated characters.
///
/// `Tape` models a sequence of characters for parsing, allowing efficient, non-destructive consumption of input. It is designed to be easy to work with for parsing tasks, supporting operations like concatenation, splitting, and single-character consumption.
///
/// The Tape type is a recursive enumeration that represents a sequence of annotated characters, akin to a linked list. Each character in the Tape carries not only the character value itself but also its position within the original input, facilitating rich, context-aware parsing and error reporting.
public indirect enum Tape {
    case empty, cons(Char, Tape)
    /// Initializes a `Tape` from an array of `Char`, effectively converting a sequence of characters into a linked list.
    public init(from stream: [Char]) {
        self = stream
            .reversed()
            .reduce(Tape.empty) { (rest, next) in Tape.cons(next, rest) }
    }
    /// Initializes a `Tape` with a single character, creating a singleton list.
    public init(singleton head: Char) {
        self = .cons(head, .empty)
    }
    /// Initializes a `Tape` from a `String`, annotating each character with its position index.
    public init(from string: String) {
        var position = PositionIndex.zero
        let chars = string.map {
            let result = Char(value: $0, index: position)
            position = position.advance(for: $0)
            return result
        }
        self = .init(from: chars)
    }
    /// Flattens two `Tape` instances into one, appending the trailing tape to the leading one.
    public static func flatten(leading: Tape, trailing: Tape) -> Tape {
        let xs = leading.flatten
        let ys = trailing.flatten
        return Tape(from: xs.with(append: ys))
    }
    /// Represents an annotated character within the `Tape`, including its value and position in the original input.
    public struct Char {
        let value: Character
        let index: PositionIndex
    }
    /// Models the position of a character in the input, supporting detailed parsing error messages and context analysis.
    public struct PositionIndex {
        let character: UInt
        let column: UInt
        let line: UInt
    }
}

extension Tape {
    /// Checks if the `Tape` is empty.
    public var isEmpty: Bool {
        switch self {
        case .empty: return true
        case .cons: return false
        }
    }
    /// Attempts to consume the next character, returning it along with the rest of the `Tape`.
    public var uncons: (Char, Tape)? {
        switch self {
        case .empty: return nil
        case .cons(let char, let tape): return (char, tape)
        }
    }
    /// Attempts to consume a specified number of characters, returning them and the remaining `Tape`.
    public func take(count: UInt) -> ([Char], Tape) {
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
    public func split(prefix: String) -> (Tape, Tape)? {
        let (tokens, rest) = self.take(count: UInt(prefix.count))
        if tokens.count == prefix.count {
            let isMatch = zip(prefix, tokens).allSatisfy { (l, r) in l == r.value }
            if isMatch {
                return (Tape(from: tokens), rest)
            }
        }
        return nil
    }
    /// Attempts to consume a character matching a specific pattern.
    public func uncons(pattern: Character) -> (Char, Tape)? {
        guard let (head, rest) = self.uncons else { return nil }
        guard head.value == pattern else { return nil }
        return (head, rest)
    }
    /// Attempts to consume a character satisfying a given predicate.
    public func uncons(predicate: @escaping (Character) -> Bool) -> (Char, Tape)? {
        guard let (head, rest) = self.uncons else { return nil }
        guard predicate(head.value) else { return nil }
        return (head, rest)
    }
    /// Returns the `Tape` as a flat array of characters.
    public var flatten: [ Char ] {
        switch self {
        case .empty: return []
        case .cons(let char, let tape): return [char].with(append: tape.flatten)
        }
    }
    /// Converts the `Tape` into a `String`.
    public var asString: String {
        String(flatten.map { $0.value })
    }
    /// Appends another `Tape` to this one.
    public func with(append tail: Tape) -> Tape {
        let xs = self.flatten
        let ys = tail.flatten
        return Tape(from: xs.with(append: ys))
    }
    /// Checks if two `Tape` instances are semantically equal.
    public func semanticallyEqual(with other: Tape) -> Bool {
        switch (self, other) {
        case (.empty, .empty): return true
        case (.cons(let c1, let t1), .cons(let c2, let t2)) where c1.value == c2.value:
            return t1.semanticallyEqual(with: t2)
        default: return false
        }
    }
}

extension Tape: CustomDebugStringConvertible {
    public var debugDescription: String {
        self.asString.debugDescription
    }
}

extension Tape.PositionIndex {
    public static let zero = Self(character: 0, column: 0, line: 0)
    /// Advances the position index based on the given character, accommodating line breaks.
    public func advance(for character: Character) -> Self {
        if character.isNewline {
            return Self(character: self.character + 1, column: 0, line: line + 1)
        }
        return Self(character: self.character + 1, column: column + 1, line: line)
    }
}

// MARK: - DEBUG -
extension Tape: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree.string(asString)
    }
}
extension Tape.Char: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Tape.Char", children: [
            PrettyTree(key: "value", value: value),
            PrettyTree(key: "index", value: index),
        ])
    }
}
extension Tape.PositionIndex: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Tape.PositionIndex", children: [
            PrettyTree(key: "character", value: character),
            PrettyTree(key: "column", value: column),
            PrettyTree(key: "line", value: line),
        ])
    }
}
