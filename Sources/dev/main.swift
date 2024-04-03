//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/26/24.
//

import Foundation
import Monado
import Markdown

let source1 = """
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
let source2 = """
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
let source3 = """
This is a multi-line paragraph in Markdown. You can write as much as you want
here and as long as you don't insert a blank line, it will be considered part
of the same paragraph. This allows for natural writing flow similar to
traditional text editors.
The new line here will be treated as a space in HTML.

This is a multi-line paragraph in Markdown. You can write as much as you want here and as long as you don't insert a blank line, it will be considered part of the same paragraph.
This allows for natural writing flow similar to traditional text editors.
The new line here will be treated as a space in HTML.
"""

//let parser = TapeParser.restOfLine
let parser = Block.Paragraph.wholeChunk
//let parser = Block.Blockquote.wholeChunk
//let parser = Block.UnorderedListItem.wholeChunk.some
//let parser = Block.OrderedListItem.wholeChunk.some

let (result, unparsed) = parser.evaluate(source: source3)
if let result = result {
    print("RESULTS:")
    print(result.asPrettyTree.format())
} else {
    print("RESULTS: Error")
}
print("UNPARSED")
print(unparsed.asPrettyTree.format())
