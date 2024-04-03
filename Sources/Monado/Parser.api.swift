//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation

// MARK: - ROOT EVALUATION ENTRYPOINT -
extension Parser {
    /// Evaluates the parser against a given source string, producing either a parsed value or nil if parsing fails, along with the final parser state.
    ///
    /// - Parameters:
    ///   - source: The input string to be parsed.
    /// - Returns: A tuple containing the optional parsed value and the final state of the parser.
    ///
    /// Example:
    /// ```swift
    /// let parser = Parser<Int>.pure(value: 42)
    /// let result = parser.evaluate(source: "input string")
    /// print(result) // Prints "(Optional(42), ParserState(...))"
    /// ```
    public func evaluate(source: String) -> (A?, ParserState) {
        let state = ParserState.root(tape: Tape(from: source))
        switch self.binder(state) {
        case .ok(value: let a, state: let state): return (a, state)
        case .err(state: let state): return (nil, state)
            
        }
    }
}

extension UnitParser {
    /// Creates a parser that forks the parsing process by applying a subparser to a predetermined segment of input, allowing for independent parsing of embedded content without altering the original parsing state.
    ///
    /// This approach is particularly useful for parsing embedded structures or content within a larger text that should be handled separately, such as comments, metadata, or specialized data formats embedded within a general stream. It enables isolated parsing of a segment with a different parser, preserving the main parsing context.
    ///
    /// - Parameters:
    ///   - pure input: A predefined segment (`Tape`) that the subparser will process.
    ///   - subparser: The parser to apply to the specified input segment.
    /// - Returns: A parser that returns the result of the subparser, encapsulating success or failure, alongside the state after subparser execution, without affecting the original parser's state.
    ///
    /// Example:
    /// ```swift
    /// // Parsing embedded JSON within a larger text stream.
    /// let jsonSegment = Tape(from: "{\"key\": \"value\"}")
    /// let jsonParser = Parser<JSON>.parseJSON // Hypothetical parser for JSON content.
    /// let forkedJSONParser = UnitParser.fork(pure: jsonSegment, subparser: jsonParser)
    /// // This setup isolates the JSON parsing from the main text stream, enabling embedded JSON parsing.
    /// ```
    public static func forkFor<T>(pure input: Tape, subparser: @autoclosure @escaping () -> Parser<T>) -> Parser<(T?, ParserState)> {
        Parser<(T?, ParserState)> { original in
            let forked = ParserState(tape: input, debugScopes: [])
            switch subparser().binder(forked) {
            case .ok(value: let t, state: let state):
                return original.ok(value: (t, state))
            case .err(state: let state):
                return original.ok(value: (nil, state))
            }
        }
    }
    /// Executes a subparser on an input segment extracted by another parser, allowing for conditional parsing of embedded content without advancing the main parser's state. Ideal for scenarios where embedded content needs to be parsed differently or can potentially break parsing if treated as part of the main stream.
    ///
    /// This function first uses an extraction parser to identify and extract a segment of interest. If extraction succeeds, the specified subparser is then applied to this segment. This mechanism supports complex parsing scenarios, such as nested structures or conditionally formatted data, by enabling detailed examination and separate handling of specific content sections.
    ///
    /// - Parameters:
    ///   - extract: A `TapeParser` that identifies and extracts the segment of interest.
    ///   - execute: The subparser to be applied to the extracted input.
    /// - Returns: A parser that returns the result of the subparser based on the extracted input, alongside the main parser's unmodified state.
    ///
    /// Example:
    /// ```swift
    /// // Parsing a log file where certain lines contain JSON that requires special handling.
    /// let lineParser = TapeParser.restOfLine
    /// let jsonParser = Parser<JSON>.parseJSON // Hypothetical JSON parser.
    /// let logFileParser = UnitParser.fork(
    ///     extract: lineParser,
    ///     execute: jsonParser
    /// )
    /// // This configuration allows each line to be checked for JSON content and parsed accordingly, isolating JSON parsing from general line parsing.
    /// ```
    public static func forkFor<T>(
        extract: @escaping @autoclosure () -> TapeParser,
        execute subparser: @escaping @autoclosure () -> Parser<T>
    ) -> Parser<(T?, ParserState)> {
        Parser<(T?, ParserState)> {
            switch extract().binder($0) {
            case .ok(value: let input, state: let global):
                let forked = ParserState(tape: input, debugScopes: [])
                switch subparser().binder(forked) {
                case .ok(value: let t, state: let embeded):
                    return global.ok(value: (t, embeded))
                case .err(state: let embeded):
                    return global.ok(value: (nil, embeded))
                }
            case .err(state: let state): return state.err()
            }
        }
    }
}

// MARK: - GENERAL PARSER -
extension Parser {
    /// Creates a parser that always succeeds with the given value, without consuming any input.
    ///
    /// - Parameter value: The value that the parser will return upon evaluation.
    /// - Returns: A parser that always returns the provided value.
    ///
    /// Example:
    /// ```swift
    /// let always42 = Parser<Int>.pure(value: 42)
    /// ```
    public static func pure(value: A) -> Self {
        Self { $0.ok(value: value) }
    }
    
    /// Creates a parser that always fails.
    ///
    /// - Returns: A parser that always fails without consuming any input.
    ///
    /// Example:
    /// ```swift
    /// let failParser = Parser<String>.fail
    /// ```
    public static var fail: Self {
        Self { $0.err() }
    }
    
    /// Attempts to parse using each parser in the provided array, in order, stopping at the first success.
    ///
    /// - Parameter parsers: An array of parsers to be tried sequentially until one succeeds.
    /// - Returns: A parser that succeeds if any of the provided parsers succeed.
    ///
    /// Example:
    /// ```swift
    /// let parser = Parser<String>.options([
    ///     Parser<String>.token("Hello"),
    ///     Parser<String>.token("World")
    /// ])
    /// ```
    public static func options(_ parsers: @escaping @autoclosure () -> [Self]) -> Self {
        return Self {
            for p in parsers() {
                switch p.binder($0) {
                case .ok(value: let a, state: let o): return o.ok(value: a)
                case .err: continue
                }
            }
            return $0.err()
        }
    }
    public func withDebugLabels(before: String, after: String) -> Self {
        return UnitParser.unit
            .withDebugLabel(before)
            .keepRight(self)
            .withDebugLabel(after)
    }
    /// Sequences two parsers, running the second parser after the first and combining their results.
    ///
    /// - Parameter f: A function that takes the result of the first parser and returns the second parser to execute.
    /// - Returns: A parser that combines the results of two parsers.
    ///
    /// Example:
    /// ```swift
    /// let combinedParser = Parser<String>.token("Hello").andThen { _ in Parser<String>.token("World") }
    /// ```
    public func andThen<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        Parser<B> {
            switch self.binder($0) {
            case .ok(value: let a, state: let o):
                switch f(a).binder(o) {
                case .ok(value: let b, state: let o):
                    return o.ok(value: b)
                case .err(state: let o):
                    return o.err()
                }
            case .err(state: let o):
                return o.err()
            }
        }
    }
    /// Transforms the result of the parser with a given function.
    ///
    /// - Parameter f: A function to apply to the result of the parser.
    /// - Returns: A parser that transforms its result with the given function.
    ///
    /// Example:
    /// ```swift
    /// let numberParser = Parser<String>.token("123").map { Int($0) }
    /// ```
    public func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
        andThen { Parser<B>.pure(value: f($0)) }
    }
    /// Runs the parser, optionally consuming and then restoring the input tape to its original state.
    ///
    /// - Parameter tape: The tape to put back if not null after parsing.
    /// - Returns: A parser that may restore the input tape after parsing.
    ///
    /// Example:
    /// ```swift
    /// let parserWithBacktrack = Parser<String>.token("Hello").putBack(tape: Tape(from: " World"))
    /// ```
    public func putBack(tape: Tape?) -> Self {
        if let tape = tape {
            return Self {
                let input = $0.set(tape: Tape.flatten(leading: tape, trailing: $0.tape))
                switch binder(input) {
                case .ok(value: let a, state: let o):
                    return o.ok(value: a)
                case .err(state: let o):
                    return o.err()
                }
            }
        }
        return self
    }
    public func putBack(char: Tape.FatChar?) -> Self {
        let tape = char
            .map { Tape(from: [$0]) }
        return self.putBack(tape: tape)
    }
    /// Creates a parser that consumes no input and always returns the provided value.
    ///
    /// - Parameter pure value: The value to be returned by the parser.
    /// - Returns: A parser that always succeeds with the given value.
    ///
    /// Example:
    /// ```swift
    /// let alwaysHello = Parser<String>.pure(value: "Hello")
    /// ```
    public func set<T>(pure value: T) -> Parser<T> {
        map { _ in value }
    }
    /// Creates a parser that sequences this parser with another, discarding the result of this parser and only returning the result of the second.
    ///
    /// This combinator is useful when the result of the first parser is not needed, but its successful execution is required to proceed. It's a common pattern for skipping over delimiters or other syntax elements where only the content following these elements is of interest.
    ///
    /// - Parameter f: A parser to be executed after the current parser, whose result will be returned.
    /// - Returns: A parser that returns the result of the second parser if both parsers succeed; otherwise, it fails with the state of the first failure encountered.
    ///
    /// Example:
    /// ```swift
    /// let ignoreWhitespace = Parser<String>.whitespace
    /// let digitParser = CharParser.pop { $0.isNumber }
    /// let parseDigitAfterSpace = ignoreWhitespace.keepRight(digitParser)
    /// // Consumes and ignores whitespace, then parses and returns the next digit.
    /// ```
    public func keepRight<T>(_ f: @escaping @autoclosure () -> Parser<T>) -> Parser<T> {
        andThen { _ in f() }
    }
    /// Creates a parser that ignores the result of another parser applied after the current parser.
    ///
    /// - Parameter f: The parser whose result is to be ignored.
    /// - Returns: A parser that returns the result of the first parser while ignoring the result of the second.
    ///
    /// Example:
    /// ```swift
    /// let digitParser = CharParser.pop { $0.isNumber }
    /// let ignoreWhitespace = digitParser.ignoring(TapeParser.whitespace)
    /// // Parses a digit and then ignores any following whitespace.
    /// ```
    public func ignoring<B>(_ f: @escaping @autoclosure () -> Parser<B>) -> Parser<A> {
        andThen { a in f().map { _ in a} }
    }
    /// Attempts to parse using the current parser, then applies another parser on the remaining input and combines their results.
    ///
    /// - Parameter f: A function that returns a parser to be applied after the current one.
    /// - Returns: A parser that sequences the application of two parsers and combines their results into a tuple.
    ///
    /// Example:
    /// ```swift
    /// let greetingParser = Parser<String>.token("Hello")
    /// let nameParser = Parser<String>.token("World")
    /// let combinedParser = greetingParser.and(nameParser)
    /// // If the input is "HelloWorld", the result will be a tuple ("Hello", "World").
    /// ```
    public func and<B>(_ f: @escaping @autoclosure () -> Parser<B>) -> TupleParser<A, B> {
        andThen { a in f().map { b in Tuple(a, b) } }
    }
    /// Combines the current parser with two additional parsers, sequencing their execution and aggregating their results into a triple.
    ///
    /// - Parameters:
    ///   - f: The second parser to be executed.
    ///   - g: The third parser to be executed.
    /// - Returns: A parser that combines the results of all three parsers into a triple.
    ///
    /// Example:
    /// ```swift
    /// let parserA = Parser.token("First")
    /// let parserB = Parser.token("Second")
    /// let parserC = Parser.token("Third")
    /// let combinedParser = parserA.and2(parserB, parserC)
    /// // Parses "FirstSecondThird" into a triple ("First", "Second", "Third").
    /// ```
    public func and2<B, C>(
        _ f: @escaping @autoclosure () -> Parser<B>,
        _ g: @escaping @autoclosure () -> Parser<C>
    ) -> TripleParser<A, B, C> {
        and(f()).and(g()).map {
            Triple($0.a.a, $0.a.b, $0.b)
        }
    }
    public func and3<B, C, D>(
        _ f: @escaping @autoclosure () -> Parser<B>,
        _ g: @escaping @autoclosure () -> Parser<C>,
        _ h: @escaping @autoclosure () -> Parser<D>
    ) -> QuadrupleParser<A, B, C, D> {
        and2(f(), g()).and(h()).map { Quadruple(a: $0.a.a, b: $0.a.b, c: $0.a.c, d: $0.b) }
    }
    /// Creates a parser that results in an `Either` type, encapsulating the result of the first successful parser.
    ///
    /// - Parameter f: A parser to attempt if the first parser fails.
    /// - Returns: A parser that encapsulates the result of the first successful parser in an `Either` type.
    ///
    /// Example:
    /// ```swift
    /// let parserA = Parser.token("Hello")
    /// let parserB = Parser.token("World")
    /// let eitherParser = parserA.eitherOr(parserB)
    /// // Parses "Hello" into .left("Hello") or "World" into .right("World").
    /// ```
    public func eitherOr<B>(_ f: @escaping @autoclosure () -> Parser<B>) -> EitherParser<A, B> {
        return EitherParser<A, B> {
            switch self.binder($0) {
            case .ok(value: let a, state: let o): return o.ok(value: .left(a))
            case .err(_): break
            }
            switch f().binder($0) {
            case .ok(value: let b, state: let o): return o.ok(value: .right(b))
            case .err(_): break
            }
            return $0.err()
        }
    }
    /// Attempts to parse with the current parser; if it fails, tries the next parser.
    ///
    /// - Parameter f: A parser to attempt if the first parser fails.
    /// - Returns: The first successful parser result or fails if both parsers fail.
    ///
    /// Example:
    /// ```swift
    /// let parserA = Parser<String>.token("OptionA")
    /// let parserB = Parser<String>.token("OptionB")
    /// let choiceParser = parserA.or(parserB)
    /// // Parses "OptionA" or "OptionB" from the input.
    /// ```
    public func or(_ f: @escaping @autoclosure () -> Parser<A>) -> Parser<A> {
        Parser<A> {
            switch self.binder($0) {
            case .ok(value: let a, state: let o): return o.ok(value: a)
            case .err(_): break
            }
            switch f().binder($0) {
            case .ok(value: let a, state: let o): return o.ok(value: a)
            case .err(_): break
            }
            return $0.err()
        }
    }
    /// Marks the parser as optional, allowing it to succeed with a `nil` value if the underlying parser fails.
    ///
    /// - Returns: A parser that succeeds with an optional value.
    ///
    /// Example:
    /// ```swift
    /// let optionalDigit = CharParser.pop { $0.isNumber }.optional
    /// // Parses a single digit if present, otherwise succeeds with `nil`.
    /// ```
    public var optional: Parser<A?> {
        Parser<A?> {
            switch self.binder($0) {
            case .ok(value: let a, state: let rest):
                return rest.ok(value: a)
            case .err(state: _):
                return $0.ok(value: nil)
            }
        }
    }
    private func sequence(allowEmptyResults: Bool) -> Parser<[A]> {
        Parser<[A]> {
            var results: [A] = []
            var current: ParserState = $0
            var last: ParserState? = nil
            var counter = 0
            loop: while !current.tape.isEmpty {
                counter += 1
                switch self.binder(current) {
                case .ok(value: let a, state: let rest):
                    last = current
                    current = rest
                    if last?.tape.semanticallyEqual(with: current.tape) == true {
                        break loop
                    }
                    results.append(a)
                    if counter >= 1000 {
                        let type = "Parser<[\(type(of: A.self))]>.sequence"
                        print("\(type) WARNING: TOO MANY ITERATIONS: LAST: \(a)")
                    }
                    continue
                case .err(state: _):
                    if counter >= 1000 {
                        let type = "Parser<[\(type(of: A.self))]>.sequence"
                        print("\(type) WARNING: TOO MANY ITERATIONS")
                    }
                    break loop
                }
            }
            if !allowEmptyResults, results.isEmpty {
                return $0.err()
            }
            return current.ok(value: results)
        }
    }
    private func sequenceUnless<B>(
        allowEmptyResults: Bool,
        terminator: @escaping () -> Parser<B>
    ) -> TupleParser<[A], B?> {
        TupleParser<[A], B?> {
            var results: [A] = []
            var current: ParserState = $0
            var last: ParserState? = nil
            var counter = 0
            loop: while !current.tape.isEmpty {
                counter += 1
                if counter >= 1000 {
                    let type = "Parser<[\(type(of: A.self))]>.sequenceUnless"
                    print("\(type) WARNING: TOO MANY ITERATIONS")
                }
                switch terminator().binder(current) {
                case .ok(value: let b, state: let rest): return rest.ok(value: Tuple(results, b))
                case .err: break
                }
                switch self.binder(current) {
                case .ok(value: let a, state: let rest):
                    results.append(a)
                    last = current
                    current = rest
                    if last?.tape.semanticallyEqual(with: current.tape) == true {
                        break loop
                    }
                case .err: break loop
                }
            }
            if !allowEmptyResults, results.isEmpty {
                return $0.err()
            }
            return current.ok(value: Tuple(results, nil))
        }
    }
    private func sequenceUntilEnd<B>(
        allowEmptyResults: Bool,
        terminator: @escaping () -> Parser<B>
    ) -> TupleParser<[A], B> {
        TupleParser<[A], B> {
            var results: [A] = []
            var current: ParserState = $0
            var last: ParserState? = nil
            var counter = 0
            loop: while !current.tape.isEmpty {
                counter += 1
                if counter >= 1000 {
                    let type = "Parser<[\(type(of: A.self))]>.sequenceUntilEnd"
                    print("\(type) WARNING: TOO MANY ITERATIONS")
                }
                switch terminator().binder(current) {
                case .ok(value: let b, state: let rest):
                    if !allowEmptyResults, results.isEmpty {
                        return $0.err()
                    }
                    return rest.ok(value: Tuple(results, b))
                case .err:
                    ()
                }
                switch self.binder(current) {
                case .ok(value: let a, state: let rest):
                    results.append(a)
                    last = current
                    current = rest
                    if last?.tape.semanticallyEqual(with: current.tape) == true {
                        break loop
                    }
                    continue loop
                case .err:
                    break loop
                }
            }
            return $0.err()
        }
    }
    // MARK: - BASIC MANY COMBINATORS -
    /// Repeats parsing as many times as possible until a failure, returning an array of results.
    ///
    /// - Returns: A parser that collects zero or more results from the repeated application of itself.
    ///
    /// Example:
    /// ```swift
    /// let digitsParser = CharParser.pop { $0.isNumber }.many
    /// // Collects a sequence of digits into an array.
    /// ```
    public var many: Parser<[A]> {
        self.sequence(allowEmptyResults: true)
    }
    /// Repeats parsing one or more times until a failure, returning an array of results.
    ///
    /// - Returns: A parser that collects one or more results from the repeated application of itself.
    ///
    /// Example:
    /// ```swift
    /// let digitsParser = CharParser.pop { $0.isNumber }.some
    /// // Collects a sequence of one or more digits into an array.
    /// ```
    public var some: Parser<[A]> {
        self.sequence(allowEmptyResults: false)
    }
    // MARK: - VARIANTS OF MANY/SOME
    /// Parses the input multiple times with the current parser until an optional terminator is encountered.
    ///
    /// This function attempts to repeatedly apply the current parser to the input until the terminator parser succeeds. The terminator is optional, meaning the function can succeed even if the terminator is not found. It returns all successfully parsed values and an optional result indicating whether the terminator was parsed.
    ///
    /// - Parameter terminator: A parser that acts as a terminator, stopping the repetition when it succeeds.
    /// - Returns: A parser that returns a tuple containing an array of successfully parsed values and an optional result of the terminator parser.
    ///
    /// Example:
    /// ```swift
    /// let digitParser = CharParser.pop { $0.isNumber }
    /// let commaTerminator = CharParser.char(",")
    /// let digitsUntilComma = digitParser.manyUnless(terminator: commaTerminator)
    /// // Parses a sequence of digits until a comma is encountered, including the case where the comma is not present.
    /// ```
    public func manyUnless<B>(terminator: @escaping @autoclosure () -> Parser<B>) -> TupleParser<[A], B?> {
        self.sequenceUnless(allowEmptyResults: true, terminator: terminator)
    }
    /// Parses the input one or more times with the current parser until an optional terminator is encountered, requiring at least one successful parse.
    ///
    /// Similar to `manyUnless`, but requires that the current parser succeeds at least once before encountering the terminator. If the current parser never succeeds, the function fails. This ensures that at least one element is parsed successfully before the optional terminator.
    ///
    /// - Parameter terminator: A parser that acts as a terminator, stopping the repetition when it succeeds.
    /// - Returns: A parser that returns a tuple containing an array of one or more successfully parsed values and an optional result of the terminator parser.
    ///
    /// Example:
    /// ```swift
    /// let wordParser = CharParser.pop { $0.isLetter }.many
    /// let periodTerminator = CharParser.char(".")
    /// let wordsUntilPeriod = wordParser.someUnless(terminator: periodTerminator)
    /// // Parses a sequence of words until a period is encountered, requiring at least one word before the period.
    /// ```
    public func someUnless<B>(terminator: @escaping @autoclosure () -> Parser<B>) -> TupleParser<[A], B?> {
        self.sequenceUnless(allowEmptyResults: false, terminator: terminator)
    }
    /// Attempts to parse a sequence of elements terminated by a parser for a terminator, returning an array of parsed elements.
    ///
    /// - Parameters:
    ///   - terminator: A parser that determines the end of the sequence.
    /// - Returns: A parser that attempts to parse zero or more elements until the terminator is successfully parsed.
    ///
    /// Example:
    /// ```swift
    /// let comma = CharParser.char(",")
    /// let numberParser = CharParser.pop { $0.isNumber }.manyUntilEnd(terminator: comma)
    /// ```
    public func manyUntilEnd<B>(terminator: @escaping @autoclosure () -> Parser<B>) -> TupleParser<[A], B> {
        self.sequenceUntilEnd(allowEmptyResults: true, terminator: terminator)
    }
    /// Parses repeatedly until a terminating condition is met, ensuring at least one successful parse.
    ///
    /// - Parameter terminator: A parser that determines when to stop repeating the current parser.
    /// - Returns: A parser that collects one or more results until the terminator is successfully parsed.
    ///
    /// Example:
    /// ```swift
    /// let commaSeparatedNumbers = CharParser.pop { $0.isNumber }.someUntilEnd(terminator: CharParser.char(","))
    /// // Parses a comma-separated list of numbers, requiring at least one number before a comma.
    /// ```
    public func someUntilEnd<B>(terminator: @escaping @autoclosure () -> Parser<B>) -> TupleParser<[A], B> {
        self.sequenceUntilEnd(allowEmptyResults: false, terminator: terminator)
    }
    // MARK: - CALLBACK VARIANTS OF MANY/SOME
    /// Repeats the parser as many times as possible until a terminator parser is successfully applied, allowing the terminator to be optional.
    ///
    /// - Parameter terminator: A closure returning a parser that determines the optional end of repetition.
    /// - Returns: A parser that collects results in an array and includes an optional termination result.
    ///
    /// Example:
    /// ```swift
    /// let optionalCommaTerminated = CharParser.pop { $0.isNumber }.manyUnless { CharParser.char(",") }
    /// // Parses a sequence of numbers, optionally terminated by a comma.
    /// ```
    public func manyUnless<B>(terminator: @escaping () -> Parser<B>) -> TupleParser<[A], B?> {
        self.sequenceUnless(allowEmptyResults: true, terminator: terminator)
    }
    /// Parses repeatedly until a terminating condition is met, ensuring at least one successful parse, with the terminator being optional.
    ///
    /// - Parameter terminator: A closure returning a parser that determines the optional end of repetition.
    /// - Returns: A parser that collects one or more results and includes an optional termination result.
    ///
    /// Example:
    /// ```swift
    /// let requiredCommaTerminated = CharParser.pop { $0.isNumber }.someUnless { CharParser.char(",") }
    /// // Parses a sequence of numbers, requiring at least one number and allowing an optional terminating comma.
    /// ```
    public func someUnless<B>(terminator: @escaping () -> Parser<B>) -> TupleParser<[A], B?> {
        self.sequenceUnless(allowEmptyResults: false, terminator: terminator)
    }
    /// Repeats the parser as many times as possible until a terminator parser succeeds, allowing for no successful parses.
    ///
    /// - Parameter terminator: A closure returning a parser that stops the repetition when successful.
    /// - Returns: A parser that may collect zero or more results and an optional terminator result.
    ///
    /// Example:
    /// ```swift
    /// let commentsParser = Parser<String>.token("//").manyUntilEnd(terminator: { CharParser.newline })
    /// // Parses zero or more comment lines, stopping at a newline.
    /// ```
    public func manyUntilEnd<B>(terminator: @escaping () -> Parser<B>) -> TupleParser<[A], B> {
        self.sequenceUntilEnd(allowEmptyResults: true, terminator: terminator)
    }
    /// Parses repeatedly until a terminating condition is met, requiring at least one successful parse.
    ///
    /// - Parameter terminator: A closure returning a parser that stops the repetition when successful.
    /// - Returns: A parser that collects one or more results until the terminator is successfully parsed.
    ///
    /// Example:
    /// ```swift
    /// let blockContent = CharParser.any.except("}").someUntilEnd(terminator: CharParser.char("}"))
    /// // Parses the content of a block delimited by "{}", requiring at least one character before the closing brace.
    /// ```
    public func someUntilEnd<B>(terminator: @escaping () -> Parser<B>) -> TupleParser<[A], B> {
        self.sequenceUntilEnd(allowEmptyResults: false, terminator: terminator)
    }
    /// Encloses the parser within leading and trailing terminators, returning the parsed value flanked by the terminators' results.
    ///
    /// - Parameter bothEnds: A parser that matches both the leading and trailing delimiters.
    /// - Returns: A parser that captures the leading delimiter, the main content, and the trailing delimiter as a triple.
    ///
    /// Example:
    /// ```swift
    /// let quotedString = Parser<String>.token("\"").between(bothEnds: Parser<String>.token("\""))
    /// // Parses a string enclosed in quotes, returning a triple with the opening quote, the string content, and the closing quote.
    /// ```
    public func between<B>(bothEnds terminator: Parser<B>) -> TripleParser<B, A, B> {
        return terminator.andThen { x in
            self.andThen { y in
                terminator.map { z in
                    Triple(x, y, z)
                }
            }
        }
    }
    /// Encloses the parser between distinct leading and trailing parsers, useful for structures with different start and end markers.
    ///
    /// This function is particularly handy for parsing constructs like HTML tags, where the opening and closing syntax differ, but you're interested in capturing the content within, along with the delimiters.
    ///
    /// - Parameters:
    ///   - leading: A parser that matches the opening delimiter.
    ///   - trailing: A parser that matches the closing delimiter.
    /// - Returns: A parser that returns a triple: the result of the leading delimiter, the main content, and the result of the trailing delimiter.
    ///
    /// Example:
    /// ```swift
    /// // Assume we have predefined parsers for '<p>', '</p>', and any text content.
    /// let paragraphTag = Parser<String>.token("<p>")
    /// let closeParagraphTag = Parser<String>.token("</p>")
    /// let textContent = Parser<String>.anyTextUntil(closeParagraphTag)
    ///
    /// let paragraphContentParser = textContent.between(
    ///     leading: paragraphTag,
    ///     trailing: closeParagraphTag
    /// )
    /// // This parser will capture content enclosed by <p> and </p> tags.
    /// // For input "<p>Hello, World!</p>", the result is a triple: ("<p>", "Hello, World!", "</p>").
    /// ```
    public func between<B, C>(
        leading: @escaping @autoclosure () -> Parser<B>,
        trailing: @escaping @autoclosure () -> Parser<C>
    ) -> TripleParser<B, A, C> {
        return leading().andThen { x in
            self.andThen { y in
                trailing().map { z in
                    Triple(x, y, z)
                }
            }
        }
    }
    // MARK: - MISC AD HOC UTILS
    /// Creates a parser that ignores trailing whitespace after parsing the value.
    ///
    /// - Returns: A parser that ignores trailing whitespace.
    ///
    /// Example:
    /// ```swift
    /// let tokenParser = Parser<String>.token("Token").spacedRight
    /// ```
    public var spacedRight: Parser<A> {
        self.ignoring(TapeParser.whitespace.optional)
    }
    /// Creates a parser that ignores leading whitespace before parsing the value.
    ///
    /// - Returns: A parser that ignores leading whitespace.
    ///
    /// Example:
    /// ```swift
    /// let tokenParser = Parser<String>.token("Token").spacedLeft
    /// ```
    public var spacedLeft: Parser<A> {
        TapeParser.whitespace.optional.keepRight(self)
    }
    /// Creates a parser that ignores both leading and trailing whitespace around the parsed value.
    ///
    /// - Returns: A parser that ignores surrounding whitespace.
    ///
    /// Example:
    /// ```swift
    /// let tokenParser = Parser<String>.token("Token").spaced
    /// ```
    public var spaced: Parser<A> {
        TapeParser.whitespace.optional.keepRight(self).ignoring(TapeParser.whitespace.optional)
    }
    public func skip(ifTrue skip: Bool) -> Parser<A> {
        Parser<A> {
            if skip {
                return $0.err()
            }
            return self.binder($0)
        }
    }
    public static func skip(ifTrue skip: Bool, parser: @autoclosure () -> Parser<A>) -> Parser<A> {
        if skip {
            return Parser<A>.fail
        }
        return parser()
    }
    // MARK: - DEBUG HELPERS
    /// Attaches a debugging label to the parser, which can be used for debugging purposes.
    ///
    /// - Parameter label: A string label to attach to the parser for debugging.
    /// - Returns: A parser identical to the original, but with an attached debug label.
    ///
    /// Example:
    /// ```swift
    /// let debuggedParser = Parser<String>.token("Debugged").with(debugScope: "DebuggingToken")
    /// ```
    public func withDebugLabel(_ label: String) -> Self {
        Self {
            switch self.binder($0) {
            case .ok(value: let a, state: let o):
                return o.with(scope: label).ok(value: a)
            case .err(state: let o):
                return o.with(scope: label).err()
            }
        }
    }
    /// Disregards the current value.
    public var forgotten: UnitParser {
        UnitParser {
            switch self.binder($0) {
            case .ok(value: _, state: let rest):
                return rest.ok(value: ())
            case .err(state: let out): return out.err()
            }
        }
    }
}

// MARK: - UNIT PARSER -
extension UnitParser {
    /// Represents a parser that succeeds without consuming any input and returns a unit value, often used for side effects or as a no-op parser.
    ///
    /// - Returns: A parser that always succeeds and returns a unit value `()`.
    ///
    /// Example:
    /// ```swift
    /// let unit = UnitParser.unit
    /// // Can be used in places where you need to return from a parsing function but don't have a meaningful value to return.
    /// ```
    public static var unit: Self {
        Self { $0.ok(value: ()) }
    }
    /// Creates a parser that matches a single character specified by the pattern.
    ///
    /// - Parameter pattern: The character the parser should match.
    /// - Returns: A parser that consumes and returns a single character if it matches, or fails.
    ///
    /// Example:
    /// ```swift
    /// let semicolonParser = UnitParser.char(";")
    /// ```
    public static func char(_ pattern: Character) -> CharParser {
        CharParser.pop(pattern)
    }
    /// Creates a parser that consumes a single character if it satisfies the given predicate.
    ///
    /// - Parameter predicate: A closure that takes a character as its argument and returns a Boolean value indicating whether the character should be consumed.
    /// - Returns: A parser that consumes a single character matching the predicate.
    ///
    /// Example:
    /// ```swift
    /// let digitParser = UnitParser.char { $0.isNumber }
    /// // Consumes a single digit from the input.
    /// ```
    public static func char(_ predicate: @escaping (Character) -> Bool) -> CharParser {
        CharParser.pop(predicate)
    }
    /// Creates a parser that consumes a specific string pattern.
    ///
    /// - Parameter pattern: The string pattern to be matched and consumed by the parser.
    /// - Returns: A parser that consumes the specified string pattern from the input.
    ///
    /// Example:
    /// ```swift
    /// let helloParser = UnitParser.token("Hello")
    /// // Consumes the string "Hello" from the input.
    /// ```
    public static func token(_ pattern: String) -> TapeParser {
        TapeParser.pop(pattern)
    }
    /// Creates a parser that alternates between two parsers, collecting their results into an array of `Either` types, accommodating for sequences of different parsed types.
    ///
    /// - Parameters:
    ///   - f: The first parser to be applied.
    ///   - g: The second parser to be applied.
    /// - Returns: A parser that alternates between two parsers and collects their results.
    ///
    /// Example:
    /// ```swift
    /// let lettersParser = UnitParser.char { $0.isLetter }
    /// let numbersParser = UnitParser.char { $0.isNumber }
    /// let alternatingParser = UnitParser.alternatingHeterogeneousSequencesOf(f: lettersParser, g: numbersParser)
    /// // Alternates between parsing letters and numbers, collecting results in an array of Either type.
    /// ```
    public static func alternatingHeterogeneousSequencesOf<T, U>(
        f: @escaping @autoclosure () -> Parser<T>,
        g: @escaping @autoclosure () -> Parser<U>
    ) -> Parser<[Either<T, U>]> {
        Parser<[Either<T, U>]> {
            var current = $0
            var results: [Either<T, U>] = []
            loop: while !current.isEmpty {
                switch f().binder(current) {
                case .ok(value: let t, state: let rest):
                    results.append(.left(t))
                    current = rest
                    continue loop
                case .err: break
                }
                switch g().binder(current) {
                case .ok(value: let u, state: let rest):
                    results.append(.right(u))
                    current = rest
                    continue loop
                case .err: break
                }
                break loop
            }
            return current.ok(value: results)
        }
    }
    /// Creates a parser that alternates between two parsers of the same type, collecting their results into an array, suitable for parsing sequences where elements can come from one of two sources.
    ///
    /// - Parameters:
    ///   - f: The first parser to be applied.
    ///   - g: The second parser to be applied.
    /// - Returns: A parser that alternates between two parsers of the same type and collects their results.
    ///
    /// Example:
    /// ```swift
    /// let vowelsParser = UnitParser.char { "aeiou".contains($0) }
    /// let consonantsParser = UnitParser.char { "bcdfghjklmnpqrstvwxyz".contains($0) }
    /// let alternatingParser = UnitParser.alternatingHomogeneousSequencesOf(f: vowelsParser, g: consonantsParser)
    /// // Alternates between parsing vowels and consonants, collecting results in an array.
    /// ```
    public static func alternatingHomogeneousSequencesOf<T>(
        f: @escaping @autoclosure () -> Parser<T>,
        g: @escaping @autoclosure () -> Parser<T>
    ) -> Parser<[T]> {
        Parser<[T]> {
            var current = $0
            var results: [T] = []
            loop: while !current.isEmpty {
                switch f().binder(current) {
                case .ok(value: let t, state: let rest):
                    results.append(t)
                    current = rest
                    continue loop
                case .err: break
                }
                switch g().binder(current) {
                case .ok(value: let t, state: let rest):
                    results.append(t)
                    current = rest
                    continue loop
                case .err: break
                }
                break loop
            }
            return current.ok(value: results)
        }
    }
    public func withParserState<T>(_ f: @escaping (ParserState) -> T) -> Parser<T> {
        Parser<T> {
            switch self.binder($0) {
            case .ok(value: _, state: let rest):
                return rest.ok(value: f(rest))
            case .err(state: let res): return res.err()
            }
        }
    }
}

// MARK: - TAPE CHARACTER PARSER -
extension CharParser {
    /// A parser that consumes and returns the next character from the input stream, if available.
    ///
    /// This parser is useful when you need to consume a single character regardless of what it is, often used in scenarios where the specific character is not important or is handled dynamically.
    ///
    /// - Returns: A parser that consumes the next available character.
    ///
    /// Example:
    /// ```swift
    /// let nextCharParser = CharParser.next
    /// // Consumes a single character from the input, useful for parsing schemes where characters are processed one by one.
    /// ```
    public static var next: Parser<Tape.FatChar> {
        Self {
            if let (first, rest) = $0.uncons {
                return rest.ok(value: first)
            }
            return $0.err()
        }
    }
    /// Parses the next character if it matches the given pattern.
    ///
    /// - Parameter pattern: The character to match.
    /// - Returns: A parser that succeeds if the next character matches the pattern.
    ///
    /// Example:
    /// ```swift
    /// let aParser = CharParser.pop("a")
    /// ```
    public static func pop(_ pattern: Character) -> Self {
        Self {
            guard let (head, rest) = $0.uncons(pattern: pattern) else {
                return $0.err()
            }
            return rest.ok(value: head)
        }
    }
    /// Parses the next character if it satisfies the given predicate.
    public static func unconsIf(_ predicate: @escaping (Tape.FatChar) -> Bool) -> Self {
        Self {
            guard let (head, rest) = $0.unconsIf(predicate: predicate) else {
                return $0.err()
            }
            return rest.ok(value: head)
        }
    }
    /// Parses the next character if it satisfies the given predicate.
    ///
    /// - Parameter predicate: A closure that takes a character and returns true if it should be parsed.
    /// - Returns: A parser that succeeds if the next character satisfies the predicate.
    ///
    /// Example:
    /// ```swift
    /// let digitParser = CharParser.pop { $0.isNumber }
    /// ```
    public static func pop(_ predicate: @escaping (Character) -> Bool) -> Self {
        Self {
            guard let (head, rest) = $0.unconsFor(predicate: predicate) else {
                return $0.err()
            }
            return rest.ok(value: head)
        }
    }
    /// A parser that specifically consumes and returns a newline character from the input stream, if it is the next character.
    ///
    /// This parser is particularly useful in text processing tasks, such as parsing log files, configuration files, or other text data where newlines signify the end of a line or entry.
    ///
    /// - Returns: A parser that succeeds if the next character is a newline, consuming it.
    ///
    /// Example:
    /// ```swift
    /// let newlineParser = CharParser.newline
    /// // Consumes a newline character, useful for parsing tasks that involve structured text data.
    /// ```
    public static var newline: CharParser {
        CharParser.pop { $0.isNewline }
    }
    public static var space: CharParser {
        CharParser.pop { $0.isWhitespace && !$0.isNewline }
    }
    public static var number: CharParser {
        CharParser.pop { $0.isNumber }
    }
}

// MARK: - TAPE PARSER -
extension TapeParser {
    /// Creates a parser that consumes a specific string pattern from the input.
    ///
    /// This parser matches and consumes the exact sequence of characters defined by the given pattern. It's particularly useful for recognizing specific keywords, symbols, or other fixed sequences within a larger text stream.
    ///
    /// - Parameter pattern: The exact string sequence to match and consume.
    /// - Returns: A parser that consumes the specified string pattern if it matches the beginning of the input.
    ///
    /// Example:
    /// ```swift
    /// let keywordParser = TapeParser.pop("func")
    /// // Consumes the keyword "func" from the input, if present.
    /// ```
    public static func pop(_ pattern: String) -> Self {
        Self {
            guard let (head, rest) = $0.split(prefix: pattern) else {
                return $0.err()
            }
            return rest.ok(value: head)
        }
    }
    /// A parser that consumes and returns any whitespace characters it encounters, except for newline characters.
    ///
    /// - Returns: A parser that consumes leading whitespace from the input and returns a `Tape` containing the consumed whitespace characters, up until a non-whitespace or newline character is encountered.
    ///
    /// Example:
    /// ```swift
    /// let whitespaceParser = TapeParser.whitespace
    /// // When applied, this parser will consume spaces or tabs and return them in a Tape, stopping before a non-whitespace or newline character.
    /// ```
    public static var whitespace: Self {
        CharParser.pop { $0.isWhitespace && !$0.isNewline }
            .many
            .map { Tape(from: $0) }
    }
    /// A parser that consumes and returns the remainder of the current line, stopping at a newline character or end of input.
    ///
    /// This parser is valuable for scenarios where you need to capture entire lines of text, such as parsing log files, reading configuration entries, or processing command output. It effectively grabs all characters up to, but not including, the next newline character.
    ///
    /// - Returns: A parser that consumes all characters up to the next newline or the end of the input.
    ///
    /// Example:
    /// ```swift
    /// let lineParser = TapeParser.restOfLine
    /// // Consumes and returns the entire current line, excluding the terminating newline character.
    /// ```
    public static var restOfLine: Self {
        CharParser.pop { !$0.isNewline }.some.map(Tape.init(from:))
    }
    public static func manyUntilTerm<T>(terminator: @escaping @autoclosure () -> Parser<T>) -> Parser<Tuple<Tape, T>> {
        Parser<Tuple<Tape, T>> {
            var characters: [ Tape.FatChar ] = []
            var current: ParserState = $0
            var counter = 0
            loop: while !current.tape.isEmpty {
                counter += 1
                if counter >= 1000 {
                    print("TapeParser.manyUntilToken WARNING: TOO MANY ITERATIONS")
                }
                switch terminator().binder(current) {
                case .ok(value: let b, state: let rest):
                    return rest.ok(value: Tuple(Tape(from: characters), b))
                case .err: ()
                }
                switch CharParser.next.binder(current) {
                case .ok(value: let x, state: let rest):
                    characters.append(x)
                    current = rest
                    continue loop
                case .err: break loop
                }
            }
            return $0.err()
        }
    }
}

// MARK: - N-ELEMENT PRODUCT PARSERS -
extension Tuple {
    /// Combines two parsers into a single parser that produces a tuple of their results.
    ///
    /// This function is useful when you want to parse two different pieces of data that are related and should be processed together.
    ///
    /// - Parameters:
    ///   - f: The first parser to be applied.
    ///   - g: The second parser to be applied.
    /// - Returns: A `TupleParser` that combines the results of both parsers into a tuple.
    ///
    /// Example:
    /// ```swift
    /// let parserA = Parser<String>.token("A")
    /// let parserB = Parser<Int>.pure(value: 1)
    /// let combinedParser = Tuple.joinParsers(f: parserA, g: parserB)
    /// // Results in a Tuple containing the results of parserA and parserB.
    /// ```
    public static func joinParsers(
        f: @escaping @autoclosure () -> Parser<A>,
        g: @escaping @autoclosure () -> Parser<B>
    ) -> TupleParser<A, B> {
        f().and(g())
    }
}
extension Triple {
    /// Combines three parsers into a single parser that produces a triple of their results.
    ///
    /// Use this function when parsing three related pieces of data that are sequentially organized in the input.
    ///
    /// - Parameters:
    ///   - f: The first parser to be applied.
    ///   - g: The second parser to be applied.
    ///   - h: The third parser to be applied.
    /// - Returns: A `TripleParser` that combines the results of the three parsers into a triple.
    ///
    /// Example:
    /// ```swift
    /// let parserA = Parser<String>.token("A")
    /// let parserB = Parser<String>.token("B")
    /// let parserC = Parser<Int>.pure(value: 2)
    /// let combinedParser = Triple.joinParsers(f: parserA, g: parserB, h: parserC)
    /// // Results in a Triple containing the results of parserA, parserB, and parserC.
    /// ```
    public static func joinParsers(
        f: @escaping @autoclosure () -> Parser<A>,
        g: @escaping @autoclosure () -> Parser<B>,
        h: @escaping @autoclosure () -> Parser<C>
    ) -> TripleParser<A, B, C> {
        f().and2(g(), h())
    }
}
extension Quadruple {
    /// Combines four parsers into a single parser that produces a quadruple of their results.
    ///
    /// This function is ideal for cases where you need to parse four related pieces of data from the input, maintaining their relationship in the parsed output.
    ///
    /// - Parameters:
    ///   - f: The first parser to be applied.
    ///   - g: The second parser to be applied.
    ///   - h: The third parser to be applied.
    ///   - i: The fourth parser to be applied.
    /// - Returns: A `QuadrupleParser` that combines the results of the four parsers into a quadruple.
    ///
    /// Example:
    /// ```swift
    /// let parserA = Parser<String>.token("A")
    /// let parserB = Parser<String>.token("B")
    /// let parserC = Parser<String>.token("C")
    /// let parserD = Parser<Int>.pure(value: 3)
    /// let combinedParser = Quadruple.joinParsers(f: parserA, g: parserB, h: parserC, i: parserD)
    /// // Results in a Quadruple containing the results of parserA, parserB, parserC, and parserD.
    /// ```
    public static func joinParsers(
        f: @escaping @autoclosure () -> Parser<A>,
        g: @escaping @autoclosure () -> Parser<B>,
        h: @escaping @autoclosure () -> Parser<C>,
        i: @escaping @autoclosure () -> Parser<D>
    ) -> QuadrupleParser<A, B, C, D> {
        f().and3(g(), h(), i())
    }
}
