import Foundation

/// A parser that parses one specific element at the beginning of the stream.
public struct ElementParser<Stream>: Parser
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{

  public typealias Element = Stream.Element

  private let element: Element
  private let onFailure: (Stream) -> Any?

  public init(_ element: Element, onFailure: @escaping (Stream) -> Any?) {
    self.element = element
    self.onFailure = onFailure
  }

  public func parse(_ stream: Stream) -> ParseResult<Element, Stream> {
    guard stream.first == element
      else { return .error(diagnostic: onFailure(stream)) }
    return .success(element, stream.dropFirst())
  }

}

/// Creates a parser that parses one specific element at the beginning of the stream.
///
/// - Parameters:
///   - element: The element to parse.
///   - streamType: The type of the stream that the returned parser should consume.
/// - Returns: An element parser.
public func parser<Stream>(
  of element: Stream.Element,
  in streamType: Stream.Type = Stream.self)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(element, onFailure: { _ in nil })
}

/// Creates a parser that parses one specific element at the beginning of the stream.
///
/// - Parameters:
///   - element: The element to parse.
///   - streamType: The type of the stream that the returned parser should consume.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parser<Stream>(
  of element: Stream.Element,
  in streamType: Stream.Type = Stream.self,
  onFailure: @escaping (Stream) -> Any?)
  -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(element, onFailure: onFailure)
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
///   - sequence: The sequence to parse.
///   - streamType: The type of the stream that the returned parser should consume.
/// - Returns: An element parser.
public func parser<Stream, C>(
  of sequence: C,
  in streamType: Stream.Type = Stream.self)
  -> SequenceParser<C, Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return SequenceParser(sequence, onFailure: { _ in nil })
}

/// Creates a parser that parses a specific sequence at the beginning of the stream.
///
/// - Parameters:
///   - sequence: The sequence to parse.
///   - streamType: The type of the stream that the returned parser should consume.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parser<Stream, C>(
  of sequence: C,
  in streamType: Stream.Type = Stream.self,
  onFailure: @escaping (Stream) -> Any?)
  -> SequenceParser<C, Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return SequenceParser(sequence, onFailure: onFailure)
}

// MARK: String specific extensions

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
