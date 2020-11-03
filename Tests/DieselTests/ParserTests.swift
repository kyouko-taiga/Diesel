import XCTest
import class Foundation.Bundle

import Diesel

final class ParserTests: XCTestCase {

  func testManyParser() {
    let parser = digit.many

    assertThat(parser.parse("")   , .succeeded([], ""))
    assertThat(parser.parse("000"), .succeeded(["0", "0", "0"], ""))
    assertThat(parser.parse("00a"), .succeeded(["0", "0"], "a"))
    assertThat(parser.parse("0a0"), .succeeded(["0"], "a0"))
    assertThat(parser.parse("a00"), .succeeded([], "a00"))
  }

  func testOneOrManyParser() {
    let parser = digit.oneOrMany

    assertThat(parser.parse("")   , .failed())
    assertThat(parser.parse("000"), .succeeded(["0", "0", "0"], ""))
    assertThat(parser.parse("00a"), .succeeded(["0", "0"], "a"))
    assertThat(parser.parse("0a0"), .succeeded(["0"], "a0"))
    assertThat(parser.parse("a00"), .failed())
  }

  func testRepeatParser() {
    let parser = digit.repeated(count: 2)

    assertThat(parser.parse("")   , .failed())
    assertThat(parser.parse("000"), .succeeded(["0", "0"], "0"))
    assertThat(parser.parse("00a"), .succeeded(["0", "0"], "a"))
    assertThat(parser.parse("0a0"), .failed())
    assertThat(parser.parse("a00"), .failed())
  }

  func testTransformParser() {
    let parser = digit.map { digit in Int(String(digit))! }

    assertThat(parser.parse("") , .failed())
    assertThat(parser.parse("a"), .failed())
    assertThat(parser.parse("0"), .succeeded(0, ""))
  }

  func testFallibleTransformParser() {
    struct ZeroError: Error {
    }

    let parser = digit.map { (digit) -> Int in
      guard digit != "0"
        else { throw ZeroError() }
      return Int(String(digit))!
    }

    assertThat(parser.parse("") , .failed())
    assertThat(parser.parse("a"), .failed())
    assertThat(parser.parse("0"), .failed())
    assertThat(parser.parse("1"), .succeeded(1, ""))
  }

  func testCombineParser() {
    let parser = digit.then(digit).map { String([$0.0, $0.1]) }

    assertThat(parser.parse("")   , .failed())
    assertThat(parser.parse("0")  , .failed())
    assertThat(parser.parse("000"), .succeeded("00", "0"))
  }

  func testEitherParser() {
    let parser = letter("a").or(letter("b"))

    assertThat(parser.parse("") , .failed())
    assertThat(parser.parse("0"), .failed())
    assertThat(parser.parse("a"), .succeeded("a", ""))
    assertThat(parser.parse("b"), .succeeded("b", ""))
  }

  func testCatchParser() {
    let parser = digit.catch { _, stream in .success("_", stream) }

    assertThat(parser.parse("0"), .succeeded("0", ""))
    assertThat(parser.parse("a"), .succeeded("_", "a"))
  }

  func testOptionalParser() {
    let parser = digit.optional

    assertThat(parser.parse("0"), .succeeded("0", ""))
    assertThat(parser.parse("a"), .succeeded(nil, "a"))
  }

  func testForwardParser() {
    do {
      let parser = ForwardParser<Character, Substring>()
      parser.define(digit)
      assertThat(parser.parse("0"), .succeeded("0", ""))
    }

    do {
      let parser = ForwardParser<Character, Substring>()
      parser.define(digit.parse)
      assertThat(parser.parse("0"), .succeeded("0", ""))
    }
  }

  func testAnyParser() {
    assertThat(AnyParser(digit).parse("0"), .succeeded("0", ""))
    assertThat(AnyParser(digit.parse).parse("0"), .succeeded("0", ""))
  }

  func testSurroundedParser() {
    let parser = letter("a").surrounded(by: digit)

    assertThat(parser.parse("0a0"), .succeeded("a", ""))
    assertThat(parser.parse("0a"), .failed())
  }

}
