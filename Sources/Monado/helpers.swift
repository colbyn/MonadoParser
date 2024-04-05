//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation
import PrettyTree

/// The `Either` type represents a value of one of two possible types (a disjoint union). Instances of `Either` are either an instance of `Left` or `Right`.
///
/// `Either` is useful for cases where a function might return two different types of objects. It's a way to carry information about a success or an error, where `Left` might represent a failure and `Right` a success.
public enum Either<Left, Right> {
    case left(Left), right(Right)
    /// Determines whether the instance is a `Left` value.
    public var isLeft: Bool {
        switch self {
        case .left(_): return true
        case .right(_): return false
        }
    }
    /// Determines whether the instance is a `Right` value.
    public var isRight: Bool {
        switch self {
        case .right(_): return true
        case .left(_): return false
        }
    }
    /// Returns the contained `Left` value, if present; otherwise, `nil`.
    public var asLeft: Left? {
        switch self {
        case .left(let x): return x
        case .right(_): return nil
        }
    }
    /// Returns the contained `Right` value, if present; otherwise, `nil`.
    public var asRight: Right? {
        switch self {
        case .right(let x): return x
        case .left(_): return nil
        }
    }
}
/// A generic structure for holding two related values of possibly different types.
///
/// The `Tuple` type is useful for functions that need to return more than one value, encapsulating them in a single composite value.
public struct Tuple<A, B> {
    public let a: A
    public let b: B
    public init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
    public func mapA<T>(_ f: @escaping (A) -> T) -> Tuple<T, B> {
        Tuple<T, B>(f(a), b)
    }
    public func mapB<T>(_ f: @escaping (B) -> T) -> Tuple<A, T> {
        Tuple<A, T>(a, f(b))
    }
}
/// A generic structure for holding three related values of possibly different types.
///
/// Similar to `Tuple`, but for cases where three values need to be grouped together. Useful for returning multiple values from a function and maintaining type information.
public struct Triple<A, B, C> {
    public let a: A
    public let b: B
    public let c: C
    public init(_ a: A, _ b: B, _ c: C) {
        self.a = a
        self.b = b
        self.c = c
    }
    /// Returns a new `Triple` with the first value transformed by the given function.
    public func mapA<T>(_ f: @escaping (A) -> T) -> Triple<T, B, C> {
        Triple<T, B, C>(f(a), b, c)
    }
    /// Returns a new `Triple` with the second value transformed by the given function.
    public func mapB<T>(_ f: @escaping (B) -> T) -> Triple<A, T, C> {
        Triple<A, T, C>(a, f(b), c)
    }
    /// Returns a new `Triple` with the third value transformed by the given function.
    public func mapC<T>(_ f: @escaping (C) -> T) -> Triple<A, B, T> {
        Triple<A, B, T>(a, b, f(c))
    }
}
/// A generic structure for holding four related values of possibly different types.
///
/// Extends the idea of `Tuple` and `Triple` for situations where four related items need to be passed or returned from a function as a single composite value.
public struct Quadruple<A, B, C, D> {
    public let a: A
    public let b: B
    public let c: C
    public let d: D
    public init(a: A, b: B, c: C, d: D) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }
}
public struct SeperatedBy<A, B> {
    public let content: [A]
    public let separator: B?
}
public struct SeperatedByEndBy<A, B, C> {
    public let rows: [ SeperatedBy<A, B> ]
    public let terminal: C?
}

// MARK: - DEBUG -
extension Either: ToPrettyTree where Left: ToPrettyTree, Right: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .left(let left): return PrettyTree(key: ".left", value: left.asPrettyTree)
        case .right(let right): return PrettyTree(key: ".right", value: right.asPrettyTree)
        }
    }
}
extension Tuple: ToPrettyTree where A: ToPrettyTree, B: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        PrettyTree(label: "Tuple", children: [
            .init(key: "a", value: a.asPrettyTree),
            .init(key: "b", value: b.asPrettyTree),
        ])
    }
}
extension Triple: ToPrettyTree where A: ToPrettyTree, B: ToPrettyTree, C: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        PrettyTree(label: "Tuple", children: [
            .init(key: "a", value: a.asPrettyTree),
            .init(key: "b", value: b.asPrettyTree),
            .init(key: "c", value: c.asPrettyTree),
        ])
    }
}
extension Quadruple: ToPrettyTree where A: ToPrettyTree, B: ToPrettyTree, C: ToPrettyTree, D: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        PrettyTree(label: "Tuple", children: [
            .init(key: "a", value: a.asPrettyTree),
            .init(key: "b", value: b.asPrettyTree),
            .init(key: "c", value: c.asPrettyTree),
            .init(key: "d", value: d.asPrettyTree),
        ])
    }
}
