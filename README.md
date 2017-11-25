#  SwiftRegex4 - basic regex operations in Swift4

A basic regular expression library based on the idea that subscripting into a string with
a string should be a regexp match.

```Swift
//: Regexies represented as a String subscript on a String

var input = "Now is the time for all good men to come to the aid of the party"

// basic regex match
input["\\w+"]

// regex replace by assignment
input["men"] = "folk"
print(input)

// indiviual groups can be accessed
input["(all) (\\w+)", 2]

// and assigned to
input["the (\\w+)", 1] = "_$1_"
print(input)

// extractng words using Sequence
let words = input.matching(pattern: "\\w+").map { $0[0]! }
print(words)

// access groups of first match
print(input.matching(pattern: "(\\w)(\\w+)?").first { _ in true }!)

// capitalising words using closure
print(input.replacing(pattern: "(_?)(\\w)(\\w*)") {
    (groups, stop) in
    return groups[1]!+groups[2]!.uppercased()+groups[3]!
})

// parsing a properties file
let props = """
    name1 = value1
    name2 = value2
    """

var params = [String: String]()
for groups in props.matching(pattern: "(\\w+)\\s*=\\s*(.*)") {
    params[String(groups[1]!)] = String(groups[2]!)
}
print(params)
```
