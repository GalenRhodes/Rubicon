// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: RegularExpression.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: July 09, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation

open class RegularExpression {

    let regex: NSRegularExpression
    /*@f:0*/
    public var pattern:               String                    { regex.pattern               }
    public var options:               RegularExpression.Options { regex.options.xlate()       }
    public var numberOfCaptureGroups: Int                       { regex.numberOfCaptureGroups }
    /*@f:1*/

    public init(pattern string: String, options: RegularExpression.Options = []) throws {
        self.regex = try NSRegularExpression(pattern: string, options: options.xlate())
    }

    public convenience init?(pattern string: String, options: RegularExpression.Options = [], error: inout Error?) {
        do {
            try self.init(pattern: string, options: options)
            error = nil
        }
        catch let e {
            error = e
            return nil
        }
    }

    public func numberOfMatches(in string: String, options: MatchingOptions = [], range: Range<String.Index>? = nil) -> Int {
        regex.numberOfMatches(in: string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange))
    }

    public func enumerateMatches(in string: String, options: MatchingOptions = [], range: Range<String.Index>? = nil, using block: (Match?, MatchingFlags, inout Bool) throws -> Void) rethrows {
        try withoutActuallyEscaping(block) { _block in
            var error: Error? = nil
            regex.enumerateMatches(in: string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange)) {
                do {
                    var stop: Bool = false
                    try _block(Match(string, $0), $1.xlate(), &stop)
                    $2.pointee = ObjCBool(stop)
                }
                catch let e {
                    error = e
                    $2.pointee = ObjCBool(true)
                }
            }
            if let e = error { throw e }
        }
    }

    public func rangeOfFirstMatch(in string: String, options: MatchingOptions = [], range: Range<String.Index>? = nil) -> Range<String.Index>? {
        let r: NSRange = regex.rangeOfFirstMatch(in: string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange))
        guard r.location != NSNotFound else { return nil }
        return Range<String.Index>(r, in: string)
    }

    public func matches(in string: String, options: MatchingOptions = [], range: Range<String.Index>? = nil) -> [Match] {
        regex.matches(in: string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange)).map { Match(string, $0)! }
    }

    public func firstMatch(in string: String, options: MatchingOptions = [], range: Range<String.Index>? = nil) -> Match? {
        Match(string, regex.firstMatch(in: string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange)))
    }

    public func stringByReplacingMatches(in string: String, options: MatchingOptions = [], range: Range<String.Index>? = nil, withTemplate tmpl: String) -> String {
        regex.stringByReplacingMatches(in: string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange), withTemplate: tmpl)
    }

    public func replaceMatches(in string: inout String, options: MatchingOptions = [], range: Range<String.Index>? = nil, withTemplate tmpl: String) -> Int {
        let _string = NSMutableString(string: string)
        let cc      = regex.replaceMatches(in: _string, options: options.xlate(), range: string.nsRange(range: range ?? string.allRange), withTemplate: tmpl)
        string = String(_string)
        return cc
    }

    public class func escapedTemplate(for string: String) -> String {
        NSRegularExpression.escapedTemplate(for: string)
    }

    public class func escapedPattern(for string: String) -> String {
        NSRegularExpression.escapedPattern(for: string)
    }

    public class Match: @unchecked Sendable, RandomAccessCollection {
        /*@f:0*/
        public typealias Element = Group?
        public typealias Index   = Int

        public var range:      Range<String.Index> { groups[0]!.range     }
        public var substring:  String              { groups[0]!.substring }
        public var count:      Int                 { groups.count         }
        public var startIndex: Index               { groups.startIndex    }
        public var endIndex:   Index               { groups.endIndex      }
        /*@f:1*/

        public subscript(position: Index) -> Element { groups[position] }

        private let groups: [Element]

        public init?(_ string: String, _ result: NSTextCheckingResult?) {
            guard let result = result else { return nil }
            var grps: [Element] = []
            for i in (0 ..< result.numberOfRanges) {
                grps.append(Group(i, string, result.range(at: i)))
            }
            self.groups = grps
        }
    }

    public class Group: @unchecked Sendable {
        public let range:     Range<String.Index>
        public let substring: String
        public let index:     Int

        init?(_ index: Int, _ string: String, _ nsRange: NSRange) {
            guard nsRange.location != NSNotFound else { return nil }
            guard let r = Range<String.Index>(nsRange, in: string) else { fatalError() }
            self.index = index
            self.range = r
            self.substring = String(string[r])
        }
    }

    public struct Options: OptionSet, @unchecked Sendable {
        public static let caseInsensitive:            RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.caseInsensitive.rawValue)
        public static let allowCommentsAndWhitespace: RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.allowCommentsAndWhitespace.rawValue)
        public static let ignoreMetacharacters:       RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.ignoreMetacharacters.rawValue)
        public static let dotMatchesLineSeparators:   RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.dotMatchesLineSeparators.rawValue)
        public static let anchorsMatchLines:          RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.anchorsMatchLines.rawValue)
        public static let useUnixLineSeparators:      RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.useUnixLineSeparators.rawValue)
        public static let useUnicodeWordBoundaries:   RegularExpression.Options = RegularExpression.Options(rawValue: NSRegularExpression.Options.useUnicodeWordBoundaries.rawValue)

        public let rawValue: UInt

        public init(rawValue: UInt) { self.rawValue = rawValue }
    }

    public struct MatchingOptions: OptionSet, @unchecked Sendable {
        public static let reportProgress:         RegularExpression.MatchingOptions = RegularExpression.MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.reportProgress.rawValue)
        public static let reportCompletion:       RegularExpression.MatchingOptions = RegularExpression.MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.reportCompletion.rawValue)
        public static let anchored:               RegularExpression.MatchingOptions = RegularExpression.MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.anchored.rawValue)
        public static let withTransparentBounds:  RegularExpression.MatchingOptions = RegularExpression.MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.withTransparentBounds.rawValue)
        public static let withoutAnchoringBounds: RegularExpression.MatchingOptions = RegularExpression.MatchingOptions(rawValue: NSRegularExpression.MatchingOptions.withoutAnchoringBounds.rawValue)

        public let rawValue: UInt

        public init(rawValue: UInt) { self.rawValue = rawValue }
    }

    public struct MatchingFlags: OptionSet, @unchecked Sendable {
        public static let progress:      RegularExpression.MatchingFlags = RegularExpression.MatchingFlags(rawValue: RegularExpression.MatchingFlags.progress.rawValue)
        public static let completed:     RegularExpression.MatchingFlags = RegularExpression.MatchingFlags(rawValue: RegularExpression.MatchingFlags.completed.rawValue)
        public static let hitEnd:        RegularExpression.MatchingFlags = RegularExpression.MatchingFlags(rawValue: RegularExpression.MatchingFlags.hitEnd.rawValue)
        public static let requiredEnd:   RegularExpression.MatchingFlags = RegularExpression.MatchingFlags(rawValue: RegularExpression.MatchingFlags.requiredEnd.rawValue)
        public static let internalError: RegularExpression.MatchingFlags = RegularExpression.MatchingFlags(rawValue: RegularExpression.MatchingFlags.internalError.rawValue)

        public let rawValue: UInt

        public init(rawValue: UInt) { self.rawValue = rawValue }
    }
}

extension RegularExpression.Options {
    func xlate() -> NSRegularExpression.Options {
        var o: NSRegularExpression.Options = [] /*@f:0*/
        if self.contains(.caseInsensitive)            { o.insert(.caseInsensitive)            }
        if self.contains(.allowCommentsAndWhitespace) { o.insert(.allowCommentsAndWhitespace) }
        if self.contains(.ignoreMetacharacters)       { o.insert(.ignoreMetacharacters)       }
        if self.contains(.dotMatchesLineSeparators)   { o.insert(.dotMatchesLineSeparators)   }
        if self.contains(.anchorsMatchLines)          { o.insert(.anchorsMatchLines)          }
        if self.contains(.useUnixLineSeparators)      { o.insert(.useUnixLineSeparators)      }
        if self.contains(.useUnicodeWordBoundaries)   { o.insert(.useUnicodeWordBoundaries)   }
        return o /*@f:1*/
    }
}

extension NSRegularExpression.Options {
    func xlate() -> RegularExpression.Options {
        var o: RegularExpression.Options = [] /*@f:0*/
        if self.contains(.caseInsensitive)            { o.insert(.caseInsensitive)            }
        if self.contains(.allowCommentsAndWhitespace) { o.insert(.allowCommentsAndWhitespace) }
        if self.contains(.ignoreMetacharacters)       { o.insert(.ignoreMetacharacters)       }
        if self.contains(.dotMatchesLineSeparators)   { o.insert(.dotMatchesLineSeparators)   }
        if self.contains(.anchorsMatchLines)          { o.insert(.anchorsMatchLines)          }
        if self.contains(.useUnixLineSeparators)      { o.insert(.useUnixLineSeparators)      }
        if self.contains(.useUnicodeWordBoundaries)   { o.insert(.useUnicodeWordBoundaries)   }
        return o /*@f:1*/
    }
}

extension RegularExpression.MatchingOptions {
    func xlate() -> NSRegularExpression.MatchingOptions {
        var o: NSRegularExpression.MatchingOptions = [] /*@f:0*/
        if self.contains(.reportProgress)         { o.insert(.reportProgress)         }
        if self.contains(.reportCompletion)       { o.insert(.reportCompletion)       }
        if self.contains(.anchored)               { o.insert(.anchored)               }
        if self.contains(.withTransparentBounds)  { o.insert(.withTransparentBounds)  }
        if self.contains(.withoutAnchoringBounds) { o.insert(.withoutAnchoringBounds) }
        return o /*@f:1*/
    }
}

extension RegularExpression.MatchingFlags {
    func xlate() -> NSRegularExpression.MatchingFlags {
        var o: NSRegularExpression.MatchingFlags = [] /*@f:0*/
        if self.contains(.progress)      { o.insert(.progress)      }
        if self.contains(.completed)     { o.insert(.completed)     }
        if self.contains(.hitEnd)        { o.insert(.hitEnd)        }
        if self.contains(.requiredEnd)   { o.insert(.requiredEnd)   }
        if self.contains(.internalError) { o.insert(.internalError) }
        return o /*@f:1*/
    }
}

extension NSRegularExpression.MatchingFlags {
    func xlate() -> RegularExpression.MatchingFlags {
        var o: RegularExpression.MatchingFlags = [] /*@f:0*/
        if self.contains(.progress)      { o.insert(.progress)      }
        if self.contains(.completed)     { o.insert(.completed)     }
        if self.contains(.hitEnd)        { o.insert(.hitEnd)        }
        if self.contains(.requiredEnd)   { o.insert(.requiredEnd)   }
        if self.contains(.internalError) { o.insert(.internalError) }
        return o /*@f:1*/
    }
}

