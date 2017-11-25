//
//  SwiftRegex4.swift
//  SwiftRegex4
//
//  Created by John Holdsworth on 24/11/2017.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRegex4/SwiftRegex4.playground/Sources/SwiftRegex4.swift#8 $
//
//  Regexies represented as a String subscript on a String
//

import Foundation

public protocol NSRegex {
    func asRegex(options: NSRegularExpression.Options?) -> NSRegularExpression
}

extension NSRegularExpression: NSRegex {
    public func asRegex(options: NSRegularExpression.Options? = nil) -> NSRegularExpression {
        return self
    }
}

extension String: NSRegex {

    private static var regexCache = [String: [UInt: NSRegularExpression]]()

    public func asRegex(options: NSRegularExpression.Options? = nil) -> NSRegularExpression {
        do {
            let options = options ?? []
            if let regex = String.regexCache[self]?[options.rawValue] {
                return regex
            }
            let regex = try NSRegularExpression(pattern: self, options: options)
            if String.regexCache[self] == nil {
                String.regexCache[self] = [UInt: NSRegularExpression]()
            }
            String.regexCache[self]![options.rawValue] = regex
            return regex
        } catch {
            fatalError("Could not parse regex: \(self) = \(error)")
        }
    }

    private func nsRange(_ pos: Int = 0) -> NSRange {
        return NSMakeRange(pos, self.utf16.count-pos)
    }

    private func firstMatch(pattern: NSRegex, options: NSRegularExpression.Options? = nil) -> NSTextCheckingResult? {
        return pattern.asRegex(options: options).firstMatch(in: self, options: [], range: nsRange())
    }

    private subscript(range: NSRange) -> Substring? {
        return Range(range, in: self).flatMap { self[$0] }
    }

    public subscript(pattern: NSRegex) -> Bool {
        return firstMatch(pattern: pattern) != nil
    }

    public subscript(pattern: NSRegex) -> Substring? {
        get {
            return self[pattern, [], 0]
        }
        set(newValue) {
            self[pattern, [], 0] = newValue
        }
    }

    public subscript(pattern: NSRegex) -> [Substring?]? {
        return firstMatch(pattern: pattern).flatMap { groups(from: $0) }
    }

    public subscript(pattern: NSRegex) -> [[Substring?]]? {
        let matches = matching(pattern: pattern).map { $0 }
        return matches.count != 0 ? matches : nil
    }

    public subscript(pattern: NSRegex) -> [Substring]? {
        get {
            let matches = pattern.asRegex(options: nil)
                .matches(in: self, options: [], range: nsRange())
            return matches.count != 0 ? matches.map { self[$0.range]! } : nil
        }
        set(newValue) {
            let newValue = (newValue ?? []).map { String($0) }
            replaceSubrange(startIndex ..< endIndex, with: replacing(pattern: pattern,
                                                                     with: newValue))
        }
    }

    public subscript(pattern: NSRegex) -> AnyIterator<[Substring?]> {
        return matching(pattern: pattern)
    }

    public subscript(pattern: NSRegex) -> ([Substring?], UnsafeMutablePointer<ObjCBool>) -> String {
        get {
            fatalError("get of closure")
        }
        set(newValue) {
            replaceSubrange(startIndex ..< endIndex, with: replacing(pattern: pattern,
                                                                     with: newValue))
        }
    }

    public subscript(pattern: NSRegex, group: Int) -> Substring? {
        get {
            return self[pattern, [], group]
        }
        set(newValue) {
            self[pattern, [], group] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> Substring? {
        get {
            return self[pattern, options, 0]
        }
        set(newValue) {
            self[pattern, options, 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int) -> Substring? {
        get {
            return firstMatch(pattern: pattern, options: options).flatMap { self[$0.range(at: group)] }
        }
        set(newValue) {
            replaceSubrange(startIndex ..< endIndex, with: replacing(pattern: pattern, group: group,
                                                                     with: String(newValue ?? "nil")))
        }
    }

    private func groups(from match: NSTextCheckingResult) -> [Substring?] {
        return (0 ..< match.numberOfRanges).map { self[match.range(at: $0)] }
    }

    public func matching(pattern: NSRegex, options: NSRegularExpression.Options? = nil) -> AnyIterator<[Substring?]> {
        struct RegexIterator: IteratorProtocol {
            public typealias Element = [Substring?]

            let regex: NSRegularExpression
            let string: String
            var pos = 0

            init(regex: NSRegularExpression, string: String) {
                self.regex = regex
                self.string = string
            }

            public mutating func next() -> Element? {
                if let match = regex.firstMatch(in: string, options: [], range: string.nsRange(pos)) {
                    pos = NSMaxRange(match.range)
                    return string.groups(from: match)
                }
                return nil
            }
        }

        var iterator = RegexIterator(regex: pattern.asRegex(options: options), string: self)
        return AnyIterator {
            iterator.next()
        }
    }

    public func replacing(pattern: NSRegex, options: NSRegularExpression.Options? = nil, group: Int = 0,
                          with template: String) -> String {
        return _replacing(pattern: pattern, options: options, group: group, with: {
            (regex, match, stop) -> String in
            return regex.replacementString(for: match, in: self, offset: 0, template: template)
        })
    }

    public func replacing(pattern: NSRegex, options: NSRegularExpression.Options? = nil, group: Int = 0,
                          with templates: [String]) -> String {
        var templateNumber = 0
        return _replacing(pattern: pattern, options: options, group: group, with: {
            (regex, match, stop) -> String in
            templateNumber += 1
            stop.pointee = templateNumber < templates.count ? false : true
            return regex.replacementString(for: match, in: self, offset: 0, template: templates[templateNumber-1])
        })
    }

    public func replacing(pattern: NSRegex, options: NSRegularExpression.Options? = nil,
                          with closure: ([Substring?], UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return _replacing(pattern: pattern, options: options, group: 0, with: {
            (regex, match, stop) -> String in
            return closure(groups(from: match), stop)
        })
    }

    public func _replacing(pattern: NSRegex, options: NSRegularExpression.Options? = nil, group: Int,
                           with closure: (NSRegularExpression, NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        let regex = pattern.asRegex(options: options)
        var out = [Substring]()
        var pos = 0

        regex.enumerateMatches(in: self, options: [], range: nsRange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let range = match.range(at: group)
            out.append(self[NSMakeRange(pos, range.location-pos)] ?? "Invalid range")
            out.append(Substring(closure(regex, match, stop)))
            pos = NSMaxRange(range)
        }

        out.append(self[nsRange(pos)] ?? "Invalid range")
        return out.joined()
    }
}
