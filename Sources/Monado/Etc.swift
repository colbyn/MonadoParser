//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/5/24.
//

import Foundation
import PrettyTree

/// Ad-hoc helpers and et cetera are under this namespace.
public struct Etc {
    public struct SeperatedBy<A, B> {
        public let content: [A]
        public let separator: B?
    }
    public struct SeperatedByEndBy<A, B, C> {
        public let rows: [ SeperatedBy<A, B> ]
        public let terminal: C?
    }
    public struct Lines<Prefix, Content> {
        /// The startings tokens of each line.
        let lineStarts: [Prefix]
        /// The parsed sub-content.
        let content: Content
    }
}

// MARK: - DEBUG -
extension Etc.Lines: ToPrettyTree where Prefix: ToPrettyTree, Content: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        let label = "\(type(of: Self.self))"
        return .init(label: label, children: [
            .init(key: "lineStarts", value: lineStarts),
            .init(key: "content", value: content),
        ])
    }
}
