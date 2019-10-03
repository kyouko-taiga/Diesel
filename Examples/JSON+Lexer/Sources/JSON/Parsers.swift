import Diesel

enum JSONParser {

  static func parse(_ input: String) -> JSONElement? {
    guard let tokens = try? tokenize(input)
      else { return nil }
    guard case .success(let element, _) = jsonElement.parse(ArraySlice(tokens))
      else { return nil }
    return element
  }

  private(set) static var jsonElement = ForwardParser<JSONElement, ArraySlice<Token>>()

  static let null = token(.null).map { _ -> JSONElement in .null }

  static let number = token(.number).map { token -> JSONElement in .number(Double(token.value)!) }

  private static let stringLiteral = token(.stringLiteral)
    .map { token in token.value.dropFirst().dropLast() }

  static let string = stringLiteral.map { value -> JSONElement in .string(String(value)) }

  private static let listContent = jsonElement
    .then(token(.comma)
    .then(jsonElement, combine: { _, rhs in rhs })
    .many)
  { [$0] + $1 }

  static let list = token(.leftBracket)
    .then(listContent.optional) { _, rhs in rhs ?? [] }
    .then(token(.rightBracket)) { (lhs, _) -> JSONElement in .list(lhs) }

  private static let objectElement = stringLiteral
    .then(token(.colon)) { lhs, _ in lhs }
    .then(jsonElement) { lhs, rhs in JSONObjectElement(key: String(lhs), value: rhs) }

  private static let objectContent = objectElement
    .then(token(.comma)
      .then(objectElement, combine: { _, rhs in rhs })
      .many)
    { [$0] + $1 }

  static let object = token(.leftBrace)
    .then(objectContent.optional) { _, rhs in rhs ?? [] }
    .then(token(.rightBrace)) { (lhs: [JSONObjectElement], _) -> JSONElement in .object(lhs) }

  static func initialize() {
    jsonElement.define(null
      .else(number)
      .else(string)
      .else(list)
      .else(object))
  }

}

private func token(_ kind: Token.Kind) -> ElementParser<ArraySlice<Token>> {
  return element { $0.kind == kind }
}
