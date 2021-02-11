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

    /*===========================================================================================================================================================================*/
    /// These constants define the regular expression options. These constants are used by `init(pattern:options:)`.
    ///
    public enum Options {
        /*=======================================================================================================================================================================*/
        /// All matches are case-insensitive.
        ///
        case caseInsensitive
        /*=======================================================================================================================================================================*/
        /// Ignore whitespace and #-prefixed comments in the pattern.
        ///
        case allowCommentsAndWhitespace
        /*=======================================================================================================================================================================*/
        /// Treat the entire pattern as a literal string.
        ///
        case ignoreMetacharacters
        /*=======================================================================================================================================================================*/
        /// Allow . to match any character, including line separators.
        ///
        case dotMatchesLineSeparators
        /*=======================================================================================================================================================================*/
        /// Allow ^ and $ to match the start and end of lines.
        ///
        case anchorsMatchLines
        /*=======================================================================================================================================================================*/
        /// Treat only \n as a line separator (otherwise, all standard line separators are used).
        ///
        case useUnixLineSeparators
        /*=======================================================================================================================================================================*/
        /// Use Unicode TR#29 to specify word boundaries (otherwise, traditional regular expression word boundaries are used).
        ///
        case useUnicodeWordBoundaries
    }

    /*===========================================================================================================================================================================*/
    /// The matching options constants specify the reporting, completion and matching rules to the expression matching methods. These constants are used by all methods that search
    /// for, or replace values, using a regular expression.
    ///
    public enum MatchingOptions {
        /*=======================================================================================================================================================================*/
        /// Call the Block periodically during long-running match operations. This option has no effect for methods other than `forEachMatch(in:options:range:using:)`. See
        /// `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        case reportProgress
        /*=======================================================================================================================================================================*/
        /// Call the Block once after the completion of any matching. This option has no effect for methods other than `forEachMatch(in:options:range:using:)`. See
        /// `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        case reportCompletion
        /*=======================================================================================================================================================================*/
        /// Specifies that matches are limited to those at the start of the search range. See `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        case anchored
        /*=======================================================================================================================================================================*/
        /// Specifies that matching may examine parts of the string beyond the bounds of the search range, for purposes such as word boundary detection, lookahead, etc. This
        /// constant has no effect if the search range contains the entire string. See `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        case withTransparentBounds
        /*=======================================================================================================================================================================*/
        /// Specifies that ^ and $ will not automatically match the beginning and end of the search range, but will still match the beginning and end of the entire string. This
        /// constant has no effect if the search range contains the entire string. See `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        case withoutAnchoringBounds
    }

    /*===========================================================================================================================================================================*/
    /// Set by the Block as the matching progresses, completes, or fails. Used by the method `forEachMatch(in:options:range:using:)`.
    ///
    public enum MatchingFlags {
        /*=======================================================================================================================================================================*/
        /// Set when the Block is called to report progress during a long-running match operation.
        ///
        case progress
        /*=======================================================================================================================================================================*/
        /// Set when the Block is called after matching has completed.
        ///
        case completed
        /*=======================================================================================================================================================================*/
        /// Set when the current match operation reached the end of the search range.
        ///
        case hitEnd
        /*=======================================================================================================================================================================*/
        /// Set when the current match depended on the location of the end of the search range.
        ///
        case requiredEnd
        /*=======================================================================================================================================================================*/
        /// Set when matching failed due to an internal error.
        ///
        case internalError
    }

    /*===========================================================================================================================================================================*/
    /// The options specified during creation.
    ///
    public let options: [RegularExpression.Options]
    /*===========================================================================================================================================================================*/
    /// The pattern specified during creation.
    ///
    open private(set) lazy var pattern:               String = nsRegex.pattern
    /*===========================================================================================================================================================================*/
    /// The number of capture groups in the pattern.
    ///
    open private(set) lazy var numberOfCaptureGroups: Int    = nsRegex.numberOfCaptureGroups
    /*===========================================================================================================================================================================*/
    /// The underlying instance of <code>[NSRegularExpression](https://developer.apple.com/documentation/foundation/NSRegularExpression)</code>.
    ///
    private let nsRegex: NSRegularExpression

    /*===========================================================================================================================================================================*/
    /// Returns an initialized `RegularExpression` instance with the specified regular expression pattern and options. If an error occurs then `nil` is returned.
    /// 
    /// - Parameters:
    ///   - pattern: the regular expression pattern.
    ///   - options: the options.
    ///   - error: if initialization fails then this parameter will be set to the error.
    ///
    public init?(pattern: String, options: [RegularExpression.Options] = [], error: inout Error?) {
        do {
            self.options = options
            nsRegex = try NSRegularExpression(pattern: pattern, options: Options.convert(from: options))
        }
        catch let e {
            error = e
            return nil
        }
    }

    /*===========================================================================================================================================================================*/
    /// Returns an initialized `RegularExpression` instance with the specified regular expression pattern and options. If an error occurs then `nil` is returned.
    /// 
    /// - Parameters:
    ///   - pattern: the regular expression pattern.
    ///   - options: the options.
    ///
    public convenience init?(pattern: String, options: [RegularExpression.Options] = []) {
        var e: Error? = nil
        self.init(pattern: pattern, options: options, error: &e)
    }

    /*===========================================================================================================================================================================*/
    /// Returns a string by adding backslash escapes as necessary to protect any characters that would match as pattern metacharacters.
    /// 
    /// Returns a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as pattern metacharacters. You
    /// typically use this method to match on a particular string within a larger pattern.
    /// 
    /// For example, the string "(N/A)" contains the pattern metacharacters (, /, and ). The result of adding backslash escapes to this string is "\\(N\\/A\\)".
    /// 
    /// - Parameter string: the string.
    /// - Returns: the escaped string.
    ///
    open class func escapedPattern(for string: String) -> String { NSRegularExpression.escapedPattern(for: string) }

    /*===========================================================================================================================================================================*/
    /// Returns a template string by adding backslash escapes as necessary to protect any characters that would match as pattern metacharacters
    /// 
    /// Returns a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as pattern metacharacters. You
    /// typically use this method to match on a particular string within a larger pattern.
    /// 
    /// For example, the string "(N/A)" contains the pattern metacharacters (, /, and ). The result of adding backslash escapes to this string is "\\(N\\/A\\)".
    /// 
    /// See Flag Options for the format of the resulting template string.
    /// 
    /// - Parameter string: the template string.
    /// - Returns: the escaped template string.
    ///
    open class func escapedTemplate(for string: String) -> String { NSRegularExpression.escapedTemplate(for: string) }

    /*===========================================================================================================================================================================*/
    /// Returns the number of matches of the regular expression within the specified range of the string.
    /// 
    /// - Parameters:
    ///   - str: the search string.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    ///   - range: the range of the string to search.
    /// - Returns: the number of matches of the regular expression.
    ///
    open func numberOfMatches(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil) -> Int {
        nsRegex.numberOfMatches(in: str, options: MatchingOptions.convert(from: options), range: nsRange(range, string: str))
    }

    open func rangeOfFirstMatch(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil) -> Range<String.Index>? {
        str.range(nsRange: nsRegex.rangeOfFirstMatch(in: str, options: MatchingOptions.convert(from: options), range: nsRange(range, string: str)))
    }

    open func firstMatch(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil) -> Match? {
        guard let match = nsRegex.firstMatch(in: str, options: MatchingOptions.convert(from: options), range: nsRange(range, string: str)) else { return nil }
        return Match(str, match: match)
    }

    open func matches(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil) -> [Match] {
        nsRegex.matches(in: str, options: MatchingOptions.convert(from: options), range: nsRange(range, string: str)).map { Match(str, match: $0) }
    }

    /*===========================================================================================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// - Parameters:
    ///   - str: the search string.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported values.
    ///   - range: the range of the string to search.
    ///   - body: the Block that is called for each match found in the search string. The Block takes three (2) parameters: 1) An instance of `RegularExpression.Match` or `nil` if
    ///                                                                                                                     the Block is simply being called with the flags
    ///                                                                                                                     `RegularExpression.MatchingFlags.completed`,
    ///                                                                                                                     `RegularExpression.MatchingFlags.hitEnd`, or
    ///                                                                                                                     `RegularExpression.MatchingFlags.internalError`; 2) An
    ///                                                                                                                     array of `RegularExpression.MatchingFlags`. The Block
    ///                                                                                                                     returns `true` to end the search early.
    ///
    open func forEachMatch(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil, using body: (Match?, [MatchingFlags]) -> Bool) {
        nsRegex.enumerateMatches(in: str, options: MatchingOptions.convert(from: options), range: nsRange(range, string: str)) { result, flags, stop in
            let match: Match? = ((result == nil) ? nil : Match(str, match: result!))
            stop.pointee = (body(match, MatchingFlags.convert(from: flags)) ? true : false)
        }
    }

    open func forEachMatchGroup(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil, using body: ([Group]) -> Bool) {
        forEachMatch(in: str, options: options, range: range) { match, _ in ((match != nil) && body(match!.groups)) }
    }

    open func forEachMatchString(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil, using body: ([String?]) -> Bool) {
        forEachMatchGroup(in: str, options: options, range: range) { groups in body(groups.map { $0.subString }) }
    }

    /*===========================================================================================================================================================================*/
    /// RegularExpression also provides a find-and-replace method strings. The replacement is treated as a template, with $0 being replaced by the contents of the matched range,
    /// $1 by the contents of the first capture group, and so on. Additional digits beyond the maximum required to represent the number of capture groups will be treated as
    /// ordinary characters, as will a $ not followed by digits. Backslash will escape both $ and itself.
    /// 
    /// - Parameters:
    ///   - string: the string.
    ///   - options: the match options.
    ///   - range: the range of the string to search in.
    ///   - templ: the replacement template.
    /// - Returns: a tuple with the modified string and the number of replacements made.
    ///
    open func stringByReplacingMatches(in str: String, options: [RegularExpression.MatchingOptions] = [], range: Range<String.Index>? = nil, withTemplate templ: String) -> (String, Int) {
        let mStr = NSMutableString(string: str)
        let cc = nsRegex.replaceMatches(in: mStr, options: MatchingOptions.convert(from: options), range: nsRange(range, string: str), withTemplate: templ)
        return (String(mStr), cc)
    }

    public final class Match: Sequence, Collection {
        public typealias Element = Group
        public typealias Index = Int

        public let string:     String
        public var startIndex: Index { groups.startIndex }
        public var endIndex:   Index { groups.endIndex }
        public var count:      Int { groups.count }

        @usableFromInline let nsMatch:    NSTextCheckingResult
        @usableFromInline var namedCache: [String: NamedGroup] = [:]

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

    @inlinable final func nsRange(_ range: Range<String.Index>?, string str: String) -> _NSRange { ((range == nil) ? str.fullNSRange : str.nsRange(range!)) }
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

extension RegularExpression.Options {
    static func convert(from options: NSRegularExpression.Options) -> [RegularExpression.Options] {
        var o: [RegularExpression.Options] = []
        if options.contains(NSRegularExpression.Options.caseInsensitive) { o <+ RegularExpression.Options.caseInsensitive }
        if options.contains(NSRegularExpression.Options.allowCommentsAndWhitespace) { o <+ RegularExpression.Options.allowCommentsAndWhitespace }
        if options.contains(NSRegularExpression.Options.ignoreMetacharacters) { o <+ RegularExpression.Options.ignoreMetacharacters }
        if options.contains(NSRegularExpression.Options.dotMatchesLineSeparators) { o <+ RegularExpression.Options.dotMatchesLineSeparators }
        if options.contains(NSRegularExpression.Options.anchorsMatchLines) { o <+ RegularExpression.Options.anchorsMatchLines }
        if options.contains(NSRegularExpression.Options.useUnixLineSeparators) { o <+ RegularExpression.Options.useUnixLineSeparators }
        if options.contains(NSRegularExpression.Options.useUnicodeWordBoundaries) { o <+ RegularExpression.Options.useUnicodeWordBoundaries }
        return o
    }

    static func convert(from options: [RegularExpression.Options]) -> NSRegularExpression.Options {
        var o: NSRegularExpression.Options = []
        for x: RegularExpression.Options in options {
            switch x {
                case .caseInsensitive:            o.insert(NSRegularExpression.Options.caseInsensitive)
                case .allowCommentsAndWhitespace: o.insert(NSRegularExpression.Options.allowCommentsAndWhitespace)
                case .ignoreMetacharacters:       o.insert(NSRegularExpression.Options.ignoreMetacharacters)
                case .dotMatchesLineSeparators:   o.insert(NSRegularExpression.Options.dotMatchesLineSeparators)
                case .anchorsMatchLines:          o.insert(NSRegularExpression.Options.anchorsMatchLines)
                case .useUnixLineSeparators:      o.insert(NSRegularExpression.Options.useUnixLineSeparators)
                case .useUnicodeWordBoundaries:   o.insert(NSRegularExpression.Options.useUnicodeWordBoundaries)
            }
        }
        return o
    }
}

extension RegularExpression.MatchingOptions {
    static func convert(from options: [RegularExpression.MatchingOptions]) -> NSRegularExpression.MatchingOptions {
        var o: NSRegularExpression.MatchingOptions = []
        for x: RegularExpression.MatchingOptions in options {
            switch x {
                case .reportProgress:         o.insert(NSRegularExpression.MatchingOptions.reportProgress)
                case .reportCompletion:       o.insert(NSRegularExpression.MatchingOptions.reportCompletion)
                case .anchored:               o.insert(NSRegularExpression.MatchingOptions.anchored)
                case .withTransparentBounds:  o.insert(NSRegularExpression.MatchingOptions.withTransparentBounds)
                case .withoutAnchoringBounds: o.insert(NSRegularExpression.MatchingOptions.withoutAnchoringBounds)
            }
        }
        return o
    }
}

extension RegularExpression.MatchingFlags {
    static func convert(from options: NSRegularExpression.MatchingFlags) -> [RegularExpression.MatchingFlags] {
        var o: [RegularExpression.MatchingFlags] = []
        if options.contains(NSRegularExpression.MatchingFlags.progress) { o <+ RegularExpression.MatchingFlags.progress }
        if options.contains(NSRegularExpression.MatchingFlags.completed) { o <+ RegularExpression.MatchingFlags.completed }
        if options.contains(NSRegularExpression.MatchingFlags.hitEnd) { o <+ RegularExpression.MatchingFlags.hitEnd }
        if options.contains(NSRegularExpression.MatchingFlags.requiredEnd) { o <+ RegularExpression.MatchingFlags.requiredEnd }
        if options.contains(NSRegularExpression.MatchingFlags.internalError) { o <+ RegularExpression.MatchingFlags.internalError }
        return o
    }
}
