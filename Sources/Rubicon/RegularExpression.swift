/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: RegularExpression.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: July 09, 2022
 *
 * Copyright © 2022 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

open class RegularExpression: Hashable {

    fileprivate let regex: NSRegularExpression

    public private(set) lazy var pattern:               String  = regex.pattern
    public private(set) lazy var options:               Options = regex.options.xlate()
    public private(set) lazy var numberOfCaptureGroups: Int     = regex.numberOfCaptureGroups

    public init(pattern string: String, options: Options = []) throws {
        regex = try NSRegularExpression(pattern: string, options: options.xlate())
    }

    public convenience init?(pattern string: String, options: Options = [], error: inout Error?) {
        do {
            try self.init(pattern: string, options: options)
            error = nil
        }
        catch let e {
            error = e
            return nil
        }
    }

    open func numberOfMatches(in string: String, options: MatchingOptions = [], range: StringRange) -> Int {
        regex.numberOfMatches(in: string, options: options.xlate(), range: string.nsRange(range: range))
    }

    open func numberOfMatches(in string: String, options: MatchingOptions = []) -> Int {
        numberOfMatches(in: string, options: options, range: string.allRange)
    }

    open func rangeOfFirstMatch(in string: String, options: MatchingOptions = [], range: StringRange) -> StringRange {
        string.range(regex.rangeOfFirstMatch(in: string, options: options.xlate(), range: string.nsRange(range: range)))
    }

    open func rangeOfFirstMatch(in string: String, options: MatchingOptions = []) -> StringRange {
        rangeOfFirstMatch(in: string, options: options, range: string.allRange)
    }

    open func firstMatch(in string: String, options: MatchingOptions = [], range: StringRange) -> Match? {
        guard let x = regex.firstMatch(in: string, options: options.xlate(), range: string.nsRange(range: range)) else { return nil }
        return Match(string, x, self)
    }

    open func firstMatch(in string: String, options: MatchingOptions = []) -> Match? {
        firstMatch(in: string, options: options, range: string.allRange)
    }

    open func matches(in string: String, options: MatchingOptions = [], range: StringRange) -> [Match] {
        var out: [Match] = []
        forEachMatch(in: string, options: options, range: range) { m, _, _ in if let match = m { out.append(match) } }
        return out
    }

    open func matches(in string: String, options: MatchingOptions = []) -> [Match] {
        matches(in: string, options: options, range: string.allRange)
    }

    open func forEachMatch(in string: String, options: MatchingOptions = [], range: StringRange, using block: (Match?, MatchingFlags, inout Bool) throws -> Void) rethrows {
        try withoutActuallyEscaping(block) { _block in
            var error: Error? = nil
            regex.enumerateMatches(in: string, options: options.xlate(), range: string.nsRange(range: range)) { r, f, s in
                do {
                    var stop: Bool = false
                    if let result = r { _block(Match(string, result, self), f.xlate(), &stop) }
                    else { _block(nil, f.xlate(), &stop) }
                    s.pointee = ObjCBool(stop)
                }
                catch let e { error = e }
            }
            if let e = error { throw e }
        }
    }

    open func forEachMatch(in string: String, options: MatchingOptions = [], using block: (Match?, MatchingFlags, inout Bool) throws -> Void) rethrows {
        try forEachMatch(in: string, options: options, range: string.allRange, using: block)
    }

    open func stringByReplacingMatches(in string: String, options: MatchingOptions = [], range: StringRange, withTemplate templ: String) -> String {
        regex.stringByReplacingMatches(in: string, options: options.xlate(), range: string.nsRange(range: range), withTemplate: templ)
    }

    open func stringByReplacingMatches(in string: String, options: MatchingOptions = [], withTemplate templ: String) -> String {
        stringByReplacingMatches(in: string, options: options, range: string.allRange, withTemplate: templ)
    }

    open func replaceMatches(in string: inout String, options: MatchingOptions = [], range: StringRange, withTemplate templ: String) -> Int {
        let _string = NSMutableString(string: string)
        let _count  = regex.replaceMatches(in: _string, options: options.xlate(), range: string.nsRange(range: range), withTemplate: templ)
        if _count > 0 { string = String(_string) }
        return _count
    }

    open func replaceMatches(in string: inout String, options: MatchingOptions = [], withTemplate templ: String) -> Int {
        replaceMatches(in: &string, options: options, range: string.allRange, withTemplate: templ)
    }

    public class func escapedTemplate(for string: String) -> String {
        NSRegularExpression.escapedTemplate(for: string)
    }

    public class func escapedPattern(for string: String) -> String {
        NSRegularExpression.escapedPattern(for: string)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(regex)
    }

    public static func == (lhs: RegularExpression, rhs: RegularExpression) -> Bool {
        ((lhs === rhs) || ((type(of: lhs) != type(of: rhs)) && (lhs.regex == rhs.regex)))
    }

    public class Match: RandomAccessCollection, Hashable {
        public typealias Element = Group?
        public typealias Index = Int

        public let regularExpression: RegularExpression
        public let string:            String
        public let startIndex:        Int = 0

        public private(set) lazy var count:     Int         = txtChkRes.numberOfRanges
        public private(set) lazy var endIndex:  Int         = count
        public private(set) lazy var range:     StringRange = string.range(txtChkRes.range)
        public private(set) lazy var substring: String      = string.substring(range)

        fileprivate let txtChkRes: NSTextCheckingResult

        fileprivate init(_ string: String, _ textCheckingResult: NSTextCheckingResult, _ regularExpression: RegularExpression) {
            self.regularExpression = regularExpression
            self.txtChkRes = textCheckingResult
            self.string = string
        }

        public subscript(position: Int) -> Group? { groups[position] }

        public func forEach(do block: (Group, inout Bool) throws -> Void) rethrows {
            var stop: Bool = false
            for i in (startIndex ..< endIndex) {
                if let g = self[i] {
                    try block(g, &stop)
                    if stop { break }
                }
            }
        }

        fileprivate lazy var groups: [Group?] = {
            var o: [Group?] = []
            for position in (startIndex ..< endIndex) { o.append((txtChkRes.range(at: position).location == NSNotFound) ? nil : Group(self, position)) }
            return o
        }()

        public func hash(into hasher: inout Hasher) {
            hasher.combine(regularExpression)
            hasher.combine(string)
            hasher.combine(txtChkRes)
        }

        public static func == (l: Match, r: Match) -> Bool {
            ((l === r) || ((type(of: l) == type(of: r)) && (l.regularExpression == r.regularExpression) && (l.string == r.string) && (l.txtChkRes == r.txtChkRes)))
        }
    }

    public class Group: Hashable {
        public let match:    Match
        public let position: Int

        public private(set) lazy var range:     StringRange = match.string.range(match.txtChkRes.range(at: position))
        public private(set) lazy var substring: String      = match.string.substring(range)

        fileprivate init(_ match: Match, _ position: Int) {
            self.match = match
            self.position = position
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(match)
            hasher.combine(position)
        }

        public static func == (l: Group, r: Group) -> Bool {
            ((l === r) || ((type(of: l) == type(of: r)) && (l.match == r.match) && (l.position == r.position)))
        }
    }

    public struct Options: OptionSet, @unchecked Sendable {
        public static let caseInsensitive:            Options = Options(rawValue: NSRegularExpression.Options.caseInsensitive.rawValue)
        public static let allowCommentsAndWhitespace: Options = Options(rawValue: NSRegularExpression.Options.allowCommentsAndWhitespace.rawValue)
        public static let ignoreMetacharacters:       Options = Options(rawValue: NSRegularExpression.Options.ignoreMetacharacters.rawValue)
        public static let dotMatchesLineSeparators:   Options = Options(rawValue: NSRegularExpression.Options.dotMatchesLineSeparators.rawValue)
        public static let anchorsMatchLines:          Options = Options(rawValue: NSRegularExpression.Options.anchorsMatchLines.rawValue)
        public static let useUnixLineSeparators:      Options = Options(rawValue: NSRegularExpression.Options.useUnixLineSeparators.rawValue)
        public static let useUnicodeWordBoundaries:   Options = Options(rawValue: NSRegularExpression.Options.useUnicodeWordBoundaries.rawValue)

        public let rawValue: UInt

        public init(rawValue: UInt) { self.rawValue = rawValue }
    }

    public struct MatchingOptions: OptionSet, @unchecked Sendable {
        public static let reportProgress:         MatchingOptions = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.reportProgress.rawValue)
        public static let reportCompletion:       MatchingOptions = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.reportCompletion.rawValue)
        public static let anchored:               MatchingOptions = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.anchored.rawValue)
        public static let withTransparentBounds:  MatchingOptions = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.withTransparentBounds.rawValue)
        public static let withoutAnchoringBounds: MatchingOptions = MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.withoutAnchoringBounds.rawValue)

        public let rawValue: UInt

        public init(rawValue: UInt) { self.rawValue = rawValue }
    }

    public struct MatchingFlags: OptionSet, @unchecked Sendable {
        public static let progress:      MatchingFlags = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.progress.rawValue)
        public static let completed:     MatchingFlags = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.completed.rawValue)
        public static let hitEnd:        MatchingFlags = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.hitEnd.rawValue)
        public static let requiredEnd:   MatchingFlags = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.requiredEnd.rawValue)
        public static let internalError: MatchingFlags = MatchingFlags(rawValue: NSRegularExpression.MatchingFlags.internalError.rawValue)

        public let rawValue: UInt

        public init(rawValue: UInt) { self.rawValue = rawValue }
    }
}

extension RegularExpression.Options {
    func xlate() -> NSRegularExpression.Options {
        var o: NSRegularExpression.Options = []
        if self.contains(.caseInsensitive) { o.insert(.caseInsensitive) }
        if self.contains(.allowCommentsAndWhitespace) { o.insert(.allowCommentsAndWhitespace) }
        if self.contains(.ignoreMetacharacters) { o.insert(.ignoreMetacharacters) }
        if self.contains(.dotMatchesLineSeparators) { o.insert(.dotMatchesLineSeparators) }
        if self.contains(.anchorsMatchLines) { o.insert(.anchorsMatchLines) }
        if self.contains(.useUnixLineSeparators) { o.insert(.useUnixLineSeparators) }
        if self.contains(.useUnicodeWordBoundaries) { o.insert(.useUnicodeWordBoundaries) }
        return o
    }
}

extension NSRegularExpression.Options {
    fileprivate func xlate() -> RegularExpression.Options {
        var o: RegularExpression.Options = []
        if self.contains(.caseInsensitive) { o.insert(.caseInsensitive) }
        if self.contains(.allowCommentsAndWhitespace) { o.insert(.allowCommentsAndWhitespace) }
        if self.contains(.ignoreMetacharacters) { o.insert(.ignoreMetacharacters) }
        if self.contains(.dotMatchesLineSeparators) { o.insert(.dotMatchesLineSeparators) }
        if self.contains(.anchorsMatchLines) { o.insert(.anchorsMatchLines) }
        if self.contains(.useUnixLineSeparators) { o.insert(.useUnixLineSeparators) }
        if self.contains(.useUnicodeWordBoundaries) { o.insert(.useUnicodeWordBoundaries) }
        return o
    }
}

extension RegularExpression.MatchingOptions {
    fileprivate func xlate() -> NSRegularExpression.MatchingOptions {
        var o: NSRegularExpression.MatchingOptions = []
        if self.contains(.reportProgress) { o.insert(.reportProgress) }
        if self.contains(.reportCompletion) { o.insert(.reportCompletion) }
        if self.contains(.anchored) { o.insert(.anchored) }
        if self.contains(.withTransparentBounds) { o.insert(.withTransparentBounds) }
        if self.contains(.withoutAnchoringBounds) { o.insert(.withoutAnchoringBounds) }
        return o
    }
}

extension RegularExpression.MatchingFlags {
    fileprivate func xlate() -> NSRegularExpression.MatchingFlags {
        var o: NSRegularExpression.MatchingFlags = []
        if self.contains(.progress) { o.insert(.progress) }
        if self.contains(.completed) { o.insert(.completed) }
        if self.contains(.hitEnd) { o.insert(.hitEnd) }
        if self.contains(.requiredEnd) { o.insert(.requiredEnd) }
        if self.contains(.internalError) { o.insert(.internalError) }
        return o
    }
}

extension NSRegularExpression.MatchingFlags {
    fileprivate func xlate() -> RegularExpression.MatchingFlags {
        var o: RegularExpression.MatchingFlags = []
        if self.contains(.progress) { o.insert(.progress) }
        if self.contains(.completed) { o.insert(.completed) }
        if self.contains(.hitEnd) { o.insert(.hitEnd) }
        if self.contains(.requiredEnd) { o.insert(.requiredEnd) }
        if self.contains(.internalError) { o.insert(.internalError) }
        return o
    }
}
