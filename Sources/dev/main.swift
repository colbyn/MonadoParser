//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/26/24.
//

import Foundation
import MonadoParser
import MonadoMarkdown
import PrettyTree
import ExtraMonadoUtils

fileprivate let source1 = """
- Boil water in a kettle.
  - Use filtered water for a better taste.

 - Place a tea bag in your cup.
  - Green tea for a lighter flavor.
  - Black tea for a stronger flavor.
- Pour boiling water into the cup.
- Let the tea steep for 3-5 minutes.
  - 3 minutes for a lighter taste.
  - 5 minutes for a stronger brew.
- Enjoy your tea.
  - Add honey or lemon if desired.
"""
fileprivate let source2 = """
1. Boil water in a kettle.
    - Use filtered water for a better taste.
2. Place a tea bag in your cup.
    - Green tea for a lighter flavor.
    - Black tea for a stronger flavor.
3. Pour boiling water into the cup.
4. Let the tea steep for 3-5 minutes.
    - 3 minutes for a lighter taste.
    - 5 minutes for a stronger brew.
5. Enjoy your tea.
    - Add honey or lemon if desired.
"""
fileprivate let source3 = """
- AAA
  - A1
    > 1 Hello World
    > 2 Hello World
  - A2
  - A3
- BBB
    - B1
    - B2
    - B3
- CCC
    - C1
    - C2
    - C3
1. 111
    - 1.1
    - 1.2
    - 1.3
2. 222
    - 2.1
    - 2.2
    - 2.3
3. 333
    - 3.1
    - 3.2
    - 3.3
"""
let sample = markdownSourceCodeExample6

//let parser = IO.CharParser.pop
//let parser = Mark.Inline.some(env: .root)
//let parser = Mark.Inline.Emphasis.parser(env: .root)
//let parser = Mark.Inline.PlainText.parser(env: .root.withScope(inline: .emphasis(.single("*"))))
//let parser1 = Mark.some(env: .root)
let parser = Mark.some(env: .root)

let (result, unparsed) = parser.evaluate(source: sample)
if let result = result {
    header(label: "RESULTS")
    print(result.asPrettyTree.format())
} else {
    header(label: "ERROR!")
}
header(label: "FINAL PARSER STATE")
print(unparsed.asPrettyTree.format())
header(label: "UNPARSED")
print(unparsed.text.asString.truncated(limit: 300, position: .tail))

func header(label: String) {
    print(String.init(repeating: "—", count: 120))
    print("▷ \(label)")
    print(String.init(repeating: "—", count: 120))
}
