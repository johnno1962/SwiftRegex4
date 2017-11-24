//
//  SwiftRegex4Tests.swift
//  SwiftRegex4Tests
//
//  Created by John Holdsworth on 24/11/2017.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//

import XCTest
@testable import SwiftRegex4

class SwiftRegex4Tests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let input = "The quick brown fox jumps over the lazy dog."

        XCTAssertEqual(input["quick .* fox"], "quick brown fox", "basic match")

        if let _ = input["quick orange fox"] {
            XCTAssert(false, "non-match fail")
        }
        else {
            XCTAssert(true, "non-match pass")
        }

        XCTAssertEqual(input["quick brown (\\w+)", 1], "fox", "group subscript")

        XCTAssertEqual(input["(the lazy) (cat)?", 2], nil, "optional group pass")

        var minput = input

        minput["(the) (\\w+)"] = "$1 very $2"
        XCTAssertEqual(minput, "The quick brown fox jumps over the very lazy dog.", "replace pass")

        minput = minput.replacing(pattern: "(\\w)(\\w+)") {
            (groups, stop) in
            return groups[1]!.uppercased()+groups[2]!
        }

        XCTAssertEqual(minput, "The Quick Brown Fox Jumps Over The Very Lazy Dog.", "block pass")

        minput["Quick (\\w+)", 1] = "Red $1"

        XCTAssertEqual(minput, "The Quick Red Brown Fox Jumps Over The Very Lazy Dog.", "group replace pass")

        var z = "👨‍👩‍👧‍👦👨‍👩‍👧‍👦 👨‍👩‍👧‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇭🇺 🇭🇺🇭🇺"

        z["👨‍👩‍👧‍👦"] = "👩‍👩‍👦"
        z = z.replacing(pattern: "🇭🇺") {
            (groups, stop) in
            stop.pointee = true
            return "🇫🇷"
        }

        XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇫🇷 🇭🇺🇭🇺", "emoji pass")

        let props = """
            name1=value1
            name2='value2
            value2
            '

            """

        var dict = [String: String]()
        for groups in props.matching(pattern: "(\\w+)=('[^']*'|[^\n]*)") {
            dict[String(groups[1]!)] = String(groups[2]!)
        }
        XCTAssertEqual(dict, ["name1": "value1", "name2": "'value2\nvalue2\n'"], "dictionary pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            testExample()
        }
    }
}
