//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation

extension IO {
    public struct SequenceSettings {
        let allowEmpty: Bool
        let until: Optional<() -> IO.ControlFlowParser>
        public func allowEmpty(_ flag: Bool) -> Self {
            Self(allowEmpty: flag, until: until)
        }
        public func until(terminator: @escaping () -> IO.ControlFlowParser) -> Self {
            Self(allowEmpty: allowEmpty, until: terminator)
        }
        public static var `default`: Self {
            Self(allowEmpty: false, until: nil)
        }
    }
}

extension IO.Parser {
    public func sequence(settings: IO.SequenceSettings) -> IO.Parser<[A]> {
        IO.Parser<[A]> {
            var results: [A] = []
            var current: IO.State = $0
            var counter = 0
            loop: while !current.text.isEmpty {
                counter += 1
                if counter >= 1000 {
                    let type = "Parser<[\(type(of: A.self))]>.sequence"
                    print("\(type) WARNING: TOO MANY ITERATIONS")
                }
                if let until = settings.until, case .break = until().binder(current) {
                    break loop
                }
                switch self.binder(current) {
                case .continue(value: let a, state: let rest):
                    current = rest
                    results.append(a)
                    if counter >= 1000 {
                        let type = "Parser<[\(type(of: A.self))]>.sequence"
                        print("\(type) WARNING: TOO MANY ITERATIONS: LAST: \(a)")
                    }
                    continue loop
                case .break: break loop
                }
            }
            if !settings.allowEmpty, results.isEmpty {
                return $0.break()
            }
            return current.continue(value: results)
        }
    }
    public var some: IO.Parser<[A]> {
        sequence(settings: IO.SequenceSettings(allowEmpty: false, until: .none))
    }
    public var many: IO.Parser<[A]> {
        sequence(settings: IO.SequenceSettings(allowEmpty: true, until: .none))
    }
}

