import Foundation

// Load the input file.
guard CommandLine.arguments.count >= 2
  else { fatalError("missing input") }
let pathname = CommandLine.arguments[1]
let input = try String(contentsOfFile: pathname)

// Initialize the parser's forward definitions.
JSONParser.initialize()

// Parse the input file.
if let element = JSONParser.parse(input) {
  print(element)
} else {
  fatalError("could not parse '\(pathname)'")
}
