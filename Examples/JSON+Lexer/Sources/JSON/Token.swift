struct Token {

  enum Kind {
    case leftBrace
    case rightBrace
    case leftBracket
    case rightBracket
    case colon
    case comma
    case null
    case number
    case stringLiteral
  }

  let kind: Kind
  let value: Substring

}
