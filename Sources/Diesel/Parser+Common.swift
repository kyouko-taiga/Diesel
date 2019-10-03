import Foundation

/// A parser that parses one element satisfying a given predicate at the beginning of the stream.
public struct ElementParser<Stream>: Parser
  where Stream: Collection, Stream.SubSequence == Stream
{

  public typealias Element = Stream.Element

  private let predicate: (Element) -> Bool
  private let onFailure: (Stream) -> Any?

  public init(predicate: @escaping (Element) -> Bool, onFailure: @escaping (Stream) -> Any?) {
    self.predicate = predicate
    self.onFailure = onFailure
  }

  public func parse(_ stream: Stream) -> ParseResult<Element, Stream> {
    guard let first = stream.first, predicate(first)
      else { return .error(diagnostic: onFailure(stream)) }
    return .success(first, stream.dropFirst())
  }

}

/// Creates a parser that parses one element satisfying a predicate at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - predicate: The predicate to satisfy.
/// - Returns: An element parser.
public func element<Stream>(
  in streamType: Stream.Type = Stream.self,
  satisfying predicate: @escaping (Stream.Element) -> Bool)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.SubSequence == Stream
{
  return ElementParser(predicate: predicate, onFailure: { _ in nil })
}

/// Creates a parser that parses one element satisfying a predicate at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - predicate: The predicate to satisfy.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func element<Stream>(
  in streamType: Stream.Type = Stream.self,
  satisfying predicate: @escaping (Stream.Element) -> Bool,
  onFailure: @escaping (Stream) -> Any?)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.SubSequence == Stream
{
  return ElementParser(predicate: predicate, onFailure: onFailure)
}

/// Creates a parser that parses one specific element at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - element: The element to parse.
/// - Returns: An element parser.
public func element<Stream>(
  in streamType: Stream.Type = Stream.self,
  equalsTo subject: Stream.Element)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(predicate: { $0 == subject }, onFailure: { _ in nil })
}

/// Creates a parser that parses one specific element at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - element: The element to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func element<Stream>(
  in streamType: Stream.Type = Stream.self,
  equalsTo subject: Stream.Element,
  onFailure: @escaping (Stream) -> Any?)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(predicate: { $0 == subject }, onFailure: onFailure)
}

/// A parser that parses a specific prefix.
public struct PrefixParser<C, Stream>: Parser
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{

  public typealias Element = C

  private let subject: C
  private let onFailure: (Stream) -> Any?

  public init(subject: C, onFailure: @escaping (Stream) -> Any?) {
    self.subject = subject
    self.onFailure = onFailure
  }

  public func parse(_ stream: Stream) -> ParseResult<C, Stream> {
    guard stream.starts(with: subject)
      else { return .error(diagnostic: onFailure(stream)) }
    return .success(subject, stream.dropFirst(subject.count))
  }

}

/// Creates a parser that parses a specific prefix.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - sequence: The sequence to parse.
/// - Returns: An element parser.
public func prefix<Stream, C>(
  in streamType: Stream.Type = Stream.self,
  equalsTo subject: C)
  -> PrefixParser<C, Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return PrefixParser(subject: subject, onFailure: { _ in nil })
}

/// Creates a parser that parses a specific prefix.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - sequence: The sequence to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func prefix<Stream, C>(
  in streamType: Stream.Type = Stream.self,
  equalsTo subject: C,
  onFailure: @escaping (Stream) -> Any?)
  -> PrefixParser<C, Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return PrefixParser(subject: subject, onFailure: onFailure)
}

// MARK: String specific extensions

/// Creates a parser that parses one specific character at the beginning of a substring.
///
/// - Parameters:
///   - predicate: The predicate to satisfy.
/// - Returns: An element parser.
public func character(satisfying predicate: @escaping (Character) -> Bool)
  -> ElementParser<Substring>
{
  return ElementParser(predicate: predicate, onFailure: { _ in nil })
}

/// Creates a parser that parses one specific character at the beginning of a substring.
///
/// - Parameters:
///   - predicate: The predicate to satisfy.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func character(
  satisfying predicate: @escaping (Character) -> Bool,
  onFailure: @escaping (Substring) -> Any?)
  -> ElementParser<Substring>
{
  return ElementParser(predicate: predicate, onFailure: onFailure)
}

/// Creates a parser that parses one specific character at the beginning of a substring.
///
/// - Parameter chr: The character to parse.
/// - Returns: An element parser.
public func character(_ chr: Character) -> ElementParser<Substring> {
  return element(in: Substring.self, equalsTo: chr)
}

/// Creates a parser that parses one specific character at the beginning of a substring.
///
/// - Parameters:
///   - character: The character to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func character(_ chr: Character, onFailure: @escaping (Substring) -> Any?)
  -> ElementParser<Substring>
{
  return element(in: Substring.self, equalsTo: chr, onFailure: onFailure)
}

/// Creates a parser that parses a specific substring at the beginning of a substring.
///
/// - Parameter str: The substring to parse.
/// - Returns: An element parser.
public func substring(_ str: String) -> PrefixParser<String, Substring> {
  return prefix(in: Substring.self, equalsTo: str)
}

/// Creates a parser that parses a specific substring at the beginning of a substring.
///
/// - Parameters:
///   - substring: The substring to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func substring(_ str: String, onFailure: @escaping (Substring) -> Any?)
  -> PrefixParser<String, Substring>
{
  return prefix(in: Substring.self, equalsTo: str, onFailure: onFailure)
}

/// A parser that parses regular expressions at the beginning of a substring.
public struct RegularExpressionParser: Parser {

  public typealias Element = Substring

  private let pattern: String
  private let onFailure: (Substring) -> Any?

  public init(_ pattern: String, onFailure: @escaping (Substring) -> Any?) {
    self.pattern = pattern
    self.onFailure = onFailure
  }

  public func parse(_ stream: Substring) -> ParseResult<Substring, Substring> {
    guard let range = stream.range(of: pattern, options: .regularExpression)
      else { return .error(diagnostic: onFailure(stream)) }
    guard range.lowerBound == stream.startIndex
      else { return .error(diagnostic: onFailure(stream)) }

    let count = stream.distance(from: range.lowerBound, to: range.upperBound)
    return .success(stream[range], stream.dropFirst(count))
  }

}

/// Creates a parser that parses regular expressions at the beginning of a substring.
///
/// - Parameter pattern: The pattern to match, at the beginning of the stream.
/// - Returns: A regular expression parser.
public func substring(matching pattern: String) -> RegularExpressionParser {
  return RegularExpressionParser(pattern) { _ in nil }
}

/// Creates a parser that parses regular expressions at the beginning of a substring.
///
/// - Parameters:
///   - pattern: The pattern to match, at the beginning of the stream.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: A regular expression parser.
public func substring(matching pattern: String, onFailure: @escaping (Substring) -> Any?)
  -> RegularExpressionParser
{
  return RegularExpressionParser(pattern, onFailure: onFailure)
}

extension Parser where Stream == Substring {

  public func parse(_ string: String) -> ParseResult<Element, Substring> {
    return parse(Substring(string))
  }

}
