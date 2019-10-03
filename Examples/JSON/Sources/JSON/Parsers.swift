import Diesel

func character(_ character: Character) -> ElementParser<Substring> {
  return parser(of: character)
}

enum JSONParser {

  // MARK: Basic tokens

  static let leftBrace     = character("{")
  static let rightBrace    = character("}")
  static let leftBracket   = character("[")
  static let rightBracket  = character("]")
  static let colon         = character(":")
  static let comma         = character(",")
  static let whitespace    = AnyParser<Character, Substring> { stream in
    guard let character = stream.first, character.isWhitespace
      else { return .error() }
    return .success(character, stream.dropFirst())
  }

  // MARK: JSON elements

  static func parse(_ input: String) -> JSONElement? {
    guard case .success(let element, _) = jsonElement.parse(Substring(input))
      else { return nil }
    return element
  }

  private(set) static var jsonElement = ForwardParser<JSONElement, Substring>()

  static let null = parser(of: "null").map { _ -> JSONElement in .null }

  static let number = parser(matching: "-?(?:0|[1-9][0-9]*)(?:\\.[0-9]*)?")
    .map { value -> JSONElement in .number(Double(value)!) }

  private static let stringLiteral = parser(matching: "\"[^\"]*\"")
    .map { $0.dropFirst().dropLast() }

  static let string = stringLiteral.map { value -> JSONElement in .string(String(value)) }

  private static let listContent = jsonElement
    .then(comma.surrounded(by: whitespace.many)
      .then(jsonElement, combine: { _, rhs in rhs })
      .many)
    { [$0] + $1 }

  static let list = leftBracket
    .then(listContent.optional.surrounded(by: whitespace.many)) { _, rhs in rhs ?? [] }
    .then(rightBracket) { (lhs, _) -> JSONElement in .list(lhs) }

  private static let objectElement = stringLiteral
    .then(colon.surrounded(by: whitespace.many)) { lhs, _ in lhs }
    .then(jsonElement) { lhs, rhs in JSONObjectElement(key: String(lhs), value: rhs) }

  private static let objectContent = objectElement
    .then(comma.surrounded(by: whitespace.many)
      .then(objectElement, combine: { _, rhs in rhs })
      .many)
    { [$0] + $1 }

  static let object = leftBrace
    .then(objectContent.optional.surrounded(by: whitespace.many)) { _, rhs in rhs ?? [] }
    .then(rightBrace) { (lhs: [JSONObjectElement], _) -> JSONElement in .object(lhs) }

  static func initialize() {
    jsonElement.define(null
      .else(number)
      .else(string)
      .else(list)
      .else(object))
  }

}
