# Swift Parsing Framework README

Welcome to the Swift Parsing Framework, a powerful and flexible tool for building complex parsers in Swift. This framework leverages the principles of functional programming to make parsing tasks straightforward and expressive. It's designed with composability, reusability, and simplicity in mind, allowing developers to construct robust parsers for a wide range of applications.

## Features

- **Composable Parsing Operations**: Build complex parsers from simple, reusable components.
- **Monadic Interface**: Leverage the power of monads for chaining parsing operations in a declarative manner.
- **Rich State Management**: Track parsing progress and manage state effortlessly across parsing operations.
- **Error Handling**: Capture and handle parsing errors seamlessly, improving debuggability and reliability.
- **Position Tracking**: Annotate parsed characters with their positions for detailed error reporting and analysis.

## Core Components

### Parser Monad

The heart of the framework, `Parser<A>`, represents a parsing operation that can consume input and produce a result of type `A`. It encapsulates the logic for parsing tasks, allowing for easy composition and extension.

### ParserState

`ParserState` carries the current state of the parsing process, including the remaining input (`Tape`) and any debugging information, ensuring that each parsing step is aware of its context.

### Tape

A recursive enumeration that models the input stream as a sequence of annotated characters. It supports efficient, non-destructive input consumption and provides detailed position information for each character.

### Utility Types

- `Either<Left, Right>`: Represents values with two possibilities, commonly used for error handling.
- `Tuple<A, B>`, `Triple<A, B, C>`, and `Quadruple<A, B, C, D>`: Facilitate grouping of multiple parsed values.
- Specialized parser typealiases (`UnitParser`, `TapeParser`, `CharParser`, etc.) for common parsing patterns.

## Getting Started

### Installation

Add the Swift Parsing Framework to your project by including it in your `Package.swift` file or by importing it directly into your Xcode project.

### Basic Usage

Here's a simple example of using the framework to parse a numeric string into an integer:

```swift
let digitParser = CharParser.pop { $0.isNumber }.many.map { digits in
    Int(String(digits.map { $0.value })) ?? 0
}

let result = digitParser.evaluate(source: "12345")
// result: 12345
```

This example demonstrates creating a parser for digits, aggregating them into a string, and converting that string into an integer.

## Advanced Examples

For more complex parsing needs, you can compose and chain parsers to handle sophisticated input patterns. The framework's design encourages modular construction of parsers, making it easy to extend and adapt to new requirements.

### Parsing Key-Value Pairs

```swift
let keyParser = CharParser.pop { $0.isLetter }.many.map { String($0) }
let separatorParser = CharParser.char(":").spaced
let valueParser = TapeParser.restOfLine

let keyValueParser = keyParser.and(separatorParser).and(valueParser).map { key, _, value in
    (key, value)
}

let input = "key: value"
let parsedKeyValuePair = keyValueParser.evaluate(source: input)
// parsedKeyValuePair: ("key", "value")
```

## Documentation

For detailed documentation, including all available operations and advanced usage patterns, please refer to the inline documentation within the framework source files.

## Contributing

We welcome contributions and suggestions! Please open an issue or submit a pull request to propose changes or additions.