//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/2/24.
//

import Foundation
import Monado
import PrettyTree
import ExtraMonadoUtils

// MARK: - INLINE PARSERS -
extension Inline {
    public static func many(env: Environment) -> Parser<[Self]> {
        fatalError("TODO")
    }
    public static func some(env: Environment) -> Parser<[Self]> {
        fatalError("TODO")
    }
    public static func parser(env: Environment) -> Parser<Self> {
        fatalError("TODO")
    }
    public static func textParser(env: Environment) -> Parser<Text> {
        let env = env.withScope(inline: .plainText)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var lineBreak: Parser<Self> {
        CharParser.newline
            .map(Tape.init(singleton:))
            .map(Inline.lineBreak)
    }
}
extension Inline.PlainText {
    public static func parser(env: Environment) -> Parser<Self> {
        Inline
            .textParser(env: env.withScope(inline: .plainText))
            .map(Inline.PlainText.init(value:))
    }
}
extension Inline.Link {
    public static func parser(env: Environment) -> Parser<Self> {
        let textParser = Inline.InSquareBrackets
            .parser(
                content: Inline.textParser(env: env.withScope(inline: .link(.inSquareBraces)))
            )
        let openRoundBracket = CharParser.pop("(").map(Tape.init(singleton:))
        let destination = Inline.textParser(env: env.withScope(inline: .link(.inRoundBraces)))
        let title = Inline.InDoubleQuotes
            .parser(
                content: Inline.textParser(env: env.withScope(.string))
            )
            .optional
        let closeRoundBracket = CharParser.pop(")").map(Tape.init(singleton:))
        let urlParser = Quadruple.joinParsers(f: openRoundBracket, g: destination, h: title, i: closeRoundBracket)
        let parser = textParser.and(urlParser).map {
            Self(
                text: $0.a,
                openRoundBracket: $0.b.a,
                destination: $0.b.b,
                title: $0.b.c,
                closeRoundBracket: $0.b.d
            )
        }
        return parser
    }
}
extension Inline.Image {
    public static func parser(env: Environment) -> Parser<Self> {
        let bang = CharParser.pop("!").map(Tape.init(singleton:))
        let rest = Inline.Link.parser(env: env.withScope(inline: .image))
        let parser = bang.and(rest).map {
            Self(
                bang: $0.a,
                altText: $0.b.text,
                openRoundBracket: $0.b.openRoundBracket,
                src: $0.b.destination,
                title: $0.b.title,
                closeRoundBracket: $0.b.closeRoundBracket
            )
        }
        return parser
    }
}
extension Inline.Emphasis {
    public static func parser(env: Environment) -> Parser<Self> {
        let pack: (Environment.Scope.Inline.EmphasisType) -> Parser<Self> = { type in
            let env = env.withScope(inline: .emphasis(type))
            let content = Inline.many(env: env)
            let parser = content
                .between(bothEnds: TapeParser.pop(type.asString))
                .map {
                    Self(startDelimiter: $0.a, content: $0.b, endDelimiter: $0.c)
                }
            return parser
        }
        return Parser.options([
            pack(.triple("*")), // `***`
            pack(.double("*")), // `**`
            pack(.single("*")), // `*`
            pack(.triple("_")), // `___`
            pack(.double("_")), // `__`
            pack(.single("_")), // `_`
        ])
    }
}
extension Inline.Highlight {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(inline: .highlight)
        let content = Inline.many(env: env)
        return content
            .between(bothEnds: TapeParser.pop("=="))
            .map {
                Self(startDelimiter: $0.a, content: $0.b, endDelimiter: $0.c)
            }
    }
}
extension Inline.Strikethrough {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(inline: .strikethrough)
        let content = Inline.many(env: env)
        return content
            .between(bothEnds: TapeParser.pop("~~"))
            .map {
                Self(startDelimiter: $0.a, content: $0.b, endDelimiter: $0.c)
            }
    }
}
extension Inline.Subscript {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(inline: .sub)
        let content = Inline.many(env: env)
        return content
            .between(bothEnds: TapeParser.pop("~"))
            .map {
                Self(startDelimiter: $0.a, content: $0.b, endDelimiter: $0.c)
            }
    }
}
extension Inline.Superscript {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(inline: .sup)
        let content = Inline.many(env: env)
        return content
            .between(bothEnds: TapeParser.pop("^"))
            .map {
                Self(startDelimiter: $0.a, content: $0.b, endDelimiter: $0.c)
            }
    }
}
extension Inline.InlineCode {
    public static func parser(env: Environment) -> Parser<Self> {
        let start = CharParser.pop("`").some.map(Tape.init(from:))
        let parser: Parser<Self> = start.andThen { start in
            let end = TapeParser.pop(start.asString)
            let content = TapeParser.manyUntilTerm(terminator: end)
            let parser = content.map {
                Self(startDelimiter: start, content: $0.a, endDelimiter: $0.b)
            }
            return parser
        }
        return parser
    }
}
// MARK: - BLOCK PARSERS -
extension Block.Heading {
    public static func parser(env: Environment) -> Parser<Self> {
        let hashTokens = TapeParser.options([
            TapeParser.pop("######"),
            TapeParser.pop("#####"),
            TapeParser.pop("####"),
            TapeParser.pop("###"),
            TapeParser.pop("##"),
            TapeParser.pop("#"),
        ])
        let env = env.withScope(block: .heading)
        let content = Inline.many(env: env)
        let parser = Tuple.joinParsers(f: hashTokens, g: content).map {
            Self(hashTokens: $0.a, content: $0.b)
        }
        return parser
    }
}
extension Block.Paragraph {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .paragraph)
        let parser = Inline.some(env: env).map(Block.Paragraph.init(content:))
        return parser
    }
    public static var wholeChunk: TapeParser {
        // This parser attempts to consume everything up to a blank line (two newline characters in sequence)
        // or the end of input. It should capture the paragraph content directly as a Tape.
        
        // Define a parser that consumes any character that is not a newline,
        // effectively consuming non-empty lines.
        let nonNewlineChar = CharParser.pop { $0 != "\n" }
        
        // A parser for newline characters to help identify blank lines or paragraph breaks.
        let newline = CharParser.pop("\n")
        
        // Parser for non-empty lines, capturing content until a newline character.
        let nonEmptyLine = nonNewlineChar.many.map(Tape.init(from:)).and(newline).map { $0.a }
        
        // Parser that captures a sequence of non-empty lines until a blank line (two consecutive newlines)
        // or the end of input is reached.
        let paragraphContent = nonEmptyLine
            .someUnless( terminator: TapeParser.pop("\n\n") )
            .andThen {
                let output = Tape(flatten: $0.a)
                return UnitParser.unit
                    .set(pure: output)
                    .putBack(tape: $0.b)
            }
        
        return paragraphContent
    }
}
extension Block.Blockquote {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .blockquote)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var wholeChunk: TapeParser {
        Self.leader.andThen { start in
            let terminal = TapeParser.pop("\n\n")
            let consumer = CharParser
                .unconsIf {
                    if $0.index.column == start.a.index.column {
                        return $0.value == ">"
                    }
                    if $0.index.column > start.a.index.column {
                        return true
                    }
                    return false
                }
            let parser = consumer
                .manyUnless(terminator: terminal)
                .andThen {
                    UnitParser.unit.putBack(tape: $0.b).set(pure: $0.a)
                }
                .map(Tape.init(from:))
            return parser
        }
    }
    public static var leader: TupleParser<Tape.FatChar, Tape.FatChar> {
        return CharParser.pop(">").and(CharParser.space)
    }
}
extension Block.List {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .list)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}
extension Block.ListItem {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .listItem)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}
extension Block.UnorderedListItem {
    public static func parser(env: Environment) -> Parser<Self> {
//        let env = env.withScope(block: .unorderedListItem)
//        let bullet = Self.bullet
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var wholeChunk: TapeParser {
        Self.bullet.andThen { start in
            CharParser
                .unconsIf {
                    let check1 = $0.value.isWhitespace
                    let check2 = $0.index.column > start.b.index.column
                    return (check1 || check2) // any whitespace or indented chars
                }
                .some
                .map(Tape.init(from:))
                .map { start.a.singleton.with(append: start.b).with(append: $0) }
        }
    }
    public static var bullet: TupleParser<Tape.FatChar, Tape.FatChar> {
        TupleParser<Tape.FatChar, Tape.FatChar>.options([
            CharParser.pop("*").and(CharParser.space),
            CharParser.pop("-").and(CharParser.space),
            CharParser.pop("+").and(CharParser.space),
        ])
    }
}
extension Block.OrderedListItem {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .orderedListItem)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var wholeChunk: TapeParser {
        Self.leader.andThen { start in
            CharParser
                .unconsIf {
                    let check1 = $0.value.isWhitespace
                    let check2 = $0.index.column > start.b.index.column + 1
                    return (check1 || check2) // any whitespace or indented chars
                }
                .some
                .map(Tape.init(from:))
                .map { start.a.with(append: start.b).with(append: start.c).with(append: $0) }
        }
    }
    public static var leader: TripleParser<Text, Text.FatChar, Text.FatChar> {
        return Triple.joinParsers(
            f: CharParser.number.some.map(Tape.init(from:)),
            g: CharParser.pop { $0 == "." },
            h: CharParser.space
        )
    }
}
extension Block.TaskList {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .taskList)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}
extension Block.TaskListItem {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .taskListItem)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var wholeChunk: TapeParser {
        fatalError("TODO")
    }
}
extension Block.FencedCodeBlock {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .fencedCodeBlock)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}
extension Block.HorizontalRule {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .horizontalRule)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}
extension Block.Table {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .table)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var wholeChunk: TapeParser {
        fatalError("TODO")
    }
}
extension Block.TableRow {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .tableRow)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}
extension Block.TableCell {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .tableCell)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
}

extension Latex {
    public static func parser(env: Environment) -> Parser<Self> {
//        let env = env.withScope(block: .latex)
//        fatalError("TODO: \(env.asPrettyTree.format())")
        fatalError("TODO")
    }
}

// TODO:
 extension Inline.InDoubleQuotes {
     public static func parser(content: @autoclosure @escaping () -> Parser<Content>) -> Parser<Self> {
         let token = CharParser.pop("\"").map(Tape.init(singleton:))
         return token.and2(content(), token).map { Self(openQuote: $0.a, content: $0.b, closeQuote: $0.c) }
     }
 }
 extension Inline.InSquareBrackets {
     public static func parser(content: @autoclosure @escaping () -> Parser<Content>) -> Parser<Self> {
         let start = CharParser.pop("[").map(Tape.init(singleton:))
         let end = CharParser.pop("[").map(Tape.init(singleton:))
         return start.and2(content(), end).map { Self(openSquareBracket: $0.a, content: $0.b, closeSquareBracket: $0.c) }
     }
 }
