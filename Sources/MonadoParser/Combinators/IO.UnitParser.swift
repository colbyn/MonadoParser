//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/6/24.
//

import Foundation

extension IO.UnitParser {
    public static let unit = IO.UnitParser.pure(value: .unit)
}

extension IO.UnitParser {
    public static func lines(
        lineStart: @escaping @autoclosure () -> IO.TextParser,
        terminator: @escaping @autoclosure () -> IO.ControlFlowParser = IO.ControlFlowParser.noop,
        trim: Bool = true
    ) -> IO.Parser<IO.Lines<IO.Text, IO.Text>> {
        let parser = IO.Parser<IO.Lines<IO.Text, IO.Text>> {
            var current = $0
            var results: [IO.Text.FatChar] = []
            var lineGuard: IO.Text.PositionIndex? = nil
            var terminate = false
            var lineStarts: [IO.Text] = []
            // - -
            let remainingLine = IO.TextParser.restOfLine.optional.and(next: IO.CharParser.newline.optional).map {
                return IO.Text.init(
                    from: ($0.a?.chars ?? []).with(append: $0.b.map{[$0]} ?? [])
                )
            }
            // - -
            loop: while !current.text.isEmpty && !terminate {
                if case .continue(value: .terminate, state: let rest) = terminator().binder(current) {
                    return rest.continue(
                        value: IO.Lines(lineStarts: lineStarts, content: IO.Text(from: results))
                    )
                }
                // - -
                switch lineStart().and(next: remainingLine).binder(current) {
                case .continue(value: let output, state: let rest):
                    let leading = output.a.chars
                    let trailing = output.b.chars
                    let line = leading.with(append: trailing)
                    // - -
                    if leading.isEmpty {
                        break loop
                    }
                    // - -
                    if let lineGuard = lineGuard, let last = leading.last {
                        let isValid = last.index.column == lineGuard.column
                        terminate = !isValid
                    } else {
                        lineGuard = leading.last?.index
                    }
                    // - -
                    if !terminate {
                        results.append(contentsOf: trim ? trailing : line)
                        lineStarts.append(output.a)
                        current = rest
                    }
                case .break: break loop
                }
            }
            // - -
            if results.isEmpty {
                return $0.break()
            }
            // - -
            return current.continue(
                value: IO.Lines(lineStarts: lineStarts, content: IO.Text(from: results))
            )
        }
        let cleanup: (IO.Text) -> IO.TextParser = {
            let (leading, trailing) = $0.trimTrailing(includeNewlines: true).native
            return IO.UnitParser.unit
                .set(pure: leading) // RETURN ALL TEXT NOT INCLUDING TRAILING WHITESPACE
                .putBack(text: trailing) // PUT ANY TRAILING WHITESPACE BACK INTO THE UNPARSED STREAM
        }
        return parser.andThen {
            let lineStarts = $0.lineStarts
            return cleanup($0.content).map {
                return IO.Lines(lineStarts: lineStarts, content: $0)
            }
        }
    }
}
