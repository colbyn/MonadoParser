//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/27/24.
//

import Foundation
import Monado

public indirect enum Markdown {
    case plainText(Text)
    case newline(Token)
    case raw(Tape)
    case paragraph(Paragraph)
    case emphasis(Emphasis)
    case heading(Heading)
    case listItem(ListItem)
    case link(Link)
    case inlineCode(InlineCode)
    case fencedCodeBlock(Markdown.FencedCodeBlock)
    public init(char: Tape.Char) {
        self = .plainText(Text(singleton: char))
    }
}

extension Markdown {
    public typealias Token = Tape
    public typealias Text = Tape
    /// A `(` token.
    public typealias OpenRoundBracket = Token
    /// A `)` token.
    public typealias CloseRoundBracket = Token
    /// A `[` token.
    public typealias OpenSquareBracket = Token
    /// A `]` token.
    public typealias CloseSquareBracket = Token
    /// A `{` token.
    public typealias OpenCurlyBracket = Token
    /// A `}` token.
    public typealias CloseCurlyBracket = Token
    /// A `<` token.
    public typealias OpenAngleBracket = Token
    /// A `>` token.
    public typealias CloseAngleBracket = Token
    public typealias Whitespace = Token
}

extension Markdown {
    public static let allInlineSymbols: Set<Character> = Set.flatten(sets: [
        Self.inlineEmphasisTokens,
        Self.inlineLinkTokens,
        Self.inlineCodeTokens,
    ])
    public static let inlineEmphasisTokens: Set<Character> = [
        "*",
        "_",
    ]
    public static let inlineLinkTokens: Set<Character> = [
        "[",
        "]",
        "(",
        ")",
    ]
    public static let inlineCodeTokens: Set<Character> = [
        "`",
    ]
    public struct Paragraph {
        let content: [ Markdown ]
        public init(content: [Markdown]) {
            self.content = content
        }
    }
    public struct Emphasis {
        let open: Token
        let content: [Markdown]
        let close: Token
    }
    public struct InlineCode {
        let open: Token
        let content: Text
        let close: Token
    }
    public struct FencedCodeBlock {
        let open: Token
        let language: Text?
        let content: Text
        let close: Token
    }
    public struct Fragment {
        let items: [ Markdown ]
        fileprivate init(_ items: [Markdown]) {
            self.items = items
        }
    }
    public enum Heading {
        case atx(AtxHeading)
        /// "Setext" stands for "Structure Enhanced Text," and it is a plain text markup language that predates Markdown.
        case setext(SetextHeading)
        public struct AtxHeading {
            let hashes: Token
            let content: [ Markdown ]
            let id: ID?
        }
        public struct SetextHeading {
            let leadingSpace: Whitespace
            let content: [Markdown]
            /// This could represent either the `===` or `---` underline.
            let underline: Token
            let id: ID?
        }
        public struct ID {
            let openCurlyBracket: OpenCurlyBracket
            let content: Text
            let closeCurlyBracket: CloseCurlyBracket
        }
    }
    public enum ListItem {
        case unordered(Unordered)
        case ordered(Ordered)
        case task(Task)
        public struct Unordered {
            let leadingSpace: Whitespace
            /// May be a `-`, `*` or `+`.
            let itemToken: Token
            let content: [Markdown]
        }
        public struct Ordered {
            let leadingSpace: Whitespace
            /// Numbers or whatnot.
            let symbol: Token
            let dot: Token
            let content: [Markdown]
        }
        public struct Task {
            let leadingSpace: Whitespace
            let dash: Token
            let box: Box
            let content: [Markdown]
            public struct Box {
                let openSquareBracket: OpenSquareBracket
                let content: Token
                let closeSquareBracket: CloseSquareBracket
            }
        }
    }
    public enum Link {
        case hyperText(HyperText)
        case image(Image)
        public struct HyperText {
            let text: SquareBracketEnclosure
            let url: RoundBracketEnclosure
        }
        public struct Image {
            let imagePrefix: Token
            let text: SquareBracketEnclosure
            let url: RoundBracketEnclosure
        }
        public struct SquareBracketEnclosure {
            let textOpenBracket: OpenSquareBracket
            let text: [Markdown]
            let textCloseBracket: CloseSquareBracket
        }
        public struct RoundBracketEnclosure {
            let urlOpenBracket: OpenRoundBracket
            let url: Text
            /// Optional title token. It's included only if a title is provided in the markdown.
            let title: Title?
            let urlCloseBracket: CloseRoundBracket
        }
        public struct Title {
            let openQuote: Token
            let content: Text
            let closeQuote: Token
        }
    }
}
