import XCTest
import Diesel

final class CommonTests: XCTestCase {

  func testElementParser() {
    let a = parser(of: Character("a"), in: Substring.self)
    assertThat(a.parse("a0"), .succeeded("a", "0"))

    let b = parser(of: Character("b"), in: Substring.self, onFailure: String.init)
    assertThat(b.parse("---"), .failed(withDiagnostic: "---"))
  }

  func testSequenceParser() {
    let a = parser(of: "abc", in: Substring.self)
    assertThat(a.parse("abc0"), .succeeded("abc", "0"))

    let b = parser(of: "abc", in: Substring.self, onFailure: String.init)
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
