import Diesel

struct DigitParser: Parser {

  func parse(_ stream: Substring) -> ParseResult<Character, Substring> {
    guard let character = stream.first, character.isNumber
      else { return .error() }
    return .success(character, stream.dropFirst())
  }

}

struct LetterParser: Parser {

  let letter: Character

  func parse(_ stream: Substring) -> ParseResult<Character, Substring> {
    return stream.first == letter
      ? .success(letter, stream.dropFirst())
      : .error()
  }

}

struct DummyDiagnostic: Equatable {
}

/// A parser that parses digits.
let digit = DigitParser()

/// Returns a parser that parses the given letter.
func letter(_ l: Character) -> LetterParser {
  return LetterParser(letter: l)
}
