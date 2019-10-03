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
public func parser<Stream>(
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
public func parser<Stream>(
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
public func parser<Stream>(
  in streamType: Stream.Type = Stream.self,
  of element: Stream.Element)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(predicate: { $0 == element }, onFailure: { _ in nil })
}

/// Creates a parser that parses one specific element at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - element: The element to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parser<Stream>(
  in streamType: Stream.Type = Stream.self,
  of element: Stream.Element,
  onFailure: @escaping (Stream) -> Any?)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(predicate: { $0 == element }, onFailure: onFailure)
}

/// A parser that parses a specific sequence at the beginning of the stream.
public struct SequenceParser<C, Stream>: Parser
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{

  public typealias Element = C

  private let sequence: C
  private let onFailure: (Stream) -> Any?

  public init(_ sequence: C, onFailure: @escaping (Stream) -> Any?) {
    self.sequence = sequence
    self.onFailure = onFailure
  }

  public func parse(_ stream: Stream) -> ParseResult<C, Stream> {
    guard stream.starts(with: sequence)
      else { return .error(diagnostic: onFailure(stream)) }
    return .success(sequence, stream.dropFirst(sequence.count))
  }

}

/// Creates a parser that parses a specific sequence at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - sequence: The sequence to parse.
/// - Returns: An element parser.
public func parser<Stream, C>(
  in streamType: Stream.Type = Stream.self,
  of sequence: C)
  -> SequenceParser<C, Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return SequenceParser(sequence, onFailure: { _ in nil })
}

/// Creates a parser that parses a specific sequence at the beginning of the stream.
///
/// - Parameters:
///   - streamType: The type of the stream that the returned parser should consume.
///   - sequence: The sequence to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parser<Stream, C>(
  in streamType: Stream.Type = Stream.self,
  of sequence: C,
  onFailure: @escaping (Stream) -> Any?)
  -> SequenceParser<C, Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return SequenceParser(sequence, onFailure: onFailure)
}

// MARK: String specific extensions

/// Creates a parser that parses one specific character at the beginning of the stream.
///
/// - Parameter character: The character to parse.
/// - Returns: An element parser.
public func parser(of character: Character) -> ElementParser<Substring> {
  return ElementParser(predicate: { $0 == character }, onFailure: { _ in nil })
}

/// Creates a parser that parses one specific character at the beginning of the stream.
///
/// - Parameters:
///   - character: The character to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parser(of character: Character, onFailure: @escaping (Substring) -> Any?)
  -> ElementParser<Substring>
{
  return ElementParser(predicate: { $0 == character }, onFailure: onFailure)
}

/// Creates a parser that parses a specific substring at the beginning of the stream.
///
/// - Parameter substring: The substring to parse.
/// - Returns: An element parser.
public func parser(of substring: String) -> SequenceParser<String, Substring> {
  return SequenceParser(substring, onFailure: { _ in nil })
}

/// Creates a parser that parses a specific substring at the beginning of the stream.
///
/// - Parameters:
///   - substring: The substring to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parser(of substring: String, onFailure: @escaping (Substring) -> Any?)
  -> SequenceParser<String, Substring>
{
  return SequenceParser(substring, onFailure: onFailure)
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
public func parser(matching pattern: String) -> RegularExpressionParser {
  return RegularExpressionParser(pattern) { _ in nil }
}

/// Creates a parser that parses regular expressions at the beginning of a substring.
///
/// - Parameters:
///   - pattern: The pattern to match, at the beginning of the stream.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: A regular expression parser.
public func parser(matching pattern: String, onFailure: @escaping (Substring) -> Any?)
  -> RegularExpressionParser
{
  return RegularExpressionParser(pattern, onFailure: onFailure)
}

extension Parser where Stream == Substring {

  public func parse(_ string: String) -> ParseResult<Element, Substring> {
    return parse(Substring(string))
  }

}
