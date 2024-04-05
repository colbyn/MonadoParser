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
    public typealias CharParser = Parser<Text.FatChar>
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
}

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
        public func advance(for character: Character) -> Self {
            if character.isNewline {
                return Self(character: self.character + 1, column: 0, line: line + 1)
            }
            return Self(character: self.character + 1, column: column + 1, line: line)
        }
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

extension IO.Text.FatChar {
    public var singleton: IO.Text {
        IO.Text(singleton: self)
    }
}

// MARK: - DEBUG -
extension IO.Text: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree.string(asString)
    }
}
extension IO.Text.FatChar: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .value("Text.FatChar(\(value.debugDescription))")
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
