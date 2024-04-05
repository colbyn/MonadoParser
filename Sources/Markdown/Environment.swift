//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/2/24.
//

import Foundation
import Monado
import ExtraMonadoUtils
import PrettyTree

public struct Environment {
    let scopes: [ Scope ]
    public static let root: Self = Environment(scopes: [])
}

extension Environment {
    public enum Scope {
        case inline(Inline), block(Block), string
    }
    public enum ScopeDescriptor {
        case inline(Inline), block(Block)
    }
}

extension Environment.Scope {
    public enum Inline {
        case plainText
        case link(LinkPart)
        case image
        case emphasis(EmphasisType)
        case highlight
        case strikethrough
        case sub
        case sup
        case inlineCode(terminal: String)
        case latex(LatexType)
        public enum LinkPart {
            case inSquareBraces
            case inRoundBraces
        }
        public enum EmphasisType {
            case single(Character)
            case double(Character)
            case triple(Character)
            var asString: String {
                switch self {
                case .single(let x): return "\(x)"
                case .double(let x): return "\(x)\(x)"
                case .triple(let x): return "\(x)\(x)\(x)"
                }
            }
        }
    }
    public enum Block {
        case heading
        case paragraph
        case blockquote
        case list
        case listItem
        case unorderedListItem
        case orderedListItem
        case taskList
        case taskListItem
        case fencedCodeBlock
        case horizontalRule
        case table
        case tableRow
        case tableCell
        case latex(LatexType)
    }
    public enum LatexType {
        case single(Character)
        case double(Character)
    }
}

extension Environment {
    public func withScope(_ scope: Scope) -> Environment {
        Self(
            scopes: self.scopes.with(append: scope)
        )
    }
    public func withScope(inline scope: Scope.Inline) -> Environment {
        Self(
            scopes: self.scopes.with(append: .inline(scope))
        )
    }
    public func withScope(block scope: Scope.Block) -> Environment {
        Self(
            scopes: self.scopes.with(append: .block(scope))
        )
    }
    public var avoidThese: PredicateParser {
        fatalError("TODO")
    }
}

extension Environment.Scope {
    var avoidThese: Set<Character> {
        switch self {
        case .string: return ["\""]
        case .inline(let x): return x.avoidThese
        case .block(let x): return x.avoidThese
        }
    }
}
extension Environment.Scope.Inline {
    var avoidThese: Set<Character> {
        switch self {
        case .plainText: return []
        case .link(.inSquareBraces): return [ "]" ]
        case .link(.inRoundBraces): return [ ")" ]
        case .image: return []
        case .emphasis: return []
        case .highlight: return []
        case .strikethrough: return []
        case .sub: return []
        case .sup: return []
        case .inlineCode: return []
        case .latex: return []
        }
    }
}
extension Environment.Scope.Block {
    var avoidThese: Set<Character> {
        switch self {
        case .heading: return []
        case .paragraph: return []
        case .blockquote: return []
        case .list: return []
        case .listItem: return []
        case .unorderedListItem: return []
        case .orderedListItem: return []
        case .taskList: return []
        case .taskListItem: return []
        case .fencedCodeBlock: return []
        case .horizontalRule: return []
        case .table: return []
        case .tableRow: return []
        case .tableCell: return []
        case .latex: return []
        }
    }
}

// MARK: - ENV SCOPE DESCRIPTOR -
extension Environment.ScopeDescriptor {
    public enum Inline {
        case plainText
        case link
        case image
        case emphasis
        case highlight
        case strikethrough
        case sub
        case sup
        case inlineCode
        case latex
    }
    public enum Block {
        case heading
        case paragraph
        case blockquote
        case list
        case listItem
        case unorderedListItem
        case orderedListItem
        case taskList
        case taskListItem
        case fencedCodeBlock
        case horizontalRule
        case table
        case tableRow
        case tableCell
        case latex
    }
}

// MARK: - DEBUG -
extension Environment: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Environment", children: [
            .init(key: "scopes", value: scopes)
        ])
    }
}
extension Environment.Scope: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .inline(let x): return x.asPrettyTree
        case .block(let x): return x.asPrettyTree
        case .string: return .init(value: ".string")
        }
    }
}
extension Environment.Scope.Inline: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .plainText: return .init(value: ".plainText")
        case .link: return .init(value: ".link")
        case .image: return .init(value: ".image")
        case .emphasis: return .init(value: ".emphasis")
        case .highlight: return .init(value: ".highlight")
        case .strikethrough: return .init(value: ".strikethrough")
        case .sub: return .init(value: ".sub")
        case .sup: return .init(value: ".sup")
        case .inlineCode: return .init(value: ".inlineCode")
        case .latex: return .init(value: ".latex")
        }
    }
}
extension Environment.Scope.Block: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .heading: return PrettyTree(value: ".heading")
        case .paragraph: return PrettyTree(value: ".paragraph")
        case .blockquote: return PrettyTree(value: ".blockquote")
        case .list: return PrettyTree(value: ".list")
        case .listItem: return PrettyTree(value: ".listItem")
        case .unorderedListItem: return PrettyTree(value: ".unorderedListItem")
        case .orderedListItem: return PrettyTree(value: ".orderedListItem")
        case .taskList: return PrettyTree(value: ".taskList")
        case .taskListItem: return PrettyTree(value: ".taskListItem")
        case .fencedCodeBlock: return PrettyTree(value: ".fencedCodeBlock")
        case .horizontalRule: return PrettyTree(value: ".horizontalRule")
        case .table: return PrettyTree(value: ".table")
        case .tableRow: return PrettyTree(value: ".tableRow")
        case .tableCell: return PrettyTree(value: ".tableCell")
        case .latex: return PrettyTree(value: ".latex")
        }
    }
}
