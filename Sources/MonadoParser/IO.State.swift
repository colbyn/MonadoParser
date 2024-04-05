//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation

extension IO {
    public struct State {
        public let text: Text
    }
}

extension IO.State {
    internal func ok<A>(value: A) -> IO.Parser<A>.Output {
        IO.Parser<A>.Output.ok(value: value, state: self)
    }
    internal func err<A>() -> IO.Parser<A>.Output {
        IO.Parser<A>.Output.err(state: self)
    }
    internal func set(text: IO.Text) -> Self {
        Self(text: text)
    }
}
