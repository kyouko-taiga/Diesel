extension Parser where Stream == Substring {

  func parse(_ string: String) -> ParseResult<Element, Substring> {
    return parse(Stream(string))
  }

}
