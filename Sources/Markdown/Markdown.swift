//
//  File.swift
//
//
//  Created by Colbyn Wadman on 4/1/24.
//
// The ASTs defined here are designed to support relatively lossless parsing
// and so it needs to embed all parsed tokens.
//!
// The types `Text` and `Token` are strings of what I call fat chars which are characters
// with original source code position information such that it can be used for
// highlighting.
//!
// For instance consider this (code from the old Rust codebase):
// ```rust
// #[derive(Debug, Clone)]
// pub struct Attribute {
//     pub key: AttributeItem,
//     pub eq: Token,
//     pub value: AttributeItem,
// }
// ```
// Most parsers would disregard the equal sign but we need can’t throw it away (for highlighting).
import Foundation
import Monado

public typealias Token = Tape
public typealias Text = Tape
public typealias OpenRoundBracket = Token
public typealias CloseRoundBracket = Token
public typealias OpenSquareBracket = Token
public typealias CloseSquareBracket = Token

public enum Markdown {
    case inline(Inline), block(Block)
}

public enum Inline {
    case plainText(PlainText)
    case link(Link)
    case image(Image)
    case emphasis(Emphasis)
    case highlight(Highlight)
    case strikethrough(Strikethrough)
    case sub(Subscript)
    case sup(Superscript)
    case inlineCode(InlineCode)
    case latex(Latex)
    case lineBreak(Token)
    case raw(Tape)
    public struct PlainText {
        public let value: Tape
    }
    public struct Link {
        public let text: InSquareBrackets<Text>
        public let openRoundBracket: OpenRoundBracket
        public let destination: Text
        public let title: InDoubleQuotes<Text>?
        public let closeRoundBracket: CloseRoundBracket
    }
    public struct Image {
        public let bang: Token
        public let altText: InSquareBrackets<Text>
        public let openRoundBracket: OpenRoundBracket
        public let src: Text
        public let title: InDoubleQuotes<Text>?
        public let closeRoundBracket: CloseRoundBracket
    }
    public struct Emphasis {
        /// Could be `*` or `_`, up to three repeating characters of such.
        public let startDelimiter: Token
        public let content: [Inline]
        public let endDelimiter: Token
    }
    public struct Highlight {
        /// Assuming `==` for start
        public let startDelimiter: Token
        public let content: [Inline]
        /// Assuming `==` for end
        public let endDelimiter: Token
    }
    public struct Strikethrough {
        /// Assuming `~~` for start
        public let startDelimiter: Token
        public let content: [Inline]
        /// Assuming `~~` for end
        public let endDelimiter: Token
    }
    public struct Subscript {
        /// Assuming `~` for start
        public let startDelimiter: Token
        public let content: [Inline]
        /// Assuming `~` for end
        public let endDelimiter: Token
    }
    public struct Superscript {
        /// Assuming `^` for start
        public let startDelimiter: Token
        public let content: [Inline]
        /// Assuming `^` for end
        public let endDelimiter: Token
    }
    public struct InlineCode {
        /// One or more backticks.
        public let startDelimiter: Token
        public let content: Tape
        /// One or more backticks; matching the `startDelimiter`.
        public let endDelimiter: Token
    }
    public struct InDoubleQuotes<Content> {
        public let openQuote: Token
        public let content: Content
        public let closeQuote: Token
    }
    public struct InSquareBrackets<Content> {
        public let openSquareBracket: OpenSquareBracket
        public let content: Content
        public let closeSquareBracket: CloseSquareBracket
        public func map<Result>(_ function: @escaping (Content) -> Result) -> InSquareBrackets<Result> {
            InSquareBrackets<Result>(openSquareBracket: openSquareBracket, content: function(content), closeSquareBracket: closeSquareBracket)
        }
    }
}

public enum Block {
    case heading(Heading)
    case paragraph(Paragraph)
    case blockquote(Blockquote)
    case list(List)
    case listItem(ListItem)
    case unorderedListItem(UnorderedListItem)
    case orderedListItem(OrderedListItem)
    case taskList(TaskList)
    case taskListItem(TaskListItem)
    case fencedCodeBlock(FencedCodeBlock)
    case horizontalRule(HorizontalRule)
    case table(Table)
    case newline(Tape.FatChar)
    public struct Heading {
        /// Markdown allows for 1-6 `#` characters for headings
        public let hashTokens: Token
        public let content: [ Inline ]
    }
    public struct Paragraph {
        /// A paragraph can contain multiple text elements
        public let content: [Inline]
    }
    public struct Blockquote {
        /// The `>` character used to denote blockquotes
        public let startDelimiter: Token
        /// Blockquotes can contain multiple other Markdown elements
        public let content: [ Markdown ]
    }
    public struct List {
        public let items: [ ListItem ]
    }
    public enum ListItem {
        case unordered(UnorderedListItem)
        case ordered(OrderedListItem)
    }
    public struct UnorderedListItem {
        /// Either `*`, `-`, `+`, or a number followed by `.`
        public let bullet: Token
        public let content: [ Markdown ]
    }
    public struct OrderedListItem {
        public let number: Token
        public let dot: Token
        public let content: [ Markdown ]
    }
    public struct TaskList {
        public let items: [ TaskListItem ]
    }
    public struct TaskListItem {
        /// Represents the `[ ]` or `[x]` for task list items
        public let header: Inline.InSquareBrackets<Token?>
        /// Task list items can contain multiple other Markdown elements
        public let content: [ Markdown ]
    }
    public struct FencedCodeBlock {
        /// The sequence of `` ` `` or `~` characters that start the block
        public let fenceStart: Token
        /// Optional language identifier for syntax highlighting
        public let infoString: Text?
        /// The actual code content
        public let content: Text
        /// The sequence of `` ` `` or `~` characters that end the block
        public let fenceEnd: Token
    }
    public struct HorizontalRule {
        /// The characters used to create a horizontal rule, e.g., `---`, `***`, `___`
        public let tokens: Token
    }
    public struct Table {
        public let header: Header
        public let data: [ Row ]
    }
}

extension Block.Table {
    public struct Header {
        public let header: Row
        public let separator: SeperatorRow
    }
    public struct SeperatorRow {
        /// Optionally, a table row might start with a delimiter if the table format specifies it.
        public let startDelimiter: Token.FatChar?
        /// The cells within the row.
        public let columns: [ Cell ]
        public struct Cell {
            public let startColon: Token.FatChar?
            public let dashes: Tape
            public let endColon: Token.FatChar?
            public let endDelimiter: Token.FatChar?
        }
    }
    public struct Row {
        /// Optionally, a table row might start with a delimiter if the table format specifies it.
        public let startDelimiter: Token.FatChar?
        /// The cells within the row.
        public let cells: [ Cell ]
        public struct Cell {
            /// Content of the cell. This could include inline formatting, links, etc.
            public let content: [Inline]
            /// Delimiter token to separate this cell from the next. This could be considered optional,
            /// as the last cell in a row might not have a trailing delimiter in some Markdown formats.
            public let pipeDelimiter: Token.FatChar?
        }
    }
}

public struct Latex {
    /// Either a single dollar sign (`$`) or double dollar signs (`$$`).
    public let start: Token
    /// The Tex/LaTeX literal content.
    public let content: Text
    /// Either a single dollar sign (`$`) or double dollar signs (`$$`).
    public let close: Token
}
