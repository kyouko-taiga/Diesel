import Diesel

protocol ParseResultRepresentable {

  associatedtype Element
  associatedtype Stream

  func extractSuccess() -> (Element, Stream)?
  func extractFailure() -> ParseError?

}

extension ParseResult: ParseResultRepresentable {

  func extractSuccess() -> (Element, Stream)? {
    guard case .success(let element, let stream) = self
      else { return nil }
    return (element, stream)
  }

  func extractFailure() -> ParseError? {
    guard case .failure(let error) = self
      else { return nil }
    return error
  }

}

extension Assertion where Subject: ParseResultRepresentable {

  static func failed() -> Assertion<Subject> {
    return Assertion { result in
      return result.extractFailure() != nil
    }
  }

  static func failed<Diagnostic>(withDiagnostic diagnostic: Diagnostic) -> Assertion<Subject>
    where Diagnostic: Equatable
  {
    return Assertion { result in
      guard let extractedDiagnostic = result.extractFailure()?.diagnostic as? Diagnostic
        else { return false }
      return extractedDiagnostic == diagnostic
    }
  }

}

extension Assertion
  where Subject: ParseResultRepresentable, Subject.Element: Equatable, Subject.Stream: Equatable
{

  static func succeeded(_ element: Subject.Element, _ stream: Subject.Stream)
    -> Assertion<Subject>
  {
    return Assertion { result in
      guard let success = result.extractSuccess()
        else { return false }
      return success.0 == element && success.1 == stream
    }
  }

}
