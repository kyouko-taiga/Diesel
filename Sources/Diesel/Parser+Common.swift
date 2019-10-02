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
/// - Parameter element: The element to parse.
/// - Returns: An element parser.
public func parse<Stream>(exactly element: Stream.Element) -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(element, onFailure: { _ in nil })
}

/// Creates a parser that parses one specific element at the beginning of the stream.
///
/// - Parameters:
///   - element: The element to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parse<Stream>(
  exactly element: Stream.Element,
  onFailure: @escaping (Stream) -> Any?) -> ElementParser<Stream>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream
{
  return ElementParser(element, onFailure: onFailure)
}

/// A parser that parses a specific sequence at the beginning of the stream.
public struct SequenceParser<Stream, C>: Parser
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{

  public typealias Element = C

  private let sequence: C
  private let onFailure: (Stream) -> Any?

  public init(_ sequence: C, onFailure: @escaping (Stream) -> Any?) {
    self.sequence = sequence
    self.onFailure = { _ in nil }
  }

  public func parse(_ stream: Stream) -> ParseResult<C, Stream> {
    guard stream.starts(with: sequence)
      else { return .error(diagnostic: onFailure(stream)) }
    return .success(sequence, stream.dropLast(sequence.count))
  }

}

/// Creates a parser that parses a specific sequence at the beginning of the stream.
///
/// - Parameter sequence: The sequence to parse.
/// - Returns: An element parser.
public func parse<Stream, C>(exactly sequence: C) -> SequenceParser<Stream, C>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return SequenceParser(sequence, onFailure: { _ in nil })
}

/// Creates a parser that parses a specific sequence at the beginning of the stream.
///
/// - Parameters:
///   - sequence: The sequence to parse.
///   - onFailure: A function that is called when the parser fails to produce a diagnostic.
/// - Returns: An element parser.
public func parse<Stream, C>(
  exactly sequence: C,
  onFailure: @escaping (Stream) -> Any?) -> SequenceParser<Stream, C>
  where Stream: Collection, Stream.Element: Equatable, Stream.SubSequence == Stream,
        C: Collection, C.Element == Stream.Element
{
  return SequenceParser(sequence, onFailure: onFailure)
}
