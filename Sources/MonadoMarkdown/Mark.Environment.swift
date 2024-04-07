//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/6/24.
//

import Foundation
import MonadoParser
import PrettyTree

extension Mark {
    public struct Environment {
        let scopes: [ Scope ]
        public static let root: Self = Environment(scopes: [])
    }
}

extension Mark.Environment {
    public enum Scope {
        case inline(Inline), block(Block), string
    }
}

extension Mark.Environment.Scope {
    public enum Inline {
        case plainText
        case link(LinkPart)
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
    }
    public enum LatexType {
        case single(Character)
        case double(Character)
    }
}

extension Mark.Environment {
    public func withScope(_ scope: Scope) -> Self {
        Self(
            scopes: self.scopes.with(append: scope)
        )
    }
    public func withScope(inline scope: Scope.Inline) -> Self {
        Self(
            scopes: self.scopes.with(append: .inline(scope))
        )
    }
    public func withScope(block scope: Scope.Block) -> Self {
        Self(
            scopes: self.scopes.with(append: .block(scope))
        )
    }
    public var inlineTerminators: IO.TextParser {
        IO.Parser.options(self.scopes.last?.avoidThese.compactMap { IO.TextParser.token($0) } ?? [])
    }
    public var avoidThese: IO.ControlFlowParser {
        IO.ControlFlowParser.wrap(flip: inlineTerminators)
    }
}


extension Mark.Environment.Scope {
    var avoidThese: Set<String> {
        switch self {
        case .string: return ["\""]
        case .inline(let x): return x.avoidThese
        case .block: return []
        }
    }
}
extension Mark.Environment.Scope.Inline {
    var avoidThese: Set<String> {
        switch self {
        case .plainText: return []
        case .link(.inSquareBraces): return [ "]" ]
        case .link(.inRoundBraces): return [ ")" ]
        case .emphasis(.single(let x)): return [ "\(x)" ]
        case .emphasis(.double(let x)): return [ "\(x)\(x)" ]
        case .emphasis(.triple(let x)): return [ "\(x)\(x)\(x)" ]
        case .highlight: return [ "==" ]
        case .strikethrough: return [ "~~" ]
        case .sub: return [ "~" ]
        case .sup: return [ "^" ]
        case .inlineCode(terminal: let x): return [ x ]
        case .latex(.single(let x)): return [ "\(x)" ]
        case .latex(.double(let x)): return [ "\(x)\(x)" ]
        }
    }
}

// MARK: - DEBUG -
extension Mark.Environment: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Mark.Environment", children: [
            .init(key: "scopes", value: scopes)
        ])
    }
}
extension Mark.Environment.Scope: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        fatalError("TODO")
    }
}
extension Mark.Environment.Scope.Inline: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .plainText: return .value(".plainText")
        case .link(let x): return .init(key: "link", value: x)
        case .emphasis(let x): return .init(key: "emphasis", value: x)
        case .highlight: return .value(".highlight")
        case .strikethrough: return .value(".strikethrough")
        case .sub: return .value(".sub")
        case .sup: return .value(".sup")
        case .inlineCode(let x): return .init(key: ".inlineCode", value: x)
        case .latex(let x): return .init(key: "latex", value: x)
        }
    }
}
extension Mark.Environment.Scope.LatexType: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .single(let x): return .value("'\(x)'")
        case .double(let x): return .value("'\(x)\(x)'")
        }
    }
}
extension Mark.Environment.Scope.Inline.EmphasisType: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .single(let x): return .value("'\(x)'")
        case .double(let x): return .value("'\(x)\(x)'")
        case .triple(let x): return .value("'\(x)\(x)\(x)'")
        }
    }
}
extension Mark.Environment.Scope.Inline.LinkPart: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .inRoundBraces: return .value(".inRoundBraces")
        case .inSquareBraces: return .value(".inSquareBraces")
        }
    }
}
extension Mark.Environment.Scope.Block: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .heading: return .value(".heading")
        case .paragraph: return .value(".paragraph")
        case .blockquote: return .value(".blockquote")
        case .list: return .value(".list")
        case .listItem: return .value(".listItem")
        case .unorderedListItem: return .value(".unorderedListItem")
        case .orderedListItem: return .value(".orderedListItem")
        case .taskList: return .value(".taskList")
        case .taskListItem: return .value(".taskListItem")
        case .fencedCodeBlock: return .value(".fencedCodeBlock")
        case .horizontalRule: return .value(".horizontalRule")
        case .table: return .value(".table")
        case .tableRow: return .value(".tableRow")
        case .tableCell: return .value(".tableCell")
        }
    }
}
