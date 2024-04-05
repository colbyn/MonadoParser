//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/2/24.
//

import Foundation
import PrettyTree

extension Markdown: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .block(let x): return x.asPrettyTree
        case .inline(let x): return x.asPrettyTree
        }
    }
}

// MARK: - INLINE BRANCHES -
extension Inline: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .plainText(let x): return x.asPrettyTree
        case .link(let x): return x.asPrettyTree
        case .image(let x): return x.asPrettyTree
        case .emphasis(let x): return x.asPrettyTree
        case .highlight(let x): return x.asPrettyTree
        case .strikethrough(let x): return x.asPrettyTree
        case .sub(let x): return x.asPrettyTree
        case .sup(let x): return x.asPrettyTree
        case .inlineCode(let x): return x.asPrettyTree
        case .latex(let x): return x.asPrettyTree
        case .lineBreak(let x): return x.asPrettyTree
        case .raw(let x): return .init(key: ".raw", value: x)
        }
    }
}
extension Inline.PlainText: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .init(key: "Inline.PlainText", value: value)
    }
}
extension Inline.Link: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Link", children: [
            .init(key: "text", value: text),
            .init(key: "openRoundBracket", value: openRoundBracket),
            .init(key: "destination", value: destination),
            .init(key: "title", value: title),
            .init(key: "closeRoundBracket", value: closeRoundBracket),
        ])
    }
}
extension Inline.Image: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Image", children: [
            .init(key: "bang", value: bang),
            .init(key: "altText", value: altText),
            .init(key: "openRoundBracket", value: openRoundBracket),
            .init(key: "src", value: src),
            .init(key: "title", value: title),
            .init(key: "closeRoundBracket", value: closeRoundBracket),
        ])
    }
}
extension Inline.Emphasis: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Emphasis", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "content", value: content),
            .init(key: "endDelimiter", value: endDelimiter),
        ])
    }
}
extension Inline.Highlight: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Highlight", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "content", value: content),
            .init(key: "endDelimiter", value: endDelimiter),
        ])
    }
}
extension Inline.Strikethrough: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Strikethrough", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "content", value: content),
            .init(key: "endDelimiter", value: endDelimiter),
        ])
    }
}
extension Inline.Subscript: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Subscript", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "content", value: content),
            .init(key: "endDelimiter", value: endDelimiter),
        ])
    }
}
extension Inline.Superscript: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.Superscript", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "content", value: content),
            .init(key: "endDelimiter", value: endDelimiter),
        ])
    }
}
extension Inline.InlineCode: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Inline.InlineCode", children: [
            .init(key: "startBacktick", value: startDelimiter),
            .init(key: "content", value: content),
            .init(key: "endBacktick", value: endDelimiter),
        ])
    }
}

// MARK: - BLOCK BRANCHES -
extension Block: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .heading(let x): return x.asPrettyTree
        case .paragraph(let x): return x.asPrettyTree
        case .blockquote(let x): return x.asPrettyTree
        case .list(let x): return x.asPrettyTree
        case .listItem(let x): return x.asPrettyTree
        case .unorderedListItem(let x): return x.asPrettyTree
        case .orderedListItem(let x): return x.asPrettyTree
        case .taskList(let x): return x.asPrettyTree
        case .taskListItem(let x): return x.asPrettyTree
        case .fencedCodeBlock(let x): return x.asPrettyTree
        case .horizontalRule(let x): return x.asPrettyTree
        case .table(let x): return x.asPrettyTree
        case .newline(let x): return .init(key: "newline", value: x)
//        case .latex(let x): return x.asPrettyTree
        }
    }
}
extension Block.Heading: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.Heading", children: [
            .init(key: "hashTokens", value: hashTokens),
            .init(key: "content", value: content),
        ])
    }
}
extension Block.Paragraph: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.Paragraph", children: [
            .init(key: "content", value: content),
        ])
    }
}
extension Block.Blockquote: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.Blockquote", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "content", value: content),
        ])
    }
}
extension Block.List: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.List", children: [
            .init(key: "items", value: items)
        ])
    }
}
extension Block.ListItem: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .unordered(let x): return x.asPrettyTree
        case .ordered(let x): return x.asPrettyTree
        }
    }
}
extension Block.UnorderedListItem: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.UnorderedListItem", children: [
            .init(key: "bullet", value: bullet),
            .init(key: "content", value: content),
        ])
    }
}
extension Block.OrderedListItem: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.OrderedListItem", children: [
            .init(key: "number", value: number),
            .init(key: "dot", value: dot),
            .init(key: "content", value: content),
        ])
    }
}
extension Block.TaskList: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.TaskList", children: [
            .init(key: "items", value: items)
        ])
    }
}
extension Block.TaskListItem: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.TaskListItem", children: [
            .init(key: "header", value: header),
            .init(key: "content", value: content),
        ])
    }
}
extension Block.FencedCodeBlock: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.FencedCodeBlock", children: [
            .init(key: "fenceStart", value: fenceStart),
            .init(key: "infoString", value: infoString),
            .init(key: "content", value: content),
            .init(key: "fenceEnd", value: fenceEnd),
        ])
    }
}
extension Block.HorizontalRule: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.HorizontalRule", children: [
            .init(key: "tokens", value: tokens)
        ])
    }
}
extension Block.Table: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.Table", children: [
            .init(key: "header", value: header),
            .init(key: "data", value: data),
        ])
    }
}
extension Block.Table.Header: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Block.Table.Header", children: [
            .init(key: "header", value: header),
            .init(key: "separator", value: separator),
        ])
    }
}
extension Block.Table.SeperatorRow: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Block.Table.SeperatorRow", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "columns", value: columns),
        ])
    }
}
extension Block.Table.SeperatorRow.Cell: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Block.Table.SeperatorRow.Cell", children: [
            .init(key: "startColon", value: startColon),
            .init(key: "dashes", value: dashes),
            .init(key: "endColon", value: endColon),
            .init(key: "endDelimiter", value: endDelimiter),
        ])
    }
}
extension Block.Table.Row: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Block.Table.Row", children: [
            .init(key: "startDelimiter", value: startDelimiter),
            .init(key: "cells", value: cells),
        ])
    }
}
extension Block.Table.Row.Cell: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Block.Table.Row.Cell", children: [
            .init(key: "content", value: content),
            .init(key: "pipeDelimiter", value: pipeDelimiter),
        ])
    }
}

// MARK: - OTHER FORMATS -
extension Latex: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Latex", children: [
            .init(key: "start", value: start),
            .init(key: "content", value: content),
            .init(key: "close", value: close),
        ])
    }
}

// MARK: - TYPE HELPERS -
extension Inline.InDoubleQuotes: ToPrettyTree where Content: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        .init(label: "Inline.InDoubleQuotes", children: [
            .init(key: "openQuote", value: openQuote),
            .init(key: "content", value: content),
            .init(key: "closeQuote", value: closeQuote),
        ])
    }
}
extension Inline.InSquareBrackets: ToPrettyTree where Content: ToPrettyTree {
     public var asPrettyTree: PrettyTree {
         .init(label: "Inline.InSquareBrackets", children: [
            .init(key: "openSquareBracket", value: openSquareBracket),
            .init(key: "content", value: content),
            .init(key: "closeSquareBracket", value: closeSquareBracket),
         ])
     }
 }
