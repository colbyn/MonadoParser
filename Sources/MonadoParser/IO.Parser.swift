//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation

extension IO {
    public struct Parser<A> {
        internal let binder: (State) -> Output
        /// Initializes a parser with a binding function, which defines how the parser processes input and produces output.
        internal init(binder: @escaping (State) -> Output) {
            self.binder = binder
        }
        internal enum Output {
            case ok(value: A, state: State)
            case err(state: State)
        }
    }
}

//extension IO.Parser.Output {
//    public static 
//}

extension IO.Parser {
    public static func pure(value: A) -> Self {
        Self { $0.ok(value: value) }
    }
}

