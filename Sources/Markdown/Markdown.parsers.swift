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
            let content = TapeParser.consumeManyUntilTerm(terminator: end)
            let parser = content.map {
                Self(startDelimiter: start, content: $0.a, endDelimiter: $0.b)
            }
            return parser
        }
        return parser
    }
}
// MARK: - BLOCK PARSERS -
extension Block {
    public static func parser(env: Environment) -> Parser<Self> {
        fatalError("TODO")
    }
}
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
        let body = CharParser.next
            .notFollowedBy(TapeParser.pop("\n\n"))
            .some
            .map(Tape.init(from:))
        let rest = CharParser
            .pop { !$0.isNewline }
            .many
            .map(Tape.init(from:))
        return Tuple
            .joinParsers(f: body, g: rest)
            .map { Tape(flatten: [$0.a, $0.b]) }
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
        Parser.options([
            Block.UnorderedListItem.parser(env: env).map(Self.unordered),
            Block.OrderedListItem.parser(env: env).map(Self.ordered),
        ])
    }
}
extension Block.UnorderedListItem {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .unorderedListItem)
//        let leader = Self.bullet
//        let main = UnitParser.bounded(
//            extract: TapeParser.wholeIndentedBlock,
//            execute: <#T##Parser<T>#>
//        )
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
    public static var bullet: TupleParser<Tape.FatChar, Tape.FatChar> {
        let options = Parser.options([
            CharParser.pop("*"),
            CharParser.pop("-"),
            CharParser.pop("+"),
        ])
        return options.and(CharParser.space)
    }
}
extension Block.OrderedListItem {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .orderedListItem)
        fatalError("TODO: \(env.asPrettyTree.format())")
    }
//    public static var wholeChunk: TapeParser {
//        Self.leader.and(TapeParser.wholeIndentedBlock).map {
//            Tape(
//                from: $0.a.a.flatten
//                    .with(append: $0.a.b)
//                    .with(append: $0.a.c)
//                    .with(append: $0.b.flatten)
//            )
//        }
//    }
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
//    public static var wholeChunk: TupleParser<Tuple<Inline.InSquareBrackets<Tape?>, Tape.FatChar>, Tape> {
//        Self.leader.and(TapeParser.wholeIndentedBlock)
//    }
    public static var leader: TupleParser<Inline.InSquareBrackets<Tape?>, Tape.FatChar> {
        let inner = Parser.options([
            CharParser.pop("x").spaced,
            CharParser.pop("X").spaced,
        ])
        let parser = Tuple.joinParsers(
            f: Inline.InSquareBrackets
                .parser(content: inner.optional)
                .map { $0.map({$0.map(Tape.init(singleton:))}) },
            g: CharParser.space
        )
        return parser
    }
}
extension Block.FencedCodeBlock {
    public static func parser(env: Environment) -> Parser<Self> {
        let fence = TapeParser.pop("```")
        let parser = fence.and2(TapeParser.restOfLine.optional, CharParser.next.manyUntilEnd(terminator: fence)).map {
            Self(fenceStart: $0.a, infoString: $0.b, content: Tape(from: $0.c.a), fenceEnd: $0.c.b)
        }
        return parser
    }
}
extension Block.HorizontalRule {
    public static func parser(env: Environment) -> Parser<Self> {
        let options = Parser.options([
            TapeParser.pop("***").and(CharParser.pop("*").many),
            TapeParser.pop("---").and(CharParser.pop("-").many),
            TapeParser.pop("___").and(CharParser.pop("_").many)
        ])
        let parser = options
            .map {
                $0.a.with(append: Tape(from: $0.b))
            }
            .map(Self.init(tokens:))
        return parser
    }
}
extension Block.Table {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .table)
        let header = Block.Table.Header.parser(env: env)
        let body = Block.Table.Row.parser(env: env).many
        let parser = Tuple.joinParsers(f: header, g: body).map {
            Self(header: $0.a, data: $0.b)
        }
        return parser
    }
}
extension Block.Table.Header {
    public static func parser(env: Environment) -> Parser<Self> {
        let env = env.withScope(block: .table)
        let header = Block.Table.Row.parser(env: env)
        let separator = Block.Table.SeperatorRow.parser(env: env)
        let parser = Tuple.joinParsers( f: header, g: separator ).map {
            Self(header: $0.a, separator: $0.b)
        }
        return parser
    }
}
extension Block.Table.SeperatorRow {
    public static func parser(env: Environment) -> Parser<Self> {
        let pipe = CharParser.pop("|")
        let colon = CharParser.pop(":")
        let dashes = TapeParser
            .pop("---")
            .and(CharParser.char("-").many)
            .map {
                $0.a.with(append: Tape.init(from: $0.b))
            }
            .spaced
        let seperator = Triple
            .joinParsers(
                f: colon.optional,
                g: dashes,
                h: colon.optional
            )
            .spaced
        let parser = UnitParser.bounded(
            extract: TapeParser.restOfLine.ignoring(CharParser.newline.optional),
            execute: pipe.optional.and(seperator.someSeperatedBy(separator: pipe)).map { row in
                let cells = row.b.flatMap { column in
                    column.content.map {
                        Block.Table.SeperatorRow.Cell(
                            startColon: $0.a,
                            dashes: $0.b,
                            endColon: $0.c,
                            endDelimiter: column.separator
                        )
                    }
                }
                return Self(
                    startDelimiter: row.a,
                    columns: cells
                )
            }
        )
        return parser
    }
}
extension Block.Table.Row {
    public static func parser(env: Environment) -> Parser<Self> {
        let pipe = CharParser.pop("|")
        let extractor = TapeParser.restOfLine.ignoring(CharParser.newline.optional)
        let subparser = pipe.optional.and(CharParser.pop { $0 != "|" }.manySeperatedBy(separator: pipe.spaced.optional)).map { row in
            let cells = row.b.map {
                let content = [ Inline.raw(Tape(from: $0.content)) ]
                return Block.Table.Row.Cell(content: content, pipeDelimiter: $0.separator ?? nil)
            }
            return Self(startDelimiter: row.a, cells: cells)
        }
        let parser = UnitParser.bounded(
            extract: extractor,
            execute: subparser
        )
        return parser
    }
}

extension Latex {
    public static func parser(env: Environment) -> Parser<Self> {
//        fatalError("TODO: \(env.asPrettyTree.format())")
        fatalError("TODO")
    }
}

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
