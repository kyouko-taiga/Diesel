struct LexerError: Error {

  let location: String.Index

}

func tokenize(_ stream: String) throws -> [Token] {
  var tokens: [Token] = []
  var currentIndex = stream.startIndex

  while currentIndex != stream.endIndex {
    // Ignore whitespaces
    if stream[currentIndex].isWhitespace {
      currentIndex = stream.index(after: currentIndex)
      continue
    }

    // Check for 1-character tokens.
    var kind: Token.Kind?
    switch stream[currentIndex] {
    case "{": kind = .leftBrace
    case "}": kind = .rightBrace
    case "[": kind = .leftBracket
    case "]": kind = .rightBracket
    case ",": kind = .comma
    case ":": kind = .colon
    default : break
    }
    if let k = kind {
      let nextIndex = stream.index(after: currentIndex)
      tokens.append(Token(kind: k, value: stream[currentIndex ..< nextIndex]))
      currentIndex = nextIndex
      continue
    }

    // Check for numbers.
    if stream[currentIndex].isNumber || stream[currentIndex] == "-" {
      var numberEndIndex = stream.index(after: currentIndex)
      var didParseDot = false

      while numberEndIndex != stream.endIndex {
        if stream[numberEndIndex] == "." {
          guard !didParseDot
            else { throw LexerError(location: numberEndIndex) }
          didParseDot = true
        } else if !stream[numberEndIndex].isNumber {
          break
        }

        numberEndIndex = stream.index(after: numberEndIndex)
      }

      let value = stream[currentIndex ..< numberEndIndex]
      guard value != "-"
        else { throw LexerError(location: currentIndex) }

      tokens.append(Token(kind: .number, value: value))
      currentIndex = numberEndIndex
      continue
    }

    // Check for string literals.
    if stream[currentIndex] == "\"" {
      var literalEndIndex = stream.index(after: currentIndex)
      while literalEndIndex != stream.endIndex {
        guard stream[literalEndIndex] != "\"" else {
          literalEndIndex = stream.index(after: literalEndIndex)
          break
        }
        literalEndIndex = stream.index(after: literalEndIndex)
      }

      tokens.append(Token(kind: .stringLiteral, value: stream[currentIndex ..< literalEndIndex]))
      currentIndex = literalEndIndex
      continue
    }

    // Check for null.
    if stream.suffix(from: currentIndex).starts(with: "null") {
      let nextIndex = stream.index(currentIndex, offsetBy: 4)
      tokens.append(Token(kind: .null, value: stream[currentIndex ..< nextIndex]))
      currentIndex = nextIndex
      continue
    }

    throw LexerError(location: currentIndex)
  }

  return tokens
}
