// The Swift Programming Language
// https://docs.swift.org/swift-book
import PrettyTree
import ExtraMonadoUtils

/// The `Parser` struct encapsulates a parsing operation. It's a generic type that takes an input of type `ParserState` and produces an output wrapped in `Output`, which contains both the result of the parsing operation and the updated state.
///
/// This abstraction allows for building complex parsers from simpler ones, fostering composability and reusability. By modeling parsers as monads, it enables powerful functional programming techniques, such as chaining and transformation of parsing operations, without immersing the developer in the underlying complexity.
///
/// ### Conceptual Foundations of the `Parser<A>` Monad
///
/// The `Parser<A>` monad is not just a tool for text parsing—it embodies a paradigm shift towards declarative and compositional programming in Swift. Understanding its foundations can profoundly impact how developers approach parsing problems.
///
/// #### The Monad: More Than Just a Fancy Container
///
/// At its core, a monad in functional programming is a pattern that allows for the chaining of operations in a context-sensitive manner. The `Parser<A>` monad wraps parsing logic in a context where parsing may succeed with a value and a new state or fail. This wrapping and the ability to chain operations contextually are what give monads—and `Parser<A>` specifically—their power.
///
/// #### The Role of `ParserState`
///
/// `ParserState` is crucial as it carries both the "tape" (the remaining input to be parsed) and potentially any debugging or operational metadata. This state is threaded through the parsing operations, ensuring that each step is aware of the progress and context of the parsing task.
///
/// #### Composability and Building Blocks
///
/// One of the `Parser<A>` monad's most significant advantages is its ability to compose small, understandable parsing functions into more complex ones. This composability is akin to building with Lego blocks: each parser does one thing and does it well, but combined, they can parse complex structures with ease.
///
/// - **Simplicity**: Define simple parsers for small tasks (e.g., parsing a digit).
/// - **Composition**: Combine simple parsers to handle more complex structures (e.g., numbers, dates, or even whole documents).
///
/// #### Chaining and Transformation
///
/// The `Parser<A>` monad enables chaining operations where the output of one parser becomes the input of the next. This chaining is facilitated by monadic operations like `bind` (often implemented as `flatMap` in Swift) that handle the unpacking and repacking of states and values automatically.
///
/// Transformations allow for the conversion of parsed values into more useful forms without losing the parsing context. This is often achieved through the `map` function, enabling parsed data to be immediately transformed within the same parsing flow.
///
/// #### Error Handling and Debugging
///
/// By encapsulating errors as part of its operational state, the `Parser<A>` monad provides a unified approach to error handling. Operations can fail without crashing the entire parsing process, allowing for graceful recovery or alternative parsing strategies.
///
/// Additionally, the inclusion of debugging scopes within the `ParserState` enables detailed insights into the parsing process, making it easier to diagnose issues or understand the parsing flow.
///
/// #### Example: Understanding Through Usage
///
/// ```swift
/// // Define a parser for an integer followed by a space and an alphabetic string.
/// let numberParser = CharParser.pop { $0.isNumber }.many.map { String($0) }
/// let spaceParser = CharParser.char(" ")
/// let wordParser = CharParser.pop { $0.isLetter }.many.map { String($0) }
///
/// let combinedParser = numberParser.and(spaceParser).and(wordParser).map { number, _, word in
///     (Int(number), word)
/// }
////
/// // Apply the parser to an input string.
/// let result = combinedParser.evaluate(source: "123 hello")
/// // Result: (Optional((123, "hello")), ParserState(...))
/// ```
///
/// In this example, simple parsers for numbers, spaces, and words are defined and then composed to parse a structured input. The use of `map` to transform the parsed values into a tuple demonstrates chaining and transformation in action.
///
/// Understanding `Parser<A>` as more than a utility for text parsing but as an exemplar of functional programming principles can elevate Swift programming practices. It brings a powerful, mathematically sound approach to software design, emphasizing clarity, expressiveness, and robustness.
public struct Parser<A> {
    internal let binder: (ParserState) -> Output
    /// Initializes a parser with a binding function, which defines how the parser processes input and produces output.
    internal init(binder: @escaping (ParserState) -> Output) {
        self.binder = binder
    }
    /// `Output` encapsulates the result of a parsing attempt. It contains the parsed value (if any) and the resultant state of the parser, allowing for continuation or termination of parsing as dictated by the outcome.
    internal struct Output {
        let value: A?
        let state: ParserState
        fileprivate init(value: A?, state: ParserState) {
            self.value = value
            self.state = state
        }
    }
    /// `Result` is an enumeration that succinctly represents the outcome of a parsing operation: success (`ok`) with a value and updated state, or failure (`err`) with an error state.
    internal enum Result {
        case ok(value: A, state: ParserState)
        case err(state: ParserState)
    }
}
/// Encapsulates the state of the parser, including the remaining input (`Tape`) and any debugging scopes.
///
/// - tape: The current position and remaining input for the parser to consume.
/// - debugScopes: An array of strings representing the hierarchical path of parser operations, useful for debugging.
public struct ParserState {
    public let tape: Tape
    public let debugScopes: [String]
    internal init(tape: Tape, debugScopes: [String] = []) {
        self.tape = tape
        self.debugScopes = debugScopes
    }
    /// Factory method to create a root parser state with the given input.
    internal static func root(tape: Tape) -> Self {
        Self(tape: tape)
    }
    /// Checks if there is any remaining input to parse.
    public var isEmpty: Bool { tape.isEmpty }
    /// Attempts to consume the next character from the input, if available.
    public var uncons: (Tape.Char, Self)? {
        tape.uncons.map {
            ($0.0, ParserState(tape: $0.1, debugScopes: debugScopes))
        }
    }
    public func take(count: UInt) -> ([Tape.Char], Self) {
        let (xs, rest) = tape.take(count: count)
        return (xs, Self(tape: rest, debugScopes: debugScopes))
    }
    /// Attempts to consume a sequence of characters matching the given prefix.
    public func split(prefix: String) -> (Tape, Self)? {
        tape.split(prefix: prefix).map {
            ($0.0, Self(tape: $0.1, debugScopes: debugScopes))
        }
    }
    public func uncons(pattern: Character) -> (Tape.Char, Self)? {
        tape.uncons(pattern: pattern).map {
            ($0.0, ParserState(tape: $0.1, debugScopes: debugScopes))
        }
    }
    public func uncons(predicate: @escaping (Character) -> Bool) -> (Tape.Char, Self)? {
        tape.uncons(predicate: predicate).map {
            ($0.0, ParserState(tape: $0.1, debugScopes: debugScopes))
        }
    }
    /// Returns the entire remaining input as a string.
    public var asString: String { tape.asString }
}

extension ParserState {
    internal func ok<A>(value: A) -> Parser<A>.Output {
        Parser<A>.Output(value: value, state: self)
    }
    internal func ok<A>(value: A, with tape: Tape) -> Parser<A>.Output {
        Parser<A>.Output(value: value, state: ParserState.init(tape: tape, debugScopes: debugScopes))
    }
    internal func err<A>() -> Parser<A>.Output {
        Parser<A>.Output(value: nil, state: self)
    }
    internal func update(_ transform: @escaping (Tape) -> Tape) -> Self {
        Self(tape: transform(tape), debugScopes: debugScopes)
    }
    internal func set(tape: Tape) -> Self {
        Self(tape: tape, debugScopes: debugScopes)
    }
    internal func set(debugScopes: [String]) -> Self {
        Self(tape: tape, debugScopes: debugScopes)
    }
    internal func with(scope: String) -> Self {
        Self(tape: tape, debugScopes: debugScopes.with(append: scope))
    }
}
extension Parser.Output {
    public var asResult: Parser.Result {
        if let value = value {
            return Parser.Result.ok(value: value, state: state)
        }
        return Parser.Result.err(state: state)
    }
    internal func set(debugScopes: [String]) -> Self {
        Self(value: value, state: ParserState(tape: state.tape, debugScopes: debugScopes))
    }
}

/// A parser that does not produce a value but can be used to consume input according to specified rules or perform actions without returning a result.
///
/// This parser is particularly useful for operations where the result is not needed, such as consuming whitespace or comments in a language parser.
public typealias UnitParser = Parser<()>
/// A parser designed to operate on and consume segments of `Tape`, a linked list of annotated characters, often used to represent the input stream.
///
/// TapeParser is versatile for parsing tasks that require manipulation or inspection of the input stream, such as tokenizing or pattern matching.
public typealias TapeParser = Parser<Tape>
/// A specialized parser for consuming individual characters from the input stream.
///
/// CharParser is used for fine-grained parsing tasks, such as identifying specific characters, validating character patterns, or parsing single tokens.
public typealias CharParser = Parser<Tape.Char>
/// A parser that combines the results of two parsers into a `Tuple`, facilitating operations that require correlating the results of multiple parsing tasks.
///
/// Ideal for parsing paired structures or two related data points simultaneously, like key-value pairs in configuration files or markup languages.
public typealias TupleParser<A, B> = Parser<Tuple<A, B>>
/// Extends `TupleParser` to combine the results of three parsers into a `Triple`, useful for scenarios where three related pieces of data must be parsed together.
///
/// This parser type is helpful for parsing complex structures that consist of three components, such as RGB color values or conditional expressions in programming languages.
public typealias TripleParser<A, B, C> = Parser<Triple<A, B, C>>
/// A parser that aggregates the results of four parsers into a `Quadruple`, enabling the parsing of structures with four related elements.
///
/// QuadrupleParser is particularly useful for data that naturally comes in fours, such as rectangles (with four sides) or date-time stamps broken into year, month, day, and hour.
public typealias QuadrupleParser<A, B, C, D> = Parser<Quadruple<A, B, C, D>>
/// A parser that can produce one of two possible result types, encapsulated in an `Either` type.
///
/// EitherParser is ideal for parsing operations where the result can logically be one of two types, such as success/failure outcomes, or differentiating between two kinds of tokens in a language.
public typealias EitherParser<A, B> = Parser<Either<A, B>>

// MARK: - DEBUG -
extension ParserState: ToPrettyTree {
    public var asPrettyTree: PrettyTree {
        let debugScopes = "[ \(debugScopes.map({$0}).joined(separator: ", ")) ]"
        return PrettyTree(label: "ParserState", children: [
            PrettyTree(key: "tape", value: PrettyTree.string(tape.asString)),
            PrettyTree(key: "debug", value: PrettyTree.value(debugScopes)),
        ])
    }
}
