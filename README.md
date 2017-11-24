#  SwiftRegex4 - basic regex operations in Swift4

A basic regular expression library based on the idea that subscripting into a string with
a string should be a regexp match.

```Swift
//: Regexies represented as a String subscript on a String

var input = "Now is the time for all good men to come to the aid of the party"

// basic regex match
print(input["\\w+"]!)

// regex replace by assignment
input["men"] = "folk"
print(input)

// adding emphasis to words following "the"
input["the (\\w+)", 1] = "_$1_"
print(input)

// extractng words
let words = input.matching(pattern: "\\w+").map { $0[0]! }
print(words)

// capitalising words
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
