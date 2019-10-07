# Tutorial

This document has for objective to teach you how to use Diesel to write your own parsers,
by the means of a comprehensive tutorial to build an interpreter for a simple programming language.

This tutorial assumes knowledge of Swift,
and at least some some familiarity with general parsing concepts.

## The Language

In this tutorial, we will write an interpreter for a rather simple functional programming language called Fuel,
for *Functional Uncomplicated Elementary Language*.

Here is an example of a Fuel program that our interpreter will be able to execute:

```
let factorial = ((n, f) => n <= 1 ? 1 : n * f(n - 1)) in
  factorial(6, factorial)
```

## The Basics

Let's start with some basics about the inner workings of Diesel.

### The `Parser` Protocol

A parser can be understood as a function of the form `(Stream) -> (Element, Stream)`
that attempts to extract a valid output out a a given stream.
If it succeeds, it returns said output,
together with an "updated" stream, corresponding to the remainder of the input.
One advantage of this approach is that is that parsers
(i.e. parsing higher-order functions)
can be *combined* to create other parsers.

Diesel embraces this principle, and proposes a collection of combinators
to build more sophisticated from simpler ones.
In diesel, a parser is an object that conforms to a protocol `Parser`,
which requires a method `parse(:)` representing parser.
For example, the following is a parser for digits.

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
print(parseDigit.parse("123"))
// Prints `success("1", "23")`
```

The struct `DigitParser` conforms to `Parser` by providing a method `parse(:)`
that accepts a substring and returns a `ParseResult`.
`ParseResult` is an enum similar to Swift's `Result`, defined as follows:

```swift
public enum ParseResult<Element, Stream> {

  case success(Element, Stream)
  case failure(ParseError)

}
```

In other words, its `success` case represents an element successfully parsed,
together with the remainder of the stream,
whereas its `failure` case represents some parse error.
These can be provided with a diagnostic to give information about a particular failure.
This allows for instance our `DigitParser` to specify why it failed,
as illustrated below:

```swift
print(parseDigit.parse("abc"))
// Prints `failure(Diesel.ParseError(diagnostic: Optional("expected digit, got \'a\'")))`
```

Notice that `DigitParser` accepts substrings, rather than regular strings.
The reason is that strings in Swift (i.e. instances of type `String`) adopt value semantics,
meaning a new copy is created for every mutation.
It does not really make sense in our case to return a brand new object every time a parser succeeds,
as we only need to know what part of the original stream (in this case a string) has yet to be parsed.
Instead, we should rather work on slices of the original input, hence the use of `Substring`.

### Using Combinators

The `DigitParser` defined in the previous section is of little use on its own.
However, Diesel lets us combine it with other parsers (or itself) to build more complex ones.
For example, we could create a parser for two-digits numbers by combining `parseDigit` with itself:

```swift
let parseTwoDigits = parseDigit.then(parseDigit)
print(parseTwoDigits.parse("123"))
// Prints `success(("1", "2"), "3")`
```

Notice that the result of `parseTwoDigits` is now a tuple of two characters,
which corresponds to the two digits it could parse.
Consequently, the remainder of the stream also differs, as our parser has now consumed two characters,
whereas `parseDigit` used to consume only one.

Haskell enthusiasts will be quick to point out that our parser looks awfully similar to a monad,
and rightfully so.
This means that we may of course apply the `map` functor on `parseTwoDigits`
to transform the kind of elements it can produce:

```swift
let parseTwoDigitNat = parseTwoDigits.map { (first, second) in Int(String([first, second]))! }
print(parseTwoDigitNat.parse("123"))
// Prints `success(12, "3")`
```

Notice that the result of `parseTwoDigitNat` is no longer a tuple of characters,
but a good old `Int`,
obtained by converting the string formed by the two parsed digits.

## Parsing Numbers

We will start our journey with a parser for number literals.
Fuel only has one type for numbers, namely `Number`, that represents any rational number.
That means that `1`, `-8` and `1.023` have the same type.

### Parsing Naturals

Let's take an incremental approach, and start with a parser for natural numbers,
which are mere sequences of digits:

```swift
let digit = character(satisfying: { $0.isNumber })
let nat = digit.oneOrMany
print(nat.parse("123"))
// Prints `success(["1", "2", "3"], "")`
```

What does this code do?
1. First, we define a parse for digits.
2. We combine `digit` with the one-or-many combinator, resulting in a parser for non-empty sequences of digits.

Notice that we could have reused the `DigitParser` defined in the previous chapter,
but using Diesel's pre-defined helpers let us avoid a lot of boilerplate.
The `character(satisfying:)` helper lets us define a parser for any character that satisfies a given predicate.
In this particular example, the predicate states that the character should be a number.

Observe that the `nat` parser produces arrays of characters.
The reason is that the one-or-many combinator produces array of the element parsed by the parser on which it is applied.
In our case, `digit` produces characters (i.e. instances of Swift's `Character` type),
and therefore `nat` produces arrays of characters (i.e. `[Character]`).

### Parsing Integers

Like natural numbers, integers are denoted by sequences of digits,
but they may also be prefixed by `-` to denote a negative number.
Hence we can simply combine the `nat` parser with a parser for the minus sign:

```swift
let int = character("-").then(nat)
print(int.parse("-123"))
// Prints `success(("-", ["1", "2", "3"]), "")`
```

The `character(:)` helper lets us define a parser for a specific character.
This code combines such as parser with the `nat` parser defined in the previous section,
resulting in a parser for natural numbers prefixed by a minus sign.

The reader will have noticed that we now have a problem unfortunately,
as our `int` parser can *only* parse negative number.
Fortunately, we can use the optional combinator to solve this problem.
The optional combinator produces a parser that either successfully parses an element,
or simply skips and returns `nil`, together with the input stream, unchanged.

```swift
let int = character("-").optional.then(nat)
print(int.parse("123"))
// Prints `success((nil, ["1", "2", "3"]), "")``
```

### Parsing Floating Point Numbers

The last step is to parse floating point numbers.
We can't simply combine two instances of our integer parser though,
because it would allow us to parse things like `-4.-2`.
However, we may instead combine it with our natural parser!

```swift
let float = int.then((character(".").then(nat)).optional)
print(float.parse("-4.2"))
// Prints `success(((Optional("-"), ["4"]), Optional((".", ["2"]))), "")`
```

Et voilà!

But wait, doesn't the output of `float` look a little weird?
The reason it does is that we did not take care of the output of our parser,
and have instead let Diesel infer it.
Unfortunately, Diesel is does not come together with DeepMind yet,
and so it can't understand we are in fact parsing floating point number literals.
Hence, it is upon us to alter the parsers' output to make it more usable.
We can use the transform combinator (a.k.a. `map`) for that.
Let's redefine some of our parsers:

```swift
// Transform the output to return strings rather than character arrays.
let nat = digit.oneOrMany
  .map { String($0) }

// Transform the output to prepend the minus sign if it was parsed.
let int = character("-").optional.then(nat)
  .map { sign, val in sign.map { String($0) + val } ?? val }

// Transform the output to form a single string,
let float = int.then((character(".").then(nat).map { _, rhs in rhs }).optional)
  .map { arg in arg.1.map { "\(arg.0).\($0)" } ?? arg.0 }

print(float.parse("-4.2"))
// Prints `success("-4.2", "")`
```

Some may have noticed from the documentation that there is a second argument to `then`,
accepting a function to "combine" the outputs of the combined parsers.
Using this parameter is equivalent to transforming a combined parser.
For instance, the following is an equivalent definition of `int`:

```swift
// Combine the output of the combined parser to prepend the minus sign if it was parser.
let int = character("-").optional.then(nat, combine: { sign, val in
  sign.map { String($0) + val } ?? val
})
```

### Parsing with Regular Expression

[Regular expressions](https://en.wikipedia.org/wiki/Regular_expression)
enthusiasts may think this whole definition is cumbersome.
While regular expressions should not be abused, as they often tend to become unreadable,
they have their use cases.
Hence, Diesel comes with helpers to write parsers backed by regular expressions.
For instance, the following illustrates a alternative definition of the `float` parser,
using a regular expression:

```swift
let float = substring(matching: "-?(?:[0-9]+)(?:\\.[0-9]+)?")
print(float.parse("-4.2"))
// Prints `success("-4.2", "")`
```
