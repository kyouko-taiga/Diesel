import XCTest
import Diesel

final class CommonTests: XCTestCase {

  func testElementParser() {
    let a = element(in: Substring.self, satisfying: { $0.isNumber })
    assertThat(a.parse("0a"), .succeeded("0", "a"))

    let b = element(in: Substring.self, satisfying: { $0.isNumber }, onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testEquatableElementParser() {
    let a = element(in: Substring.self, equalsTo: Character("a"))
    assertThat(a.parse("a0"), .succeeded("a", "0"))

    let b = element(in: Substring.self, equalsTo: Character("b"), onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testCharacterParser() {
    let a = character("a")
    assertThat(a.parse("a0"), .succeeded("a", "0"))

    let b = character("b", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testEquatableSequenceParser() {
    let a = prefix(in: Substring.self, equalsTo: "abc")
    assertThat(a.parse("abc0"), .succeeded("abc", "0"))

    let b = prefix(in: Substring.self, equalsTo: "abc", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testSubstringParser() {
    let a = substring("abc")
    assertThat(a.parse("abc0"), .succeeded("abc", "0"))

    let b = substring("abc", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testRegularExpressionParser() {
    let a = substring(matching: "[^ ]*\\.swift")

    assertThat(a.parse("abc.swift") , .succeeded("abc.swift", ""))
    assertThat(a.parse("abc.swift "), .succeeded("abc.swift", " "))
    assertThat(a.parse(" abc.swift"), .failed())

    let b = substring(matching: "[^ ]*\\.swift", onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

}
