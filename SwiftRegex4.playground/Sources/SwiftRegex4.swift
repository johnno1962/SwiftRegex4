//
//  SwiftRegex4.swift
//  SwiftRegex4
//
//  Created by John Holdsworth on 24/11/2017.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  Regexies represented as a String subscript on a String
//

import Foundation

extension String {

    public subscript(range: NSRange) -> Substring? {
        return Range(range, in: self).flatMap { self[$0] }
    }

    private static var regexCache = [String: [UInt: NSRegularExpression]]()

    private func asRegex(options: NSRegularExpression.Options = []) -> NSRegularExpression {
        do {
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

    public subscript(pattern: String) -> Substring? {
        get {
            return self[pattern, 0, []]
        }
        set(newValue) {
            self[pattern, 0, []] = newValue
        }
    }

    public subscript(pattern: String, _ group: Int) -> Substring? {
        get {
            return self[pattern, group, []]
        }
        set(newValue) {
            self[pattern, group, []] = newValue
        }
    }

    public subscript(pattern: String, _ options: NSRegularExpression.Options) -> Substring? {
        get {
            return self[pattern, 0, options]
        }
        set(newValue) {
            self[pattern, 0, options] = newValue
        }
    }

    public subscript(pattern: String, _ group: Int, _ options: NSRegularExpression.Options) -> Substring? {
        get {
            return pattern.asRegex(options: options).firstMatch(in: self, options: [], range: nsRange())
                .flatMap { self[$0.range(at: group)] }
        }
        set(newValue) {
            replaceSubrange(startIndex ..< endIndex, with: _replacing(pattern: pattern, group: group, with: {
                (regex, match, groups, stop) -> String in
                return regex.replacementString(for: match, in: self, offset: 0,
                                               template: String(newValue ?? "nil"))
            }))
        }
    }

    private func groups(from match: NSTextCheckingResult) -> [Substring?] {
        return (0 ..< match.numberOfRanges).map { self[match.range(at: $0)] }
    }

    public func matching(pattern: String, options: NSRegularExpression.Options = []) -> AnyIterator<[Substring?]> {
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

    public func replacing(pattern: String, with closure: ([Substring?], UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return _replacing(pattern: pattern, group: 0, with: {
            (regex, match, groups, stop) -> String in
            return closure(groups, stop)
        })
    }

    public func _replacing(pattern: String, group: Int,
                           with closure: (NSRegularExpression, NSTextCheckingResult, [Substring?], UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        let regex = pattern.asRegex()
        var out = [Substring]()
        var pos = 0

        regex.enumerateMatches(in: self, options: [], range: nsRange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let range = match.range(at: group)
            if range.location != pos {
                out.append(self[NSMakeRange(pos, range.location-pos)]!)
            }
            out.append(Substring(closure(regex, match, groups(from: match), stop)))
            pos = NSMaxRange(range)
        }

        out.append(self[nsRange(pos)]!)
        return out.joined()
    }
}
