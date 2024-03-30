//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 3/28/24.
//

import Foundation
import Monado
import PrettyTree
//import ExtraUtils

extension Markdown {
    public static func main() {
//        let source1 = """
//        # Hello World!
//        * Item 1
//        * Item 2
//          * Subitem 2.1
//          * Subitem 2.2
//        * Item 3
//        + Item 1
//        + Item 2
//          + Subitem 2.1
//          + Subitem 2.2
//        + Item 3
//        - Item 1
//        - Item 2
//          - Subitem 2.1
//          - Subitem 2.2
//        - Item 3
//        """
        let source2 = """
        # Paragraphs
        
        In Markdown, you can make text *italic* by wrapping it in asterisks (`*`) or underscores (`_`). To make text **bold**, use two asterisks or underscores 1.
        
        For ***bold and italic***, use three asterisks or underscores 2.
        
        You can create a link by wrapping the link text in brackets (`[]`), followed by the URL in parentheses (`()`): [OpenAI](https://www.openai.com) Similarly to links, you can include an image by adding an exclamation mark (`!`), followed by the alt text in brackets, and the image URL in parentheses: ![OpenAI Logo](https://example.com/openai_logo.png)
        
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        
        ## Lists
        Markdown supports ordered and unordered lists.

        ### Unordered Lists
        - Item 1
        - Item 2
          - Subitem 2.1
          - Subitem 2.2

        ### Ordered Lists
        1. First item
        2. Second item
           1. Subitem 2.1
           2. Subitem 2.2

        ## Links
        You can create a link by wrapping the link text in brackets (`[]`), followed by the URL in parentheses (`()`):

        [OpenAI](https://www.openai.com)

        ## Images
        Similarly to links, you can include an image by adding an exclamation mark (`!`), followed by the alt text in brackets, and the image URL in parentheses:

        ![OpenAI Logo](https://example.com/openai_logo.png)

        ## Code
        You can present code by wrapping it in backticks (`). For inline code, use a single backtick:

        `<div class="container">`

        For a block of code, use three backticks or indent with four spaces:
        
        ## Fenced Code Blocks
        
        ```
        function main() {}
        ```
        
        ## With Language
        
        ```json
        {
          "firstName": "John",
          "lastName": "Smith",
          "age": 25
        }
        ```
        """
//        let source3 = """
//        You can present code by wrapping it in backticks (`). For inline code, use a single backtick:
//        
//        ```
//        function main() {}```
//        
//        ## Json Example
//        ```json
//        {
//          "firstName": "John",
//          "lastName": "Smith",
//          "age": 25
//        }
//        ```
//        """
        let parser = Markdown.blockParser(env: .root).many
//        let parser = Markdown.blockParser(env: .root)
//        let parser = TapeParser.untilEndOfLine
        let (result, unparsed) = parser.evaluate(source: source2)
        if let result = result {
            print("RESULTS:")
            print(result.asPrettyTree.format())
        } else {
            print("RESULTS: Error")
        }
        print("UNPARSED")
        print(unparsed.asPrettyTree.format())
    }
}
