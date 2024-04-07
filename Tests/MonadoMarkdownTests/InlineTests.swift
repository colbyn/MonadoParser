//
//  File.swift
//  
//
//  Created by Colbyn Wadman on 4/6/24.
//

import Foundation
import XCTest
@testable import MonadoParser
@testable import MonadoMarkdown

final class MonadoParserTests: XCTestCase {
    func testRandom1() throws {
        let sample = "[link text](http://dev.nodeca.com)"
        let parser1 = Mark.Inline.InSquareBrackets.parser(
            content: Mark.Inline.painTextParser(
                env: .root.withScope(inline: .link(.inSquareBraces))
            )
        )
        let parser2 = parser1.and(
            next: Mark.Inline
                .painTextParser(
                    env: .root.withScope(inline: .link(.inRoundBraces))
                )
                .between(
                    leading: IO.CharParser.pop(char: "("),
                    trailing: IO.CharParser.pop(char: ")")
                )
        )
        let (result1, unparsed1) = parser1.evaluate(source: sample)
        let (result2, unparsed2) = parser2.evaluate(source: sample)
        XCTAssertNotNil(result1)
        XCTAssertEqual(result1?.content.asString, "link text")
        XCTAssertEqual(unparsed1.text.asString, "(http://dev.nodeca.com)")
        XCTAssertNotNil(result2)
        XCTAssertEqual(result2?.b.a.value, "("); XCTAssertEqual(result2?.b.b.asString, "http://dev.nodeca.com"); XCTAssertEqual(result2?.b.c.value, ")")
        XCTAssertEqual(unparsed2.text.asString, "")
    }
    func testRandom2() throws {
        let sample1 = "Alpha *Beta Gamma* Delta"
        let sample2 = "Alpha **Beta Gamma** Delta"
        let sample3 = "Alpha ***Beta Gamma*** Delta"
        let parser = Mark.Inline.Emphasis.parser(env: .root)
        let (result1, unparsed1) = parser.evaluate(source: sample1)
        XCTAssertNotNil(result1)
//        XCTAssertEqual(result1?.content)
    }
}
