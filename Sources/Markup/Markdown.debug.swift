//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation
import PrettyTree

extension Markdown: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .plainText(let x): return x.asPrettyTree
        case .newline(let x): return PrettyTree(key: "Markdown.newline", value: x)
        case .raw(let x): return PrettyTree(key: "Markdown.raw", value: x)
        case .paragraph(let x): return x.asPrettyTree
        case .emphasis(let x): return x.asPrettyTree
        case .heading(let x): return x.asPrettyTree
        case .listItem(let x): return x.asPrettyTree
        case .link(let x): return x.asPrettyTree
        case .inlineCode(let x): return x.asPrettyTree
        case .fencedCodeBlock(let x): return x.asPrettyTree
        }
    }
}
extension Markdown.Paragraph: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        let content = content.map { $0.asPrettyTree }
        return PrettyTree(label: "Markdown.Paragraph", children: content)
    }
}
extension Markdown.Fragment: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        let items = items.map { $0.asPrettyTree }
        return PrettyTree(label: "Markdown.Fragment", children: items)
    }
}
extension Markdown.Heading: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .atx(let atxHeading): return atxHeading.asPrettyTree
        case .setext(let setextHeading): return setextHeading.asPrettyTree
        }
    }
}
extension Markdown.Heading.AtxHeading: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Heading.AtxHeading", children: [
            .init(key: "hashes", value: hashes),
            .init(key: "content", value: content),
            .init(key: "id", value: id),
        ])
    }
}

extension Markdown.Heading.SetextHeading: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Heading.AtxHeading", children: [
            PrettyTree(key: "leadingSpace", value: leadingSpace),
            PrettyTree(key: "content", value: content),
            PrettyTree(key: "underline", value: underline),
            PrettyTree(key: "id", value: id),
        ])
    }
}

extension Markdown.Heading.ID: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Heading.ID", children: [
            .init(key: "openCurlyBracket", value: openCurlyBracket),
            .init(key: "content", value: content),
            .init(key: "closeCurlyBracket", value: closeCurlyBracket),
        ])
    }
}
extension Markdown.Emphasis: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Emphasis", children: [
            .init(key: "open", value: open),
            .init(key: "content", value: content),
            .init(key: "close", value: close),
        ])
    }
}
extension Markdown.InlineCode: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.InlineCode", children: [
            .init(key: "open", value: open),
            .init(key: "content", value: content),
            .init(key: "close", value: close),
        ])
    }
}
extension Markdown.FencedCodeBlock: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.FencedCodeBlock", children: [
            .init(key: "open", value: open),
            .init(key: "language", value: language),
            .init(key: "content", value: content),
            .init(key: "close", value: close),
        ])
    }
}
extension Markdown.ListItem: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .ordered(let ordered): return ordered.asPrettyTree
        case .unordered(let unordered): return unordered.asPrettyTree
        case .task(let task): return task.asPrettyTree
        }
    }
}
extension Markdown.ListItem.Unordered: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .init(label: "Markdown.ListItem.Unordered", children: [
            PrettyTree(key: "leadingSpace", value: leadingSpace),
            PrettyTree(key: "token", value: itemToken),
            PrettyTree(key: "content", value: content),
        ])
    }
}
extension Markdown.ListItem.Ordered: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .init(label: "Markdown.ListItem.Ordered", children: [
            PrettyTree(key: "leadingSpace", value: leadingSpace),
            PrettyTree(key: "symbol", value: symbol),
            PrettyTree(key: "dot", value: dot),
            PrettyTree(key: "content", value: content),
        ])
    }
}
extension Markdown.ListItem.Task: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .init(label: "Markdown.ListItem.Task", children: [
            .init(key: "leadingSpace", value: leadingSpace),
            .init(key: "box", value: box),
            .init(key: "content", value: content),
        ])
    }
}
extension Markdown.ListItem.Task.Box: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return .init(label: "Markdown.ListItem.Task.Box", children: [
            .init(key: "openSquareBracket", value: openSquareBracket),
            .init(key: "content", value: content),
            .init(key: "closeSquareBracket", value: closeSquareBracket),
        ])
    }
}
extension Markdown.Link: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        switch self {
        case .hyperText(let hyperText): return hyperText.asPrettyTree
        case .image(let image): return image.asPrettyTree
        }
    }
}
extension Markdown.Link.HyperText: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Link.HyperText", children: [
            .init(key: "text", value: text),
            .init(key: "url", value: url),
        ])
    }
}
extension Markdown.Link.Image: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Link.Image", children: [
            .init(key: "imagePrefix", value: imagePrefix),
            .init(key: "text", value: text),
            .init(key: "url", value: url),
        ])
    }
}
extension Markdown.Link.SquareBracketEnclosure: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Link.SquareBracketEnclosure", children: [
            .init(key: "textOpenBracket", value: textOpenBracket),
            .init(key: "text", value: text),
            .init(key: "textCloseBracket", value: textCloseBracket),
        ])
    }
}
extension Markdown.Link.RoundBracketEnclosure: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Link.RoundBracketEnclosure", children: [
            .init(key: "urlOpenBracket", value: urlOpenBracket),
            .init(key: "url", value: url),
            .init(key: "title", value: title),
            .init(key: "urlCloseBracket", value: urlCloseBracket),
        ])
    }
}
extension Markdown.Link.Title: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        return PrettyTree(label: "Markdown.Link.Title", children: [
            .init(key: "openQuote", value: openQuote),
            .init(key: "content", value: content),
            .init(key: "closeQuote", value: closeQuote),
        ])
    }
}
