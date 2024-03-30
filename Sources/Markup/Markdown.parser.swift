//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation
import Monado

extension Markdown {
    public static func inlineElementParser(env: Environment) -> Parser<Self> {
        let p1 = Markdown.Emphasis
            .parser(env: env)
            .map(Markdown.emphasis)
        let p2 = Markdown.Link.parser(env: env).map(Markdown.link)
        let p3 = Markdown.InlineCode.parser(env: env).map(Markdown.inlineCode)
        return Parser.options([ p1, p2, p3 ])
    }
    public static func inlineParser(env: Environment) -> Parser<[Self]> {
        // INLINE ELEMENTS
        let p1 = inlineElementParser(env: env)
        // PLAIN TEXT
        let p2 = Markdown
            .plainTextParser(env: env)
            .map(Markdown.plainText)
            .or(Parser.skip(
                ifTrue: env.requiresSpecialInlineParsing,
                parser: Markdown.someSpecialCharParser(env: env)
            ))
        let parser = UnitParser
            .alternatingHomogeneousSequencesOf( f: p1, g: p2 )
        return parser.beforeAfterDebugLabels(before: "bgn:pp", after: "end:pp")
    }
    public static func blockParser(env: Environment) -> Parser<Self> {
        let p2 = Markdown.newlineParser
        let p1 = Markdown.FencedCodeBlock.parser(env: env).map(Markdown.fencedCodeBlock)
        let p3 = Markdown.Heading.parser(env: env).map(Markdown.heading)
        let p4 = Markdown.ListItem.parser(env: env).map(Markdown.listItem)
        let pl = Markdown.Paragraph.parser(env: env).map(Markdown.paragraph) // LAST PARSER
        return Parser<Self>.options([ p1, p2, p3, p4, pl ])
    }
    public static func plainTextParser(env: Environment) -> Parser<Text> {
        let tokenSet = env.avoidTheseInlineChars
        return Parser
            .char { !tokenSet.contains($0) && !$0.isNewline }
            .some
            .map { Tape(from: $0) }
    }
    public static func someSpecialCharParser(env: Environment) -> Parser<Self> {
        let tokenSet = env.avoidTheseInlineChars
        return CharParser
            .pop { tokenSet.contains($0) }
            .map(Tape.init(singleton:))
            .map(Markdown.plainText)
    }
    public static var newlineParser: Parser<Self> {
        CharParser.newline
            .map(Tape.init(singleton:))
            .map(Markdown.newline)
    }
}
extension Markdown.Paragraph {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        Markdown.inlineParser(env: .root).map(Markdown.Paragraph.init(content:))
    }
}
extension Markdown.Heading {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        Parser.options([
            Markdown.Heading.AtxHeading.parser(env: env).map(Markdown.Heading.atx),
        ])
    }
}
extension Markdown.Heading.AtxHeading {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let env = env.with(scope: .inlineHeader)
        let hashes = TapeParser.options([
            TapeParser.pop("######"),
            TapeParser.pop("#####"),
            TapeParser.pop("####"),
            TapeParser.pop("###"),
            TapeParser.pop("##"),
            TapeParser.pop("#"),
        ])
        let content = Markdown.inlineParser(env: env.with(scope: .inlineHeader))
        let id = Markdown.Heading.ID.parser(env: env).optional
        return Triple
            .joinParsers( f: hashes, g: content, h: id )
            .map {
                Markdown.Heading.AtxHeading(
                    hashes: $0.a,
                    content: $0.b,
                    id: $0.c
                )
            }
    }
}
extension Markdown.Heading.SetextHeading {
    public static var parser: Parser<Self> {
        fatalError("TODO")
    }
}
extension Markdown.Heading.ID {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let openCurlyBracket = TapeParser.pop("{")
        let content = Markdown.plainTextParser(env: env)
        let closeCurlyBracket = TapeParser.pop("}")
        return Triple
            .joinParsers( f: openCurlyBracket, g: content, h: closeCurlyBracket )
            .map {
                Markdown.Heading.ID(
                    openCurlyBracket: $0.a,
                    content: $0.b,
                    closeCurlyBracket: $0.c
                )
            }
    }
}
extension Markdown.Emphasis {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        if env.contains(scope: .inlineEmphasis) {
            return Parser<Self>.fail
        }
        let inner = Markdown
            .inlineParser(env: env.with(scope: .inlineEmphasis))
        let p1 = TapeParser.pop("***").and(inner.and(TapeParser.pop("***")))
        let p2 = TapeParser.pop("**").and(inner.and(TapeParser.pop("**")))
        let p3 = TapeParser.pop("*").and(inner.and(TapeParser.pop("*")))
        let parser = Parser
            .options([ p1, p2, p3 ])
            .map { Markdown.Emphasis( open: $0.a, content: $0.b.a, close: $0.b.b) }
        return parser.beforeAfterDebugLabels(before: "bgn:emphasis", after: "end:emphasis")
    }
}
extension Markdown.InlineCode {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let token = TapeParser.pop("`")
        let inner = CharParser.pop { $0 != "`" && !$0.isNewline }.many.map(Tape.init(from:))
        return inner.between(bothEnds: token).map {
            Self(open: $0.a, content: $0.b, close: $0.c)
        }
    }
}
extension Markdown.FencedCodeBlock {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let fence = TapeParser.pop("```")
        let language = CharParser
            .pop { $0.isLetter || $0.isNumber }
            .many
            .map(Tape.init(from:))
        let start = fence.and2(language.optional, CharParser.newline)
        let rest = CharParser.next.manyUntilEnd(terminator: fence).map {
            (Tape(from: $0.a), $0.b)
        }
        let parser = Tuple.joinParsers(f: start, g: rest).map {
            Self(
                open: $0.a.a,
                language: $0.a.b,
                content: $0.b.0,
                close: $0.b.1
            )
        }
        return parser
    }
}
extension Markdown.ListItem {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let p1 = Markdown.ListItem.Ordered.parser(env: env).map(Markdown.ListItem.ordered)
        let p2 = Markdown.ListItem.Task.parser(env: env).map(Markdown.ListItem.task)
        let p3 = Markdown.ListItem.Unordered.parser(env: env).map(Markdown.ListItem.unordered)
        return Parser<Self>.options([ p1, p2, p3 ])
    }
    fileprivate static func restOfLineContentParser(env: Markdown.Environment) -> Parser<[Markdown]> {
        UnitParser
            .fork( extract: TapeParser.restOfLine, execute: Markdown.inlineParser(env: env) )
            .map { (content, unparsed) in
                let content = content ?? []
                if unparsed.isEmpty {
                    return content
                }
                return content.with(append: Markdown.raw(unparsed.tape))
            }
    }
}
extension Markdown.ListItem.Unordered {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let env = env.with(scope: .inlineList)
        let allowedTokens = Set<Character>([ "*", "-", "+" ])
        let leading = TapeParser.whitespace
        let token = CharParser
            .pop { allowedTokens.contains($0) }
            .map(Tape.init(singleton:))
        let content = Markdown.ListItem.restOfLineContentParser(env: env)
        return Triple
            .joinParsers(f: leading, g: token, h: content)
            .map { Self(leadingSpace: $0.a, itemToken: $0.b, content: $0.c) }
    }
}
extension Markdown.ListItem.Ordered {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let env = env.with(scope: .inlineList)
        let leading = TapeParser.whitespace
        let symbol = CharParser
            .pop { $0.isLetter || $0.isNumber }
            .some
            .map(Tape.init(from:))
        let dot = CharParser.pop(".").map(Tape.init(singleton:))
        let content = Markdown.ListItem.restOfLineContentParser(env: env)
        let components = Quadruple.joinParsers(
            f: leading,
            g: symbol,
            h: dot,
            i: content
        )
        let parser = components.map {
            Self(leadingSpace: $0.a, symbol: $0.b, dot: $0.c, content: $0.d)
        }
        return parser
    }
}
extension Markdown.ListItem.Task {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let env = env.with(scope: .inlineList)
        let leading = TapeParser.whitespace
        let token = CharParser
            .pop("-")
            .map(Tape.init(singleton:))
        let box = Markdown.ListItem.Task.Box.parser(env: env)
        let content = Markdown.ListItem.restOfLineContentParser(env: env)
        let components = Quadruple.joinParsers(
            f: leading,
            g: token,
            h: box,
            i: content
        )
        let parser = components.map { Self(leadingSpace: $0.a, dash: $0.b, box: $0.c, content: $0.d) }
        return parser
    }
}
extension Markdown.ListItem.Task.Box {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let openSquareBracket = CharParser.pop("[")
            .map(Tape.init(singleton:))
        let allowedContent = CharParser.pop {
            let char = $0.lowercased()
            return char == "x" || char == "-" || char == " "
        }
        let content = allowedContent.map(Tape.init(singleton:))
        let closeSquareBracket = CharParser.pop("]")
            .map(Tape.init(singleton:))
        return Triple
            .joinParsers(f: openSquareBracket, g: content, h: closeSquareBracket)
            .map { Self(openSquareBracket: $0.a, content: $0.b, closeSquareBracket: $0.c) }
    }
}
extension Markdown.Link {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        if env.contains(scope: .inlineLink) {
            return Parser<Self>.fail
        }
        let p1 = Markdown.Link.Image.parser(env: env).map(Markdown.Link.image)
        let p2 = Markdown.Link.HyperText.parser(env: env).map(Markdown.Link.hyperText)
        return Parser<Self>
            .options([ p1, p2 ])
            .beforeAfterDebugLabels(before: "bgn:link", after: "end:link")
    }
}
extension Markdown.Link.HyperText {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let text = Markdown.Link.SquareBracketEnclosure.parser(env: env)
        let url = Markdown.Link.RoundBracketEnclosure.parser(env: env)
        let parser = text.and(url).map {
            Markdown.Link.HyperText(text: $0.a, url: $0.b)
        }
        return parser
    }
}
extension Markdown.Link.Image {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let imagePrefix = CharParser.pop("!").map(Tape.init(singleton:))
        let text = Markdown.Link.SquareBracketEnclosure.parser(env: env)
        let url = Markdown.Link.RoundBracketEnclosure.parser(env: env)
        let parser = imagePrefix.and2(text, url).map {
            Markdown.Link.Image(imagePrefix: $0.a, text: $0.b, url: $0.c)
        }
        return parser
    }
}
extension Markdown.Link.SquareBracketEnclosure {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let textOpenBracket = TapeParser.pop("[")
        let text = Markdown.inlineParser(env: env.with(scope: .inlineLink))
        let textCloseBracket = TapeParser.pop("]")
        let parser = textOpenBracket.and2(text, textCloseBracket).map {
            Markdown.Link.SquareBracketEnclosure(textOpenBracket: $0.a, text: $0.b, textCloseBracket: $0.c)
        }
        return parser
    }
}
extension Markdown.Link.RoundBracketEnclosure {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let urlOpenBracket = CharParser.pop("(").map(Tape.init(singleton:))
        let urlText = Markdown.plainTextParser(env: env.with(scope: .inlineLink))
        let title = Markdown.Link.Title.parser(env: env.with(scope: .inlineLink)).optional
        let urlCloseBracket = CharParser.pop(")").map(Tape.init(singleton:))
        let parser = urlOpenBracket.and3(urlText, title, urlCloseBracket).map {
            Markdown.Link.RoundBracketEnclosure(urlOpenBracket: $0.a, url: $0.b, title: $0.c, urlCloseBracket: $0.d)
        }
        return parser
    }
}
extension Markdown.Link.Title {
    public static func parser(env: Markdown.Environment) -> Parser<Self> {
        let openQuote = CharParser.pop("\"").map(Tape.init(singleton:))
        let text = Markdown.plainTextParser(env: env.with(scope: .inlineString))
        let closeQuote = CharParser.pop("\"").map(Tape.init(singleton:))
        let parser = openQuote.and2(text, closeQuote).map {
            Markdown.Link.Title(openQuote: $0.a, content: $0.b, closeQuote: $0.c)
        }
        return parser
    }
}


