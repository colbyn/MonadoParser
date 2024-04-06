import XCTest
@testable import MonadoParser

final class MonadoParserTests: XCTestCase {
    func testRandom1() throws {
        let sample = "Hello World!"
        let p1 = IO.TextParser.token("Hello World")
        let p2 = IO.CharParser.next
        let p3 = p1.and(next: p2)
        let (result1, unparsed1) = p1.evaluate(source: sample)
        let (result2, unparsed2) = p2.evaluate(source: sample)
        let (result3, unparsed3) = p3.evaluate(source: sample)
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
        XCTAssertEqual(result1?.asString, "Hello World")
        XCTAssertEqual(result2?.singleton.asString, "H")
        XCTAssertEqual(result3?.a.asString, "Hello World")
        XCTAssertEqual(result3?.b.singleton.asString, "!")
        XCTAssertEqual(unparsed1.text.asString, "!")
        XCTAssertEqual(unparsed2.text.asString, "ello World!")
        XCTAssertEqual(unparsed3.text.asString, "")
    }
    func testRandom2() {
        let sample = "Hello World!"
        let parser1 = IO.CharParser.char { $0.isLetter }.some
        let parser2 = IO.CharParser.char { $0.isSymbol }.some
        let (result1, unparsed1) = parser1.evaluate(source: sample)
        let (result2, unparsed2) = parser2.evaluate(source: sample)
        XCTAssertNotNil(result1)
        XCTAssertEqual(unparsed1.text.asString, " World!")
        XCTAssertNil(result2)
    }
    func testRandom3() {
        let sample = "Hello World"
        let parser1 = IO.CharParser.char { $0.isLetter }.some
        let parser2 = IO.CharParser.char { $0.isSymbol }.some
        
//        let (result, unparsed) = parser.evaluate(source: sample)
//        XCTAssertNotNil(result)
//        XCTAssertEqual(unparsed.text.asString, " World!")
    }
}
