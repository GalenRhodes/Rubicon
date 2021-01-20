/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: RegularExpression.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/19/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation
import CoreFoundation

open class RegularExpression {

    private let nsRegex: NSRegularExpression

    public init(pattern: String, options: NSRegularExpression.Options = []) throws {
        nsRegex = try NSRegularExpression(pattern: pattern, options: options)
    }

    open func firstMatch(in str: String, options: NSRegularExpression.MatchingOptions = []) -> Match? {
        let nsRange = NSRange(location: 0, length: str.endIndex.utf16Offset(in: str))
        guard let match = nsRegex.firstMatch(in: str, options: options, range: nsRange) else { return nil }
        return Match(str, match: match)
    }

    open func matches(in str: String, options: NSRegularExpression.MatchingOptions = []) -> [Match] {
        let nsRange          = NSRange(location: 0, length: str.endIndex.utf16Offset(in: str))
        let arr              = nsRegex.matches(in: str, options: options, range: nsRange)
        var matches: [Match] = []
        for m in arr { matches.append(Match(str, match: m)) }
        return matches
    }

    open func forEachMatch(in str: String, options: NSRegularExpression.MatchingOptions = [], _ body: @escaping (Match) -> Bool) {
        let nsRange: NSRange = NSRange(location: 0, length: str.endIndex.utf16Offset(in: str))
        nsRegex.enumerateMatches(in: str, options: options, range: nsRange) { r, _, p in if let r = r { if body(Match(str, match: r)) { p.pointee = true } } }
    }

    public final class Match: Sequence, Collection {
        public typealias Element = Group
        public typealias Index = Int

        public let string:     String
        public var startIndex: Index { groups.startIndex }
        public var endIndex:   Index { groups.endIndex }
        public var count:      Int { groups.count }

        @usableFromInline let nsMatch:    NSTextCheckingResult
        @usableFromInline var namedCache: [String:NamedGroup] = [:]

        @usableFromInline lazy var groups: [Group] = getGroups()

        public init(_ str: String, match: NSTextCheckingResult) {
            self.nsMatch = match
            self.string = str
        }

        @inlinable func getGroups() -> [Group] {
            var grps: [Group] = []
            for x in (0 ..< nsMatch.numberOfRanges) { grps.append(Group(self, range: nsMatch.range(at: x))) }
            return grps
        }

        @inlinable public subscript(name: String) -> NamedGroup {
            if let ng = namedCache[name] { return ng }
            let ng = NamedGroup(self, name: name, range: nsMatch.range(withName: name))
            namedCache[name] = ng
            return ng
        }

        public subscript(position: Index) -> Element { groups[position] }

        public func index(after i: Index) -> Index { groups.index(after: i) }

        public func makeIterator() -> Iterator { Iterator(match: self) }

        public final class Iterator: IteratorProtocol {
            public typealias Element = Group

            @usableFromInline var index: Int = 0
            @usableFromInline let match: Match

            public init(match: Match) { self.match = match }

            @inlinable public func next() -> Element? { (index < match.groups.endIndex ? match.groups[index++] : nil) }
        }
    }

    public class Group {
        let match: Match

        public let range: Range<String.Index>?
        public internal(set) lazy var subString: String? = ((range == nil) ? nil : String(match.string[range!]))

        public init(_ match: Match, range: NSRange) {
            self.match = match
            self.range = ((range.location == NSNotFound) ? nil : (String.Index(utf16Offset: range.lowerBound, in: match.string) ..< String.Index(utf16Offset: range.upperBound, in: match.string)))
        }
    }

    public class NamedGroup: Group {
        public let name: String

        public init(_ match: Match, name: String, range: NSRange) {
            self.name = name
            super.init(match, range: range)
        }
    }
}

/*===============================================================================================================================================================================*/
/// Because that's a LONG freaking name to type.
///
public typealias RegEx = NSRegularExpression
/*===============================================================================================================================================================================*/
/// Because that's a LONG freaking name to type.
///
public typealias RegExResult = NSTextCheckingResult

/*===============================================================================================================================================================================*/
/// Convienience function to build an instance of <code>[RegEx](https://developer.apple.com/documentation/foundation/nsregularexpression/)</code> that includes the option to have
/// anchors ('^' and '$') match the beginning and end of lines instead of the entire input.
/// 
/// - Parameter pattern: the regular expression pattern.
/// - Returns: the instance of <code>[RegEx](https://developer.apple.com/documentation/foundation/nsregularexpression/)</code>
/// - Throws: exception if the pattern is an invalid regular expression pattern.
///
public func regexML(pattern: String) throws -> RegEx {
    try RegEx(pattern: pattern, options: [ RegEx.Options.anchorsMatchLines ])
}
