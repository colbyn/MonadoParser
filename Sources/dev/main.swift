//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/26/24.
//

import Foundation
import Monado
import Markdown

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
fileprivate let sample = """
> A
> B
> C
"""

//let parser = Parser
//    .options([
//        Block.UnorderedListItem.parser(env: .root).map(Block.unorderedListItem),
//        Block.OrderedListItem.parser(env: .root).map(Block.orderedListItem),
//        CharParser.newline.map(Block.newline),
//    ])
//    .many
//let parser = CharParser.next
let parser1 = TapeParser.pop("- ").and(
    UnitParser.bounded(
        extract: TapeParser.wholeIndentedBlock(deindent: true),
        execute: Parser
            .options([
                TapeParser.pop("Hello World"),
                TapeParser.pop("\n"),
            ])
            .many
    )
)
let parser = UnitParser.lines(lineStart: TapeParser.pop("> "))

let (result, unparsed) = parser.evaluate(source: sample)
if let result = result {
    header(label: "RESULTS")
    print(result.asPrettyTree.format())
} else {
    header(label: "ERROR!")
}
header(label: "FINAL PARSER STATE!")
print(unparsed.asPrettyTree.format())
header(label: "UNPARSED")
print(unparsed.tape.asString.truncated(limit: 300, position: .tail))

func header(label: String) {
    print(String.init(repeating: "—", count: 120))
    print("▷ \(label)")
    print(String.init(repeating: "—", count: 120))
}
