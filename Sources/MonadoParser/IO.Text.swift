//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation

extension IO {
    public indirect enum Text {
        case empty, cons(FatChar, Text)
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
    }
}
