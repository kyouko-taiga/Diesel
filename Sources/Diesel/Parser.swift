/// A type that implements a parser.
///
/// A parser can be understood as a function of the form `(Stream) -> (Element, Stream) | Error`
/// that attempts to extract a valid output out a a given stream. If it succeeds, it returns said
/// output, together with an "updated" stream, corresponding to the remainder of the input. If it
/// fails, it simply returns an error.
///
/// For example, consider the task of reading a single digit out of a character string. Such a
/// parser could be implemented as a function `(String) -> (Character, String) | Error`, that
/// either successfully reads a digit from the beginning of the string, or just fails. In more
/// concrete terms, it could be wrote as follows:
///
///     func parseDigit(from string: String) -> ParseResult<Character, String> {
///       guard let character = string.first, character.isNumber
///         else { return .error() }
///       return .success(character, String(string.dropFirst()))
///     }
///
/// One advantage of this approach is that is that parsers (i.e. parsing functions) can be
/// *combined* to create other parsers. For example, one could create a parser for two-digit
/// numbers by reusing the above function twice, feeding the result of its first application to a
/// second one. Note however that such a combination does not simply boils down to function
/// composition, as one has to care for cases in which the first application does not succeeds,
/// which unfertunately leads significant boilerplate.
///
/// The `Parser` protocol defines an interface for types that represent such parsing functions, and
/// provides so-called "combinators" to combine them and form more complex parsers. For example,
/// the `parseDigit` function may be wrapped within an `AnyParser` instance to provide it with
/// these combinators, in order to produce `parseTwoDigit` parser as follows:
///
///     let digit = AnyParser(parseDigit)
///     let twoDigits = digit.then(digit)
///
/// # Performance Considerations
///
/// Note that upon success, a parser necessarily produces a new stream, which is then fed to the
/// next parser. While this has the advantage to keep the stream immutable, this may induce
/// significant memory traffic if the new "updated" stream is a copy of its precedessor. To avoid
/// such pitfalls, consider using types that simply provide a *view* of an underlying buffer, such
/// as `Substring` for character strings, or `ArraySlice` for arrays.
public protocol Parser {

  associatedtype Element
  associatedtype Stream

  /// Attempts to parse the given stream to extract a valid output.
  ///
  /// - Parameter stream: The stream to parse
  /// - Returns:
  ///     Either pair containing the parsed element and the remainder of the stream, or a parse
  ///     error if the element could not be parsed.
  func parse(_ stream: Stream) -> ParseResult<Element, Stream>

}

/// The result of a parser.
public enum ParseResult<Element, Stream> {

  case success(Element, Stream)
  case failure(ParseError)

  public static func error(diagnostic: Any? = nil) -> ParseResult {
    return .failure(ParseError(diagnostic: diagnostic))
  }

}

/// A parse error.
public struct ParseError: Error {

  /// A diagnostic that provides information about this parse error.
  public let diagnostic: Any?

  public init(diagnostic: Any? = nil) {
    self.diagnostic = diagnostic
  }

}

/// A parser that attempts to apply another parser as many times as possible.
public struct ManyParser<Base>: Parser where Base: Parser {

  private let base: Base

  public init(_ base: Base) {
    self.base = base
  }

  public func parse(_ stream: Base.Stream) -> ParseResult<[Base.Element], Base.Stream> {
    var elements: [Base.Element] = []
    var remainder = stream

    while case .success(let newElement, let newRemainder) = base.parse(remainder) {
      elements.append(newElement)
      remainder = newRemainder
    }

    return .success(elements, remainder)
  }

}

/// A parser that transforms the result of another parser, if the latter is successful.
public struct TransformParser<Base, Element>: Parser where Base: Parser {

  private let base: Base
  private let transform: (Base.Element) -> Element

  public init(_ base: Base, transform: @escaping (Base.Element) -> Element) {
    self.base = base
    self.transform = transform
  }

  public func parse(_ stream: Base.Stream) -> ParseResult<Element, Base.Stream> {
    switch base.parse(stream) {
    case .success(let output, let remainder):
      return .success(transform(output), remainder)
    case .failure(let error):
      return .failure(error)
    }
  }

}

/// A parser that chains two parsers.
public struct CombineParser<First, Second, Element>: Parser
  where First: Parser, Second: Parser, First.Stream == Second.Stream
{

  private let first: First
  private let second: Second
  private let combine: (First.Element, Second.Element) -> Element

  public init(
    first: First,
    second: Second,
    combine: @escaping (First.Element, Second.Element) -> Element)
  {
    self.first = first
    self.second = second
    self.combine = combine
  }

  public func parse(_ stream: First.Stream) -> ParseResult<Element, First.Stream> {
    let firstResult = first.parse(stream)
    guard case .success(let firstOutput, let firstRemainder) = firstResult else {
      guard case .failure(let error) = firstResult
        else { unreachable() }
      return .failure(error)
    }

    let secondResult = second.parse(firstRemainder)
    guard case .success(let secondOutput, let secondRemainder) = secondResult else {
      guard case .failure(let error) = secondResult
        else { unreachable() }
      return .failure(error)
    }

    return .success(combine(firstOutput, secondOutput), secondRemainder)
  }

}

/// A parser that attempts to apply a first parser, or a second if the former fails.
public struct EitherParser<First, Second>: Parser
  where First: Parser, Second: Parser,
        First.Stream == Second.Stream, First.Element == Second.Element
{

  private let first: First
  private let second: Second

  public init(first: First, second: Second) {
    self.first = first
    self.second = second
  }

  public func parse(_ stream: First.Stream) -> ParseResult<First.Element, First.Stream> {
    let firstResult = first.parse(stream)
    if case .success = firstResult {
      return firstResult
    }

    let secondResult = second.parse(stream)
    guard case .success = secondResult else {
      guard case .failure(let error) = secondResult
        else { unreachable() }
      return .failure(error)
    }

    return secondResult
  }

}

/// A parser that transforms the result of a failed parser.
public struct CatchParser<Base>: Parser where Base: Parser {

  private let base: Base
  private let handler: (ParseError, Base.Stream) -> ParseResult<Base.Element, Base.Stream>

  public init(
    _ base: Base,
    handler: @escaping (ParseError, Base.Stream) -> ParseResult<Base.Element, Base.Stream>)
  {
    self.base = base
    self.handler = handler
  }

  public func parse(_ stream: Base.Stream) -> ParseResult<Base.Element, Base.Stream> {
    let result = base.parse(stream)
    switch result {
    case .success:
      return result
    case .failure(let error):
      return handler(error, stream)
    }
  }

}

/// A parser that attempts to apply another parser, or skips the stream if the latter fails.
public struct OptionalParser<Base>: Parser where Base: Parser {

  private let base: Base

  public init(_ base: Base) {
    self.base = base
  }

  public func parse(_ stream: Base.Stream) -> ParseResult<Base.Element?, Base.Stream> {
    guard case .success(let element, let remainder) = base.parse(stream)
      else { return .success(nil, stream) }

    return .success(element, remainder)
  }

}

/// A parser that might have been forward declared.
public final class ForwardParser<Element, Stream>: Parser {

  private var _parse: ((Stream) -> ParseResult<Element, Stream>)?

  public init() {}

  /// Defines this parser.
  ///
  /// Note that defining a forward parser multiple times will trigger a runtime error.
  ///
  /// - Parameter parser: The parser corresponding to this forward parser.
  public func define<P>(_ parser: P) where P: Parser, P.Stream == Stream, P.Element == Element {
    precondition(_parse == nil, "parser was already defined")
    self._parse = parser.parse
  }

  /// Defines this parser.
  ///
  /// Note that defining a forward parser multiple times will trigger a runtime error.
  ///
  /// - Parameter parse: A function representing the parser corresponding to this forward parser.
  public func define(_ parse: @escaping (Stream) -> ParseResult<Element, Stream>) {
    precondition(_parse == nil, "parser was already defined")
    self._parse = parse
  }

  public func parse(_ stream: Stream) -> ParseResult<Element, Stream> {
    precondition(_parse != nil, "parser is not defined")
    return _parse!(stream)
  }

}

/// A type-erased parser.
public struct AnyParser<Element, Stream>: Parser {

  private let _parse: (Stream) -> ParseResult<Element, Stream>

  /// Creates a type-erased parser from an existing parser.
  ///
  /// - Parameter parser: An existing parser.
  public init<P>(_ parser: P) where P: Parser, P.Stream == Stream, P.Element == Element {
    self._parse = parser.parse
  }

  /// Creates a type-erased parser from a function representing a parser.
  ///
  /// - Parameter parse: A function representing a parser.
  public init(_ parse: @escaping (Stream) -> ParseResult<Element, Stream>) {
    self._parse = parse
  }

  public func parse(_ stream: Stream) -> ParseResult<Element, Stream> {
    return _parse(stream)
  }

}

extension Parser {

  /// Wraps this parser within a many combinator, resulting in a parser that parses this parser's
  /// element as many times as possible. The resulting parser is successful even if the element
  /// cannot be parsed once, and produces an empty array.
  ///
  /// The following example creates a parser that parses sequences of `a` at the beginning of a
  /// character string, and uses it to parse the prefix of a string:
  ///
  ///     let a = character("a")
  ///     print(a.many.parse("aabbaa"))
  ///     // Prints `success(["a", "a"], "bbaa")`
  public var many: ManyParser<Self> {
    return ManyParser(self)
  }

  /// Wraps this parser within an optional combinator, resulting in a parser that never fails,
  /// either successfully parsing this parser's element, or producing `nil`.
  ///
  /// The following example creates a parser that attempts to parse `a` at the beginning of a
  /// character string or skips the input if it cannot:
  ///
  ///     let a = character("a")
  ///     print(a.optional.parse("foo"))
  ///     // Prints `success(nil, "foo")`
  public var optional: OptionalParser<Self> {
    return OptionalParser(self)
  }

  /// Wraps this parser within a transform combinator, resulting in a parser that transforms the
  /// parsed element with the given function if successful.
  ///
  /// The following example creates a parser that parses a sequence of digits at the beginning of a
  /// character string and transforms it into an integer if it is successful.
  ///
  ///     let digit = character { $0.isNumber }
  ///     let integer = digit.many.map { digits in digits.isEmpty? 0 Int(String(digits))! }
  ///     print(integer.parse("123abc"))
  ///     // Prints `success(123, "abc")`
  ///
  /// - Parameter transform: A transform function.
  /// - Returns: This parser wrapped within a transform combinator.
  public func map<R>(_ transform: @escaping (Element) -> R) -> TransformParser<Self, R> {
    return TransformParser(self, transform: transform)
  }

  /// Wraps this parser and another within a combine combinator, resulting in a parser that parses
  /// both parsers' elements in sequence.
  ///
  /// The following example creates a parser that parses the letters `a` and `b` at the beginning
  /// of a character string:
  ///
  ///     let p = character("a").then(character("b"))
  ///     print(p.parse("abc"))
  ///     // Prints `success(("a", "b"), "c")`
  ///
  /// - Parameter parser: A parser for the element to parse next.
  /// - Returns: This and another wrapped within a combine combinator.
  public func then<P>(_ parser: P) -> CombineParser<Self, P, (Element, P.Element)> where P: Parser {
    return CombineParser(first: self, second: parser) { ($0, $1) }
  }

  /// Wraps this parser and another within a combine combinator, resulting in a parser that parses
  /// both parsers' elements in sequence.
  ///
  /// The method accepts an additional `combine` function that can be used to define how the
  /// results of both parsers should be combined. The following exemple creates a parser that
  /// parses two characters at the beginning of a character string but only keeps the second one:
  ///
  ///     let p = character("a").then(character("b")) { _, snd in snd }
  ///     print(p.parse("abc"))
  ///     // Prints `success("b", "c")`
  ///
  /// - Parameters:
  ///   - parser: A parser for the element to parse next.
  ///   - combine: A transform function that combines both parsed elements.
  /// - Returns: This parser and another wrapped within a combine combinator.
  public func then<P, R>(_ parser: P, combine: @escaping (Element, P.Element) -> R)
    -> CombineParser<Self, P, R>
    where P: Parser
  {
    return CombineParser(first: self, second: parser, combine: combine)
  }

  /// Wraps this parser and another within an either combinator, resulting in a parser that either
  /// parses the this parser's element, or falls back to the second if it fails.
  ///
  /// The following example creates a parser that attempts to parses `a` at the begining of
  /// character string, and fallsback to parsing a `b` if it fails:
  ///
  ///     let p = character("a").else(character("b"))
  ///     print(p.parse("bcd"))
  ///     // Prints `success("b", "cd")`
  ///
  /// - Parameter parser: A parser to which fall back if this parser fails.
  /// - Returns: This parser and another wrapped within a combine combinator.
  public func `else`<P>(_ parser: P) -> EitherParser<Self, P>
    where P: Parser, P.Stream == Stream, P.Element == Element
  {
    return EitherParser(first: self, second: parser)
  }

  /// Wraps this parser within a catch combinator, resulting in a parser that applies the given
  /// handler if it fails.
  ///
  /// The following example creates a parser that either successfully parses `a` at the beginning
  /// of a character string, or produces `_` if it fails:
  ///
  ///     let a = character("a")
  ///     let p = a.catch { _, stream in .success("_", stream) }
  ///     print(p.parse("bcd"))
  ///     // Prints `success("_", "bcd")`
  ///
  /// - Parameter handler: A handler to call if the parser fails.
  /// - Returns: This parser wrapped within a catch combinator.
  public func `catch`(_ handler: @escaping (ParseError, Stream) -> ParseResult<Element, Stream>)
    -> CatchParser<Self>
  {
    return CatchParser(self, handler: handler)
  }

  /// Returns a parser that parses this parser's element, surrounded by elements of the given
  /// parser.
  ///
  /// The following example creates a parser that parses `b` surrounded by `a`s at the beginning
  /// of a character string:
  ///
  ///     let p = character("b").surrounded(by: character("a").many)
  ///     print(p.parse("aabccd"))
  ///     // Prints `success("b", "ccd")`
  ///
  /// - Parameter parser: A parser for the elements that should surrounds this parser's element.
  /// - Returns: A transformed parser.
  public func surrounded<P>(by parser: P) -> AnyParser<Element, Stream>
    where P: Parser, P.Stream == Stream
  {
    let p = parser
      .then(self) { _, rhs in rhs }
      .then(parser) { lhs, _ in lhs }
    return AnyParser(p)
  }

}

private func unreachable() -> Never {
  fatalError()
}
