enum JSONElement {

  case null
  case number(Int)
  case string(String)
  case list([JSONElement])
  case object([JSONObjectElement])

}

extension JSONElement: CustomStringConvertible {

  var description: String {
    switch self {
    case .null:
      return "null"
    case .number(let value):
      return String(describing: value)
    case .string(let value):
      return "\"\(value)\""
    case .list(let content):
      return "[ " + content.map(String.init).joined(separator: ", ") + " ]"
    case .object(let content):
      return "{ " + content.map(String.init).joined(separator: ", ") + " }"
    }
  }

}

struct JSONObjectElement {

  var key: String
  var value: JSONElement

}

extension JSONObjectElement: CustomStringConvertible {

  var description: String {
    return "\"\(key)\": \(value)"
  }

}
