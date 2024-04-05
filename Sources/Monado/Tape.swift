//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation
import PrettyTree
import ExtraMonadoUtils

/// A `Tape` is a linked list of annotated characters. (I would call it `Text` but it's taken by `SwiftUI`'s `Text` element.)
///
/// `Tape` models a sequence of characters for parsing, allowing efficient, non-destructive consumption of input. It is designed to be easy to work with for parsing tasks, supporting operations like concatenation, splitting, and single-character consumption.
///
/// The Tape type is a recursive enumeration that represents a sequence of annotated characters, akin to a linked list. Each character in the Tape carries not only the character value itself but also its position within the original input, facilitating rich, context-aware parsing and error reporting.
public indirect enum Tape {
    case empty, cons(FatChar, Tape)
    /// Initializes a `Tape` from an array of `Char`, effectively converting a sequence of characters into a linked list.
    public init(from stream: [FatChar]) {
        self = stream
            .reversed()
            .reduce(Tape.empty) { (rest, next) in Tape.cons(next, rest) }
    }
    public init(flatten tapes: [Tape]) {
        self = tapes
            .flatMap { $0.flatten }
            .reversed()
            .reduce(Tape.empty) { (rest, next) in Tape.cons(next, rest) }
    }
    /// Initializes a `Tape` with a single character, creating a singleton list.
    public init(singleton head: FatChar) {
        self = .cons(head, .empty)
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
    /// Flattens two `Tape` instances into one, appending the trailing tape to the leading one.
    public static func flatten(leading: Tape, trailing: Tape) -> Tape {
        let xs = leading.flatten
        let ys = trailing.flatten
        return Tape(from: xs.with(append: ys))
    }
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
    public var uncons: (FatChar, Tape)? {
        switch self {
        case .empty: return nil
        case .cons(let char, let tape): return (char, tape)
        }
    }
    /// Attempts to consume a specified number of characters, returning them and the remaining `Tape`.
    public func take(count: UInt) -> ([FatChar], Tape) {
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
    public func uncons(pattern: Character) -> (FatChar, Tape)? {
        guard let (head, rest) = self.uncons else { return nil }
        guard head.value == pattern else { return nil }
        return (head, rest)
    }
    /// Attempts to consume a character satisfying a given predicate.
    public func unconsIf(predicate: @escaping (Tape.FatChar) -> Bool) -> (FatChar, Tape)? {
        guard let (head, rest) = self.uncons else { return nil }
        guard predicate(head) else { return nil }
        return (head, rest)
    }
    /// Attempts to consume a character satisfying a given predicate.
    public func unconsFor(predicate: @escaping (Character) -> Bool) -> (FatChar, Tape)? {
        unconsIf(predicate: { predicate($0.value) })
    }
    /// Returns the `Tape` as a flat array of characters.
    public var flatten: [ FatChar ] {
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
    public func with(append tail: Tape?) -> Tape {
        if let tail = tail {
            let xs = self.flatten
            let ys = tail.flatten
            return Tape(from: xs.with(append: ys))
        }
        return self
    }
    public func with(append char: Tape.FatChar) -> Tape {
        let xs = self.flatten.with(append: [char])
        return Tape(from: xs)
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
    public var positionIndex: PositionIndex? {
        switch self {
        case .cons(let char, _): return char.index
        case .empty: return nil
        }
    }
    func transformLines(_ f: @escaping (Tape) -> Tape) -> Tape {
        var lines: [[FatChar]] = []
        var current: [FatChar] = []
        for x in flatten {
            if x.value.isNewline {
                lines.append(current.with(append: x))
                current = []
                continue
            }
            current.append(x)
        }
        let all = lines.with(append: current)
        let newLines = all.map { line in
            f(Tape(from: line))
        }
        return Tape.init(flatten: newLines)
    }
    func filter(_ predicate: @escaping (FatChar) -> Bool) -> Tape {
        Tape(from: flatten.filter(predicate))
    }
}

extension Tape: CustomDebugStringConvertible {
    public var debugDescription: String {
        self.asString.debugDescription
    }
}

extension Tape.FatChar {
    public var singleton: Tape {
        Tape(singleton: self)
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
extension Tape.FatChar: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
//        return PrettyTree(label: "Tape.Char", children: [
//            PrettyTree(key: "value", value: value),
//            PrettyTree(key: "index", value: index),
//        ])
        return .value("Tape.FatChar(\(value.debugDescription))")
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
