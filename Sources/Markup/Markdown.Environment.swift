//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/29/24.
//

import Foundation

extension Markdown {
    public struct Environment {
        let scopes: [ Scope ]
        public init(scopes: [Scope]) {
            self.scopes = scopes
        }
        public enum Scope: Equatable {
            case inlineEmphasis
            case inlineHeader
            case inlineList
            case inlineLink
            case inlineString
            case inlineCode
            case inlineParagraph
        }
    }
}
extension Markdown.Environment {
    public static let root: Self = Self(scopes: [])
    public func with(scope: Scope) -> Self {
        Self( scopes: scopes.with(append: scope) )
    }
    public func contains(scope target: Scope) -> Bool {
        for scope in scopes {
            if scope == target {
                return true
            }
        }
        return false
    }
    public var avoidTheseInlineChars: Set<Character> {
        var tokens = Markdown.allInlineSymbols
        if contains(scope: .inlineLink) {
            tokens.remove("_")
        }
        return tokens
    }
    public var requiresSpecialInlineParsing: Bool {
        for scope in self.scopes {
            if scope.requiresSpecialInlineParsing {
                return true
            }
        }
        return false
    }
}
extension Markdown.Environment.Scope {
    /// This is based on the current parser implementation.
    public var requiresSpecialInlineParsing: Bool {
        switch self {
        // MARK: THESE DO
        case .inlineString, .inlineCode, .inlineLink, .inlineEmphasis: return true
        // MARK: THESE DO NOT
        case .inlineHeader, .inlineList, .inlineParagraph: return false
        }
    }
    public var inInline: Bool {
        switch self {
        case .inlineEmphasis: return true
        case .inlineHeader: return true
        case .inlineList: return true
        case .inlineLink: return true
        case .inlineString: return true
        case .inlineCode: return true
        case .inlineParagraph: return true
        }
    }
}
