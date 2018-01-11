//: Regexies represented as a String subscript on a String

var input = "Now is the time for all good men to come to the aid of the party"

// basic regex match
if input["\\w+"] {
    print("match")
}

// receiving type controls data you get
if let firstMatch: Substring = input["\\w+"] {
    print("match: \(firstMatch)")
}

if let groupsOfFirstMatch: [Substring?] = input["(all) (\\w+)"] {
    print("groups: \(groupsOfFirstMatch)")
}

// "splat" out up to five groups of first match
if let (group1, group2): (Substring?, Substring?) = input["(all) (\\w+)"] {
    print("group1: \(group1!), group2: \(group2!)")
}

if let (group1, group2): (String, String) = input["(all) (\\w+)"] {
    print("group1: \(group1), group2: \(group2)")
}

if let allGroupsOfAllMatches: [[Substring?]] = input["(\\w)(\\w*)"] {
    print("allGroups: \(allGroupsOfAllMatches)")
}

// Matches only can be fetched with non-optional Substring array
if let allMatches: [Substring] = input["\\w+"] {
    print("words: \(allMatches)")
}

// regex replace by assignment
input["men"] = "folk"
print(input)

// replace just the first two matches
input["\\w+"] = ["yesterday", "was"]
print(input)

// individual groups can be accessed
input["(all) (\\w+)", 2]

// and assigned to
input["the (\\w+)", [.caseInsensitive], 1] = "_$1_"
print(input)

// or replaced using a closure
input["(_?)(\\w)(\\w*)"] = {
    (groups, stop) in
    return groups[1]!+groups[2]!.uppercased()+groups[3]!
}
print(input)

// parsing a properties file using regex as iterator
let props = """
    name1 = value1
    name2 = value2
    """

var params = [String: String]()
for groups in props["(\\w+)\\s*=\\s*(.*)"] {
    params[String(groups[1]!)] = String(groups[2]!)
}
print(params)

// use in switches
let match = RegexMatch()
switch input {
case RegexPattern("(\\w)(\\w*)", capture: match):
    let (first, rest) = input[match]
    print("\(first) \(rest)")
default:
    break
}
