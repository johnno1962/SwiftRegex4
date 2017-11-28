//
//  SwiftRegex4.swift
//  SwiftRegex4
//
//  Created by John Holdsworth on 24/11/2017.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRegex4/SwiftRegex4.playground/Sources/SwiftRegex4.swift#33 $
//
//  Regexies represented as a String subscript on a String
//

import Foundation

public typealias RegexClosure = ([Substring?], UnsafeMutablePointer<ObjCBool>) -> String

public protocol NSRegex {
    func asRegex(options: NSRegularExpression.Options?) -> NSRegularExpression
}

extension NSRegularExpression: NSRegex {
    public func asRegex(options _: NSRegularExpression.Options?) -> NSRegularExpression {
        return self
    }
}

#if !swift(>=4.0)
extension NSTextCheckingResult {
    fileprivate func range(at group: Int) -> NSRange {
        return rangeAt(group)
    }
}
#endif

extension String: NSRegex {

    private static var regexCache = [UInt: [String: NSRegularExpression]]()

    public func asRegex(options: NSRegularExpression.Options?) -> NSRegularExpression {
        do {
            let options = options ?? []
            if let regex = String.regexCache[options.rawValue]?[self] {
                return regex
            }
            let regex = try NSRegularExpression(pattern: self, options: options)
            if String.regexCache[options.rawValue] == nil {
                String.regexCache[options.rawValue] = [String: NSRegularExpression]()
            }
            String.regexCache[options.rawValue]![self] = regex
            return regex
        } catch {
            fatalError("Could not parse regex: \(self) = \(error)")
        }
    }

    private func nsRange(_ pos: Int = 0) -> NSRange {
        return NSMakeRange(pos, utf16.count - pos)
    }

    private subscript(range: NSRange) -> Substring? {
        return Range(range, in: self).flatMap { self[$0] }
    }

    private func groups(from match: NSTextCheckingResult) -> [Substring?] {
        return (0 ..< match.numberOfRanges).map { self[match.range(at: $0)] }
    }

    private func _firstMatch(pattern: NSRegex, options: NSRegularExpression.Options?) -> NSTextCheckingResult? {
        return pattern.asRegex(options: options).firstMatch(in: self, options: [], range: nsRange())
    }

    /// test for match
    public func doesMatch(pattern: NSRegex, options: NSRegularExpression.Options? = nil) -> Bool {
        return _firstMatch(pattern: pattern, options: options) != nil
    }

    public subscript(pattern: NSRegex) -> Bool {
        return doesMatch(pattern: pattern)
    }

    /// obtain first match
    public func firstMatch(pattern: NSRegex, options: NSRegularExpression.Options? = nil, group: Int = 0) -> Substring? {
        return _firstMatch(pattern: pattern, options: options).flatMap { self[$0.range(at: group)] }
    }

    public subscript(pattern: NSRegex) -> Substring? {
        get {
            return firstMatch(pattern: pattern)
        }
        set(newValue) {
            self[pattern, [], 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> Substring? {
        get {
            return firstMatch(pattern: pattern, options: options)
        }
        set(newValue) {
            self[pattern, options, 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int) -> Substring? {
        get {
            return firstMatch(pattern: pattern, options: options, group: group)
        }
        set(newValue) {
            replaceSubrange(startIndex ..< endIndex,
                            with: replacing(pattern: pattern, options: options,
                                            group: group, with: String(newValue ?? "nil")))
        }
    }

    /// particular group of first match (always Substring)
    public subscript(pattern: NSRegex, group: Int) -> Substring? {
        get {
            return firstMatch(pattern: pattern, group: group)
        }
        set(newValue) {
            self[pattern, [], group] = newValue
        }
    }

    /// obtain groups of first match
    public func firstGroups(pattern: NSRegex, options: NSRegularExpression.Options? = nil) -> [Substring?]? {
        return _firstMatch(pattern: pattern, options: options).flatMap { groups(from: $0) }
    }

    public subscript(pattern: NSRegex) -> [Substring?]? {
        return firstGroups(pattern: pattern)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> [Substring?]? {
        return firstGroups(pattern: pattern, options: options)
    }

    /// obtain groups of all matches
    public func allGroups(pattern: NSRegex, options: NSRegularExpression.Options? = nil) -> [[Substring?]] {
        return matching(pattern: pattern, options: options).map { $0 }
    }

    public subscript(pattern: NSRegex) -> [[Substring?]]? {
        let matches = allGroups(pattern: pattern)
        return matches.count != 0 ? matches : nil
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> [[Substring?]]? {
        let matches = allGroups(pattern: pattern, options: options)
        return matches.count != 0 ? matches : nil
    }

    /// iterators of groups across matches
    public subscript(pattern: NSRegex) -> AnyIterator<[Substring?]> {
        return matching(pattern: pattern)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> AnyIterator<[Substring?]> {
        return matching(pattern: pattern, options: options)
    }

    /// all matches in String as non-null Substring array & partial replace of first n matches
    public func allMatches(pattern: NSRegex, options: NSRegularExpression.Options? = nil, group: Int = 0) -> [Substring] {
        let regex = pattern.asRegex(options: options)
        return group > regex.numberOfCaptureGroups ? ["Invalid group number"] :
            regex.matches(in: self, options: [], range: nsRange())
                .map { self[$0.range(at: group)] ?? "nil" }
    }

    public subscript(pattern: NSRegex) -> [Substring]? {
        get {
            let matches = allMatches(pattern: pattern)
            return matches.count != 0 ? matches : nil
        }
        set(newValue) {
            self[pattern, [], 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> [Substring]? {
        get {
            let matches = allMatches(pattern: pattern, options: options)
            return matches.count != 0 ? matches : nil
        }
        set(newValue) {
            self[pattern, options, 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int) -> [Substring]? {
        get {
            let matches = allMatches(pattern: pattern, options: options, group: group)
            return matches.count != 0 ? matches : nil
        }
        set(newValue) {
            let newValue = (newValue ?? ["nil replacement list"]).map { String($0) }
            replaceSubrange(startIndex ..< endIndex,
                            with: replacing(pattern: pattern, options: options,
                                            group: group, with: newValue))
        }
    }

    /// replacement using result of calling closure for each match
    public subscript(pattern: NSRegex) -> RegexClosure {
        get {
            fatalError("Invalid get of closure")
        }
        set(newValue) {
            self[pattern, [], 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options) -> RegexClosure {
        get {
            fatalError("Invalid get of closure")
        }
        set(newValue) {
            self[pattern, options, 0] = newValue
        }
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int) -> RegexClosure {
        get {
            fatalError("Invalid get of closure")
        }
        set(newValue) {
            replaceSubrange(startIndex ..< endIndex,
                            with: replacing(pattern: pattern, options: options,
                                            group: group, with: newValue))
        }
    }

    // inplace replacements
    public subscript(pattern: NSRegex, template: String) -> String {
        return replacing(pattern: pattern, with: template)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, template: String) -> String {
        return replacing(pattern: pattern, options: options, with: template)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int, template: String) -> String {
        return replacing(pattern: pattern, options: options, group: group, with: template)
    }

    public subscript(pattern: NSRegex, templates: [String]) -> String {
        return replacing(pattern: pattern, with: templates)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, templates: [String]) -> String {
        return replacing(pattern: pattern, options: options, with: templates)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int, templates: [String]) -> String {
        return replacing(pattern: pattern, options: options, group: group, with: templates)
    }

    public subscript(pattern: NSRegex, closure: RegexClosure) -> String {
        return replacing(pattern: pattern, with: closure)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, closure: RegexClosure) -> String {
        return replacing(pattern: pattern, options: options, with: closure)
    }

    public subscript(pattern: NSRegex, options: NSRegularExpression.Options, group: Int, closure: RegexClosure) -> String {
        return replacing(pattern: pattern, options: options, group: group, with: closure)
    }

    // named functions
    public func matching(pattern: NSRegex, options: NSRegularExpression.Options? = nil) -> AnyIterator<[Substring?]> {
        struct GroupsIterator: IteratorProtocol {
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

        var iterator = GroupsIterator(regex: pattern.asRegex(options: options), string: self)
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
            return regex.replacementString(for: match, in: self, offset: 0, template: templates[templateNumber - 1])
        })
    }

    public func replacing(pattern: NSRegex, options: NSRegularExpression.Options? = nil, group: Int = 0,
                          with closure: RegexClosure) -> String {
        return _replacing(pattern: pattern, options: options, group: group, with: {
            (regex, match, stop) -> String in
            return closure(groups(from: match), stop)
        })
    }

    private func _replacing(pattern: NSRegex, options: NSRegularExpression.Options?, group: Int,
                            with closure: (NSRegularExpression, NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        let regex = pattern.asRegex(options: options)
        var out = [Substring]()
        var pos = 0

        regex.enumerateMatches(in: self, options: [], range: nsRange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let range = match.range(at: group)
            if range.location != NSNotFound {
                out.append(self[NSMakeRange(pos, range.location - pos)] ?? "Invalid range")
                out.append(Substring(closure(regex, match, stop)))
                pos = NSMaxRange(range)
            }
        }

        out.append(self[nsRange(pos)] ?? "Invalid range")
        return out.joined()
    }
}
