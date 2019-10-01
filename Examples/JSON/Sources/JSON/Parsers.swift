import Diesel

struct CharacterParser: Parser {

  let character: Character

  init(_ character: Character) {
    self.character = character
  }

  func parse(_ stream: Substring) -> ParseResult<Character, Substring> {
    guard stream.first == character
      else { return .error() }
    return .success(character, stream.dropFirst())
  }

}

enum JSONParser {

  // MARK: Basic tokens

  static let leftBrace     = CharacterParser("{")
  static let rightBrace    = CharacterParser("}")
  static let leftBracket   = CharacterParser("[")
  static let rightBracket  = CharacterParser("]")
  static let colon         = CharacterParser(":")
  static let comma         = CharacterParser(",")
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

  static let null = AnyParser<JSONElement, Substring> { stream in
    guard stream.starts(with: "null")
      else { return .error() }
    return .success(.null, stream.dropFirst(4))
  }

  static let positiveNumber = AnyParser<Int, Substring> { stream in
    let characters = stream.prefix(while: { $0.isNumber })
    return characters.isEmpty
      ? .error()
      : .success(Int(String(characters))!, stream.dropFirst(characters.count))
  }

  static let number = CharacterParser("-").optional
    .then(positiveNumber) { (minusSign, number) -> JSONElement in
      .number(minusSign.map { _ in -number } ?? number)
    }

  private static let stringContent = AnyParser<String, Substring> { stream in
    let characters = stream.prefix(while: { $0 != "\"" })
    return .success(String(characters), stream.dropFirst(characters.count))
  }

  static let string = stringContent.surrounded(by: CharacterParser("\""))
    .map { value -> JSONElement in .string(value) }

  private static let listContent = jsonElement
    .then(comma.surrounded(by: whitespace.many)
      .then(jsonElement, combine: { _, rhs in rhs })
      .many)
    { [$0] + $1 }

  static let list = leftBracket
    .then(listContent.optional.surrounded(by: whitespace.many)) { _, rhs in rhs ?? [] }
    .then(rightBracket) { (lhs, _) -> JSONElement in .list(lhs) }

  private static let objectElement = stringContent.surrounded(by: CharacterParser("\""))
    .then(colon.surrounded(by: whitespace.many)) { lhs, _ in lhs }
    .then(jsonElement) { lhs, rhs in JSONObjectElement(key: lhs, value: rhs) }

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
