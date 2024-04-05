//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//
// This file contains Monado’s core monadic parser combinators.

import Foundation

extension IO.Parser {
    /// Attempts to parse using each parser in the provided array, in order, stopping at the first success.
    ///
    /// - Parameter parsers: An array of parsers to be tried sequentially until one succeeds.
    /// - Returns: A parser that succeeds if any of the provided parsers succeed.
    public static func options(_ parsers: @escaping @autoclosure () -> [Self]) -> Self {
        return Self {
            loop: for p in parsers() {
                switch p.binder($0) {
                case .continue(value: let a, state: let state): return state.continue(value: a)
                case .break: continue loop
                }
            }
            return $0.break()
        }
    }
}

