import XCTest
import Diesel

final class CommonTests: XCTestCase {

  func testElementParser() {
    let a = parser(in: Substring.self, satisfying: { $0.isNumber })
    assertThat(a.parse("0a"), .succeeded("0", "a"))

    let b = parser(in: Substring.self, satisfying: { $0.isNumber }, onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testEquatableElementParser() {
    let a = parser(in: Substring.self, of: Character("a"))
    assertThat(a.parse("a0"), .succeeded("a", "0"))

    let b = parser(in: Substring.self, of: Character("b"), onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testCharacterParser() {
    let a = parser(of: Character("a"))
    assertThat(a.parse("a0"), .succeeded("a", "0"))

    let b = parser(of: Character("b"), onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testEquatableSequenceParser() {
    let a = parser(in: Substring.self, of: "abc")
    assertThat(a.parse("abc0"), .succeeded("abc", "0"))

    let b = parser(in: Substring.self, of: "abc", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testSubstringParser() {
    let a = parser(of: "abc")
    assertThat(a.parse("abc0"), .succeeded("abc", "0"))

    let b = parser(of: "abc", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testRegularExpressionParser() {
    let a = parser(matching: "[^ ]*\\.swift")

    assertThat(a.parse("abc.swift") , .succeeded("abc.swift", ""))
    assertThat(a.parse("abc.swift "), .succeeded("abc.swift", " "))
    assertThat(a.parse(" abc.swift"), .failed())

    let b = parser(matching: "[^ ]*\\.swift", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

}
