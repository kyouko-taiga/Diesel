# Diesel

Diesel is a Swift library to write recursive descent parsers for domain specific languages (DSLs),
using parser combinators.
Like [Parsec](https://hackage.haskell.org/package/parsec) and other similar parser combinator libraries,
Diesel lets you build sophisticated parsers by combining simpler ones.

## TL;DR;

The following example defines a parser for IPv4 addresses.

```swift
// A digit is a character representing a number.
let digit = character(satisfying: { $0.isNumber })

// An octet is a sequence of 1, 2 or 3 digits, converted to an integer.
let octet = digit.then(digit.optional.repeated(count: 2))
  .map { head, tail in Int(String([head] + tail.compactMap { $0 }))! }

// An IPv4 address is a sequence of 4 octets, separated by dots.
let ipv4  = octet.then((character(".").then(octet) { _, r in r }).repeated(count: 3))
  .map { head, tail in [head] + tail }

print(ipv4.parse("192.168.1.1"))
// Prints `success([192, 168, 1, 1], "")`
```

More elaborate examples can be found in the `Examples/` folder.

## Motivation

A parser can be understood as a function of the form `(Stream) -> (Element, Stream)`
that attempts to extract a valid output out a a given stream.
If it succeeds, it returns said output,
together with an "updated" stream, corresponding to the remainder of the input.

For example, consider the task of reading a single digit out of a character string.
Such a parser could be implemented as a function `(String) -> (Character, String)`,
that either successfully reads a digit from the beginning of the string, or returns `nil`.
In more concrete terms, it could be wrote as follows:

```swift
func parseDigit(from string: String) -> (Character, String)? {
  guard let character = string.first, character.isNumber
    else { return nil }
  return (character, String(string.dropFirst()))
}

print(parseDigit(from: "123")!)
//  Prints `("1", "23")`
```

One advantage of this approach is that is that parsers
(i.e. parsing higher-order functions)
can be *combined* to create other parsers.
For example, one could create a parser for two-digit numbers by reusing the above function twice,
feeding the result of its first application to a second one:

```swift
func parseTwoDigits(from string: String) -> ((Character, Character), String)? {
  return parseDigit(from: string).flatMap { (first, remainder) in
    parseDigit(from: remainder).map { (second, remainder) in ((first, second), remainder) }
  }
}

print(parseTwoDigits(from: "123")!)
// Prints `(("1", "2"), "3")`
```

Notice that combining two applications of `parseDigit` is slightly more complex than a simple function composition,
as one must cater for cases where the first application does not succeeds.
Fortunately, the boilerplate involved in such combination can be written implemented as one single *combinator*. A combinator is a higher-order function that accepts one or several parsers to produce a new one.
For instance, we can write a combinator to chain two parsers as follows:

```swift
func chain<T, U>(
  _ first: @escaping (String) -> (T, String)?,
  _ second: @escaping (String) -> (U, String)?)
  -> (String) -> ((T, U), String)?
{
  return { string in
    first(string).flatMap { arg0 in
      second(arg0.1).map { arg1 in ((arg0.0, arg1.0), arg1.1) }
    }
  }
}

print(chain(parseDigit, parseDigit)("123")!)
// Prints `(("1", "2"), "3")`
```

Diesel embraces this principle, and proposes a collection of combinators
to build more sophisticated from simpler ones.
In diesel, a parser is an object that conforms to a protocol `Parser`,
which requires a method `parse(:)` representing parser.
All combinators are proposed in the form of properties and methods of a `Parser` object.
Note that instead of returning optional values,
Diesel parsers are expected to return a case of the enum type `ParseResult`.
This allows to attach optional diagnostics to parse failures,
so as to provide debug information for example:

```swift
struct DigitParser: Parser {

  func parse(_ stream: Substring) -> ParseResult<Character, Substring> {
    guard let character = stream.first
      else { return .error(diagnostic: "unexpected empty stream") }
    guard character.isNumber
      else { return .error(diagnostic: "expected digit, got '\(character)'") }
    return .success(character, stream.dropFirst())
  }

}

let parseDigit = DigitParser()
let parseTwoDigits = parseDigit.then(parseDigit)
print(parseTwoDigits.parse("123"))
// Prints `success(("1", "2"), "3")`
```

## Installation

Diesel is distributed in the form of a Swift package for [Swift Package Manager](https://swift.org/package-manager/).
Simply add Diesel as a dependency to your own package and you'll be ready to go.
There are no other dependencies.

The master branch of Diesel always refers to the latest stable version of the library,
so using `.branch("master")` guarantees that you'll always pull the latest version.
See the official documentation of Swift Package Manager for alternative configurations.

## License

Diesel is distributed under the MIT License.
