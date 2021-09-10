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

/*==============================================================================================================*/
/// RegularExpression is a replacement for NSRegularExpression that is much more Swift friendly.
/// 
/// A Note about the methods that take closures: I know that having these methods as throws rather than a rethrows
/// is not ideal but given that NSRegularExpression, which we’re actually using underneath, doesn't allow it’s
/// closure to be throws sort of leaves us no choice. At least I haven’t found an easy way around it. So I decided
/// to have these methods as throws and in the future, if we can fix this issue, make them rethrows then.
/// 
/// BLOG Post with Examples: [I, Introvert - A Better
/// RegularExpression](https://blog.projectgalen.com/2021/02/12/a-better-regularexpression/)
///
open class RegularExpression {

    /*==========================================================================================================*/
    /// The options specified during creation.
    ///
    public let options: Options
    /*==========================================================================================================*/
    /// The pattern specified during creation.
    ///
    public private(set) lazy var pattern:               String = nsRegex.pattern
    /*==========================================================================================================*/
    /// The number of capture groups in the pattern.
    ///
    public private(set) lazy var numberOfCaptureGroups: Int    = nsRegex.numberOfCaptureGroups
    /*==========================================================================================================*/
    /// The underlying instance of
    /// <code>[NSRegularExpression](https://developer.apple.com/documentation/foundation/NSRegularExpression)</code>.
    ///
    @usableFromInline let nsRegex: NSRegularExpression

    /*==========================================================================================================*/
    /// Returns an initialized `RegularExpression` instance with the specified regular expression pattern and
    /// options. If an error occurs then `nil` is returned.
    /// 
    /// - Parameters:
    ///   - pattern: The regular expression pattern.
    ///   - options: The options.
    ///   - error: If initialization fails then this parameter will be set to the error.
    ///
    public init?(pattern: String, options: Options = [], error: inout Error?) {
        do {
            self.options = options
            nsRegex = try NSRegularExpression(pattern: pattern, options: options.convert())
        }
        catch let e {
            error = e
            return nil
        }
    }
}

extension RegularExpression {
    public typealias MatchEnumClosure = (Match?, MatchingFlags, inout Bool) throws -> Void

    /*==========================================================================================================*/
    /// Returns an initialized `RegularExpression` instance with the specified regular expression pattern and
    /// options. If an error occurs then `nil` is returned.
    /// 
    /// - Parameters:
    ///   - pattern: The regular expression pattern.
    ///   - options: The options.
    ///
    @inlinable public convenience init?(pattern: String, options: Options = []) {
        var e: Error? = nil
        self.init(pattern: pattern, options: options, error: &e)
    }

    /*==========================================================================================================*/
    /// Returns a string by adding backslash escapes as necessary to protect any characters that would match as
    /// pattern metacharacters.
    /// 
    /// Returns a string by adding backslash escapes as necessary to the given string, to escape any characters
    /// that would otherwise be treated as pattern metacharacters. You typically use this method to match on a
    /// particular string within a larger pattern.
    /// 
    /// For example, the string "(N/A)" contains the pattern metacharacters (, /, and ). The result of adding
    /// backslash escapes to this string is "\\(N\\/A\\)".
    /// 
    /// - Parameter string: An object that implements the
    ///                     <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///                     protocol.
    /// - Returns: The escaped string.
    ///
    @inlinable public class func escapedPattern<S>(for string: S) -> String where S: StringProtocol { NSRegularExpression.escapedPattern(for: toString(string)) }

    /*==========================================================================================================*/
    /// Returns a template string by adding backslash escapes as necessary to protect any characters that would
    /// match as pattern metacharacters
    /// 
    /// Returns a string by adding backslash escapes as necessary to the given string, to escape any characters
    /// that would otherwise be treated as pattern metacharacters. You typically use this method to match on a
    /// particular string within a larger pattern.
    /// 
    /// For example, the string "(N/A)" contains the pattern metacharacters (, /, and ). The result of adding
    /// backslash escapes to this string is "\\(N\\/A\\)".
    /// 
    /// See Flag Options for the format of the resulting template string.
    /// 
    /// - Parameter string: An object that implements the
    ///                     <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///                     protocol.
    /// - Returns: The escaped template string.
    ///
    @inlinable public class func escapedTemplate<S>(for string: S) -> String where S: StringProtocol { NSRegularExpression.escapedTemplate(for: toString(string)) }

    /*==========================================================================================================*/
    /// Returns the number of matches of the regular expression within the specified range of the string.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    ///   - range: The range of the string to search.
    /// - Returns: The number of matches of the regular expression.
    ///
    @inlinable public func numberOfMatches(in str: String, options: MatchingOptions = [], range: Range<String.Index>) -> Int {
        nsRegex.numberOfMatches(in: str, options: options.convert(), range: NSRange(range, in: str))
    }

    /*==========================================================================================================*/
    /// Returns the number of matches of the regular expression within the specified range of the string.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    /// - Returns: The number of matches of the regular expression.
    ///
    @inlinable public func numberOfMatches<S>(in str: S, options: MatchingOptions = []) -> Int where S: StringProtocol {
        let s = toString(str)
        return numberOfMatches(in: s, options: options, range: s.fullRange)
    }

    /*==========================================================================================================*/
    /// Returns the range of the first match.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    ///   - range: The range of the string to search.
    /// - Returns: The range of the first match of `nil` if the match was not found.
    ///
    @inlinable public func rangeOfFirstMatch(in str: String, options: MatchingOptions = [], range: Range<String.Index>) -> Range<String.Index>? {
        str.range(nsRange: nsRegex.rangeOfFirstMatch(in: str, options: options.convert(), range: NSRange(range, in: str)))
    }

    /*==========================================================================================================*/
    /// Returns the range of the first match.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    /// - Returns: The range of the first match of `nil` if the match was not found.
    ///
    @inlinable public func rangeOfFirstMatch<S>(in str: S, options: MatchingOptions = []) -> Range<String.Index>? where S: StringProtocol {
        let s = toString(str)
        return rangeOfFirstMatch(in: s, options: options, range: s.fullRange)
    }

    /*==========================================================================================================*/
    /// Returns the first `RegularExpression.Match` found in the search string.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    ///   - range: The range of the string to search.
    /// - Returns: The first `RegularExpression.Match` found in the search string or `nil` if the match was not
    ///            found.
    ///
    @inlinable public func firstMatch(in str: String, options: MatchingOptions = [], range: Range<String.Index>) -> Match? {
        guard let match = nsRegex.firstMatch(in: str, options: options.convert(), range: NSRange(range, in: str)) else { return nil }
        return Match(str, match: match)
    }

    /*==========================================================================================================*/
    /// Returns the first `RegularExpression.Match` found in the search string.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    /// - Returns: The first `RegularExpression.Match` found in the search string or `nil` if the match was not
    ///            found.
    ///
    @inlinable public func firstMatch<S>(in str: S, options: MatchingOptions = []) -> Match? where S: StringProtocol {
        let s = toString(str)
        return firstMatch(in: s, options: options, range: s.fullRange)
    }

    /*==========================================================================================================*/
    /// Returns all of the `RegularExpression.Match`s found in the search string.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    ///   - range: The range of the string to search.
    /// - Returns: An array of `RegularExpression.Match`s found in the search string or an empty array if the
    ///            match was not found.
    ///
    @inlinable public func matches(in str: String, options: MatchingOptions = [], range: Range<String.Index>) -> [Match] {
        nsRegex.matches(in: str, options: options.convert(), range: NSRange(range, in: str)).map { Match(str, match: $0)! }
    }

    /*==========================================================================================================*/
    /// Returns all of the `RegularExpression.Match`s found in the search string.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to use. See `RegularExpression.MatchingOptions` for possible values.
    /// - Returns: An array of `RegularExpression.Match`s found in the search string or an empty array if the
    ///            match was not found.
    ///
    @inlinable public func matches<S>(in str: S, options: MatchingOptions = []) -> [Match] where S: StringProtocol {
        let s = toString(str)
        return matches(in: s, options: options, range: s.fullRange)
    }

    /*==========================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// <b>NOTE:</b> Having this as a throwing function rather than a rethrowing function is not ideal but given
    /// that NSRegularExpression doesn't allow the closure to throw anything sort of removes that option from us.
    /// At least I haven't found an easy way around it. So I decided to have to have this method `throws` and in
    /// the future, if we can fix this issue, make it `rethrows` then.
    /// 
    /// This method is the fundamental matching method for regular expressions and is suitable for overriding by
    /// subclassers. There are additional convenience methods for returning all the matches as an array, the total
    /// number of matches, the first match, and the range of the first match.
    /// 
    /// By default, the Block iterator method calls the Block precisely once for each match, with a non-`nil`
    /// match and the appropriate flags. The client may then stop the operation by returning `true` from the block
    /// instead of `false`.
    /// 
    /// If the `RegularExpression.MatchingOptions.reportProgress` matching option is specified, the Block will
    /// also be called periodically during long-running match operations, with `nil` result and progress matching
    /// flag set in the Block’s flags parameter, at which point the client may again stop the operation by
    /// returning `true` instead of `false`.
    /// 
    /// If the `RegularExpression.MatchingOptions.reportCompletion` matching option is specified, the Block object
    /// will be called once after matching is complete, with `nil` result and the completed matching flag is set
    /// in the flags passed to the Block, plus any additional relevant `RegularExpression.MatchingFlags` from
    /// among `RegularExpression.MatchingFlags.hitEnd`, `RegularExpression.MatchingFlags.requiredEnd`, or
    /// `RegularExpression.MatchingFlags.internalError`.
    /// 
    /// `RegularExpression.MatchingFlags.progress` and `RegularExpression.MatchingFlags.completed` matching flags
    /// have no effect for methods other than this method.
    /// 
    /// The `RegularExpression.MatchingFlags.hitEnd` matching flag is set in the flags passed to the Block if the
    /// current match operation reached the end of the search range. The
    /// `RegularExpression.MatchingFlags.requiredEnd` matching flag is set in the flags passed to the Block if the
    /// current match depended on the location of the end of the search range.
    /// 
    /// The `RegularExpression.MatchingFlags` matching flag is set in the flags passed to the block if matching
    /// failed due to an internal error (such as an expression requiring exponential memory allocations) without
    /// examining the entire search range.
    /// 
    /// The `RegularExpression.Options.anchored`, `RegularExpression.Options.withTransparentBounds`, and
    /// `RegularExpression.Options.withoutAnchoringBounds` regular expression options, specified in the options
    /// property specified when the regular expression instance is created, can apply to any match or replace
    /// method.
    /// 
    /// If `RegularExpression.Options.anchored` matching option is specified, matches are limited to those at the
    /// start of the search range.
    /// 
    /// If `RegularExpression.Options.withTransparentBounds` matching option is specified, matching may examine
    /// parts of the string beyond the bounds of the search range, for purposes such as word boundary detection,
    /// lookahead, etc.
    /// 
    /// If `RegularExpression.Options.withoutAnchoringBounds` matching option is specified, ^ and $ will not
    /// automatically match the beginning and end of the search range, but will still match the beginning and end
    /// of the entire string.
    /// 
    /// `RegularExpression.Options.withTransparentBounds` and `RegularExpression.Options.withoutAnchoringBounds`
    /// matching options have no effect if the search range covers the entire string.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported
    ///              values.
    ///   - range: The range of the string to search.
    ///   - body: The Block that is called for each match found in the search string. The Block takes two (2)
    ///           parameters&#58; <dl><dt><b><i>match</i></b></dt><dd>An instance of `RegularExpression.Match` or
    ///           `nil` if the Block is simply being called with the flags
    ///           `RegularExpression.MatchingFlags.completed`, `RegularExpression.MatchingFlags.hitEnd`, or
    ///           `RegularExpression.MatchingFlags.internalError`</dd> <dt><b><i>flags</i></b></dt><dd>An array of
    ///           `RegularExpression.MatchingFlags`.</dd></dl> The closure returns `true` to stop the enumeration
    ///           or `false` to continue to the next match.
    ///
    @inlinable public func forEachMatch(in str: String, options: MatchingOptions = [], range: Range<String.Index>, using body: MatchEnumClosure) rethrows {
        try withoutActuallyEscaping(body) { (_body) -> Void in
            var error: Error? = nil
            nsRegex.enumerateMatches(in: str, options: options.convert(), range: NSRange(range, in: str)) { result, flags, stop in
                var fStop: Bool = false
                do {
                    try _body(((result == nil) ? nil : Match(str, match: result!)), flags.convert(), &fStop)
                }
                catch let e {
                    error = e
                    fStop = true
                }
                stop.pointee = ObjCBool(fStop)
            }
            if let e = error { throw e }
        }
    }

    /*==========================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// <b>NOTE:</b> Having this as a throwing function rather than a rethrowing function is not ideal but given
    /// that NSRegularExpression doesn't allow the closure to throw anything sort of removes that option from us.
    /// At least I haven't found an easy way around it. So I decided to have to have this method `throws` and in
    /// the future, if we can fix this issue, make it `rethrows` then.
    /// 
    /// This method is the fundamental matching method for regular expressions and is suitable for overriding by
    /// subclassers. There are additional convenience methods for returning all the matches as an array, the total
    /// number of matches, the first match, and the range of the first match.
    /// 
    /// By default, the Block iterator method calls the Block precisely once for each match, with a non-`nil`
    /// match and the appropriate flags. The client may then stop the operation by returning `true` from the block
    /// instead of `false`.
    /// 
    /// If the `RegularExpression.MatchingOptions.reportProgress` matching option is specified, the Block will
    /// also be called periodically during long-running match operations, with `nil` result and progress matching
    /// flag set in the Block’s flags parameter, at which point the client may again stop the operation by
    /// returning `true` instead of `false`.
    /// 
    /// If the `RegularExpression.MatchingOptions.reportCompletion` matching option is specified, the Block object
    /// will be called once after matching is complete, with `nil` result and the completed matching flag is set
    /// in the flags passed to the Block, plus any additional relevant `RegularExpression.MatchingFlags` from
    /// among `RegularExpression.MatchingFlags.hitEnd`, `RegularExpression.MatchingFlags.requiredEnd`, or
    /// `RegularExpression.MatchingFlags.internalError`.
    /// 
    /// `RegularExpression.MatchingFlags.progress` and `RegularExpression.MatchingFlags.completed` matching flags
    /// have no effect for methods other than this method.
    /// 
    /// The `RegularExpression.MatchingFlags.hitEnd` matching flag is set in the flags passed to the Block if the
    /// current match operation reached the end of the search range. The
    /// `RegularExpression.MatchingFlags.requiredEnd` matching flag is set in the flags passed to the Block if the
    /// current match depended on the location of the end of the search range.
    /// 
    /// The `RegularExpression.MatchingFlags` matching flag is set in the flags passed to the block if matching
    /// failed due to an internal error (such as an expression requiring exponential memory allocations) without
    /// examining the entire search range.
    /// 
    /// The `RegularExpression.Options.anchored`, `RegularExpression.Options.withTransparentBounds`, and
    /// `RegularExpression.Options.withoutAnchoringBounds` regular expression options, specified in the options
    /// property specified when the regular expression instance is created, can apply to any match or replace
    /// method.
    /// 
    /// If `RegularExpression.Options.anchored` matching option is specified, matches are limited to those at the
    /// start of the search range.
    /// 
    /// If `RegularExpression.Options.withTransparentBounds` matching option is specified, matching may examine
    /// parts of the string beyond the bounds of the search range, for purposes such as word boundary detection,
    /// lookahead, etc.
    /// 
    /// If `RegularExpression.Options.withoutAnchoringBounds` matching option is specified, ^ and $ will not
    /// automatically match the beginning and end of the search range, but will still match the beginning and end
    /// of the entire string.
    /// 
    /// `RegularExpression.Options.withTransparentBounds` and `RegularExpression.Options.withoutAnchoringBounds`
    /// matching options have no effect if the search range covers the entire string.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported
    ///              values.
    ///   - body: The Block that is called for each match found in the search string. The Block takes two (2)
    ///           parameters&#58; <dl><dt><b><i>match</i></b></dt><dd>An instance of `RegularExpression.Match` or
    ///           `nil` if the Block is simply being called with the flags
    ///           `RegularExpression.MatchingFlags.completed`, `RegularExpression.MatchingFlags.hitEnd`, or
    ///           `RegularExpression.MatchingFlags.internalError`</dd> <dt><b><i>flags</i></b></dt><dd>An array of
    ///           `RegularExpression.MatchingFlags`.</dd></dl> The closure returns `true` to stop the enumeration
    ///           or `false` to continue to the next match.
    ///
    @inlinable public func forEachMatch<S>(in str: S, options: MatchingOptions = [], using block: MatchEnumClosure) rethrows where S: StringProtocol {
        let s: String = toString(str)
        try forEachMatch(in: s, options: options, range: str.fullRange, using: block)
    }

    /*==========================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// This method is the fundamental matching method for regular expressions and is suitable for overriding by
    /// subclassers. There are additional convenience methods for returning all the matches as an array, the total
    /// number of matches, the first match, and the range of the first match.
    /// 
    /// By default, the Block iterator method calls the Block precisely once for each match, with an array of the
    /// `RegularExpression.Group`s representing each capture group. The client may then stop the operation by
    /// returning `true` from the block instead of `false`.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported
    ///              values.
    ///   - range: The range of the string to search.
    ///   - body: The closure that is called for each match found in the search string. The closure takes one
    ///           parameter which is an array of `RegularExpression.Group` objects representing each capture group
    ///           and returns `true` to stop the enumeration or `false` to continue to the next match.
    ///
    @inlinable public func forEachMatchGroup(in str: String, options: MatchingOptions = [], range: Range<String.Index>, using body: ([Group], inout Bool) throws -> Void) rethrows {
        try forEachMatch(in: str, options: options, range: range) { match, _, stop in
            if let m = match {
                var groups: [Group] = []
                for g in m { groups <+ g }
                try body(groups, &stop)
            }
        }
    }

    /*==========================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// This method is the fundamental matching method for regular expressions and is suitable for overriding by
    /// subclassers. There are additional convenience methods for returning all the matches as an array, the total
    /// number of matches, the first match, and the range of the first match.
    /// 
    /// By default, the Block iterator method calls the Block precisely once for each match, with an array of the
    /// `RegularExpression.Group`s representing each capture group. The client may then stop the operation by
    /// returning `true` from the block instead of `false`.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported
    ///              values.
    ///   - body: The closure that is called for each match found in the search string. The closure takes one
    ///           parameter which is an array of `RegularExpression.Group` objects representing each capture group
    ///           and returns `true` to stop the enumeration or `false` to continue to the next match.
    ///
    @inlinable public func forEachMatchGroup<S>(in str: S, options: MatchingOptions = [], using block: ([Group], inout Bool) throws -> Void) rethrows where S: StringProtocol {
        let s: String = toString(str)
        try forEachMatchGroup(in: s, options: options, range: s.fullRange, using: block)
    }

    /*==========================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// - Parameters:
    ///   - str: The search string.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported
    ///              values.
    ///   - range: The range of the string to search.
    ///   - body: The closure that is called for each match found in the search string. The closure takes one
    ///           parameter which is an array of Strings representing each capture group and returns `true` to
    ///           stop the enumeration or `false` to continue to the next match. Any of the strings in the array
    ///           may be `nil` if that capture group did not participate in the match.
    ///
    @inlinable public func forEachMatchString(in str: String, options: MatchingOptions = [], range: Range<String.Index>, using body: ([String?], inout Bool) throws -> Void) rethrows {
        try forEachMatchGroup(in: str, options: options, range: range) { groups, stop in try body(groups.map { $0.subString }, &stop) }
    }

    /*==========================================================================================================*/
    /// Enumerates the string allowing the Block to handle each regular expression match.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The matching options to report. See `RegularExpression.MatchingOptions` for the supported
    ///              values.
    ///   - body: The closure that is called for each match found in the search string. The closure takes one
    ///           parameter which is an array of Strings representing each capture group and returns `true` to
    ///           stop the enumeration or `false` to continue to the next match. Any of the strings in the array
    ///           may be `nil` if that capture group did not participate in the match.
    ///
    @inlinable public func forEachMatchString<S>(in str: S, options: MatchingOptions = [], using body: ([String?], inout Bool) throws -> Void) rethrows where S: StringProtocol {
        let s: String = toString(str)
        try forEachMatchGroup(in: s, options: options, range: s.fullRange) { groups, stop in try body(groups.map { $0.subString }, &stop) }
    }

    /*==========================================================================================================*/
    /// RegularExpression also provides a find-and-replace method strings. The replacement is treated as a
    /// template, with $0 being replaced by the contents of the matched range, $1 by the contents of the first
    /// capture group, and so on. Additional digits beyond the maximum required to represent the number of capture
    /// groups will be treated as ordinary characters, as will a $ not followed by digits. Backslash will escape
    /// both $ and itself.
    /// 
    /// - Parameters:
    ///   - str: The string.
    ///   - options: The match options.
    ///   - range: The range of the string to search in.
    ///   - templ: The replacement template.
    /// - Returns: A tuple with the modified string and the number of replacements made.
    ///
    @inlinable public func stringByReplacingMatches(in str: String, options: MatchingOptions = [], range: Range<String.Index>, withTemplate templ: String) -> (String, Int) {
        let mStr = NSMutableString(string: str)
        let cc   = nsRegex.replaceMatches(in: mStr, options: options.convert(), range: NSRange(range, in: str), withTemplate: templ)
        return (String(mStr), cc)
    }

    /*==========================================================================================================*/
    /// RegularExpression also provides a find-and-replace method strings. The replacement is treated as a
    /// template, with $0 being replaced by the contents of the matched range, $1 by the contents of the first
    /// capture group, and so on. Additional digits beyond the maximum required to represent the number of capture
    /// groups will be treated as ordinary characters, as will a $ not followed by digits. Backslash will escape
    /// both $ and itself.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The match options.
    ///   - templ: The replacement template.
    /// - Returns: A tuple with the modified string and the number of replacements made.
    ///
    @inlinable public func stringByReplacingMatches<S>(in str: S, options: MatchingOptions = [], withTemplate templ: String) -> (String, Int) where S: StringProtocol {
        let s: String = toString(str)
        return stringByReplacingMatches(in: s, options: options, range: s.fullRange, withTemplate: templ)
    }

    /*==========================================================================================================*/
    /// This method will perform a find-and-replace on the provided string by calling the closure for each match
    /// found in the source string and replacing it with the string returned by the closure.
    /// 
    /// - Parameters:
    ///   - str: The source string.
    ///   - options: The match options.
    ///   - range: The range of the string to search in. If `nil` then the entire string will be searched.
    ///   - body: The closure that will return the replacement string. It is called once for each match found in
    ///           the source string.
    /// - Returns: A tuple with the modified string and the number of replacements made.
    /// - Throws: If the closure throws an error.
    ///
    @inlinable public func stringByReplacingMatches(in str: String, options: MatchingOptions = [], range: Range<String.Index>? = nil, using body: (Match) throws -> String) rethrows -> (String, Int) {
        var out: String       = ""
        var cc:  Int          = 0
        var idx: String.Index = str.startIndex

        try forEachMatch(in: str, options: options, range: range ?? str.fullRange) { m, _, _ in
            if let m = m {
                out.append(contentsOf: str[idx ..< m.range.lowerBound])
                out.append(contentsOf: try body(m))
                idx = m.range.upperBound
                cc += 1
            }
        }

        if idx < str.endIndex { out.append(contentsOf: str[idx ..< str.endIndex]) }
        return (out, cc)
    }

    /*==========================================================================================================*/
    /// This method will perform a find-and-replace on the provided string by calling the closure for each match
    /// found in the source string and replacing it with the string returned by the closure.
    /// 
    /// - Parameters:
    ///   - str: An object that implements the
    ///          <code>[StringProtocol](https://developer.apple.com/documentation/swift/StringProtocol)</code>
    ///          protocol.
    ///   - options: The match options.
    ///   - body: The closure that will return the replacement string. It is called once for each match found in
    ///           the source string.
    /// - Returns: A tuple with the modified string and the number of replacements made.
    /// - Throws: If the closure throws an error.
    ///
    @inlinable public func stringByReplacingMatches<S>(in str: S, options: MatchingOptions = [], using body: (Match) throws -> String) rethrows -> (String, Int) where S: StringProtocol {
        let s: String = toString(str)
        return try stringByReplacingMatches(in: s, options: options, range: s.fullRange, using: body)
    }
}

@inlinable func toString<S>(_ str: S) -> String where S: StringProtocol { (str as? String) ?? String(str) }

extension RegularExpression {
    /*==========================================================================================================*/
    /// These constants define the regular expression options. These constants are used by
    /// `init(pattern:options:)`.
    ///
    public struct Options: OptionSet {
        /*======================================================================================================*/
        /// All matches are case-insensitive.
        ///
        public static let caseInsensitive:            Options = Options(rawValue: 1 << 0)
        /*======================================================================================================*/
        /// Ignore whitespace and #-prefixed comments in the pattern.
        ///
        public static let allowCommentsAndWhitespace: Options = Options(rawValue: 1 << 1)
        /*======================================================================================================*/
        /// Treat the entire pattern as a literal string.
        ///
        public static let ignoreMetacharacters:       Options = Options(rawValue: 1 << 2)
        /*======================================================================================================*/
        /// Allow . to match any character, including line separators.
        ///
        public static let dotMatchesLineSeparators:   Options = Options(rawValue: 1 << 3)
        /*======================================================================================================*/
        /// Allow ^ and $ to match the start and end of lines.
        ///
        public static let anchorsMatchLines:          Options = Options(rawValue: 1 << 4)
        /*======================================================================================================*/
        /// Treat only \n as a line separator (otherwise, all standard line separators are used).
        ///
        public static let useUnixLineSeparators:      Options = Options(rawValue: 1 << 5)
        /*======================================================================================================*/
        /// Use Unicode TR#29 to specify word boundaries (otherwise, traditional regular expression word
        /// boundaries are used).
        ///
        public static let useUnicodeWordBoundaries:   Options = Options(rawValue: 1 << 6)

        public let rawValue: Int

        public init(rawValue: Int) { self.rawValue = rawValue }
    }

    /*==========================================================================================================*/
    /// The matching options constants specify the reporting, completion and matching rules to the expression
    /// matching methods. These constants are used by all methods that search for, or replace values, using a
    /// regular expression.
    ///
    public struct MatchingOptions: OptionSet {
        /*======================================================================================================*/
        /// Call the Block periodically during long-running match operations. This option has no effect for
        /// methods other than `forEachMatch(in:options:range:using:)`. See
        /// `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        public static let reportProgress:         MatchingOptions = MatchingOptions(rawValue: (1 << 0))
        /*======================================================================================================*/
        /// Call the Block once after the completion of any matching. This option has no effect for methods other
        /// than `forEachMatch(in:options:range:using:)`. See `forEachMatch(in:options:range:using:)` for a
        /// description of the constant in context.
        ///
        public static let reportCompletion:       MatchingOptions = MatchingOptions(rawValue: (1 << 1))
        /*======================================================================================================*/
        /// Specifies that matches are limited to those at the start of the search range. See
        /// `forEachMatch(in:options:range:using:)` for a description of the constant in context.
        ///
        public static let anchored:               MatchingOptions = MatchingOptions(rawValue: (1 << 2))
        /*======================================================================================================*/
        /// Specifies that matching may examine parts of the string beyond the bounds of the search range, for
        /// purposes such as word boundary detection, lookahead, etc. This constant has no effect if the search
        /// range contains the entire string. See `forEachMatch(in:options:range:using:)` for a description of the
        /// constant in context.
        ///
        public static let withTransparentBounds:  MatchingOptions = MatchingOptions(rawValue: (1 << 3))
        /*======================================================================================================*/
        /// Specifies that ^ and $ will not automatically match the beginning and end of the search range, but
        /// will still match the beginning and end of the entire string. This constant has no effect if the search
        /// range contains the entire string. See `forEachMatch(in:options:range:using:)` for a description of the
        /// constant in context.
        ///
        public static let withoutAnchoringBounds: MatchingOptions = MatchingOptions(rawValue: (1 << 4))

        public let rawValue: UInt8

        public init(rawValue: UInt8) { self.rawValue = rawValue }
    }

    /*==========================================================================================================*/
    /// Set by the Block as the matching progresses, completes, or fails. Used by the method
    /// `forEachMatch(in:options:range:using:)`.
    ///
    public struct MatchingFlags: OptionSet {
        /*======================================================================================================*/
        /// Set when the Block is called to report progress during a long-running match operation.
        ///
        public static let progress:      MatchingFlags = MatchingFlags(rawValue: (1 << 0))
        /*======================================================================================================*/
        /// Set when the Block is called after matching has completed.
        ///
        public static let completed:     MatchingFlags = MatchingFlags(rawValue: (1 << 1))
        /*======================================================================================================*/
        /// Set when the current match operation reached the end of the search range.
        ///
        public static let hitEnd:        MatchingFlags = MatchingFlags(rawValue: (1 << 2))
        /*======================================================================================================*/
        /// Set when the current match depended on the location of the end of the search range.
        ///
        public static let requiredEnd:   MatchingFlags = MatchingFlags(rawValue: (1 << 3))
        /*======================================================================================================*/
        /// Set when matching failed due to an internal error.
        ///
        public static let internalError: MatchingFlags = MatchingFlags(rawValue: (1 << 4))

        public let rawValue: UInt8

        public init(rawValue: UInt8) { self.rawValue = rawValue }
    }
}

extension RegularExpression {
    /*==========================================================================================================*/
    /// This struct encapsulates all of the capture groups of a single match.
    ///
    public final class Match: BidirectionalCollection {
        public typealias Element = Group
        public typealias Index = Int

        /*======================================================================================================*/
        /// The search string.
        ///
        public let string: String
        /*======================================================================================================*/
        /// The range within the search string for the entire match.
        ///
        public let range:  Range<String.Index>
        /*======================================================================================================*/
        /// The sub-string of the entire match region.
        ///
        public lazy var subString: String = String(string[range])
        /*======================================================================================================*/
        /// The index of the first group group.
        ///
        public let startIndex: Index = 0
        /*======================================================================================================*/
        /// The index just past the last capture group.
        ///
        public let endIndex:   Index
        /*======================================================================================================*/
        /// The number of capture groups.
        ///
        public let count:      Int

        @usableFromInline let nsMatch:    NSTextCheckingResult
        @usableFromInline var namedCache: [String: NamedGroup] = [:]
        @usableFromInline var groupCache: [Index: Group]       = [:]

        @usableFromInline init?(_ str: String, match: NSTextCheckingResult?) {
            guard let _match = match else { return nil }
            guard let _range = Range<String.Index>(_match.range, in: str) else { return nil }
            string = str
            range = _range
            nsMatch = _match
            endIndex = _match.numberOfRanges
            count = endIndex
        }
    }

    /*==========================================================================================================*/
    /// This class encapsulates a single capture group.
    ///
    public class Group {
        let string: String

        /*======================================================================================================*/
        /// The range of the search string for this capture group of `nil` if this capture group did not
        /// participate in the match.
        ///
        public let range: Range<String.Index>?
        /*======================================================================================================*/
        /// The substring of the search string for this capture group of `nil` if this capture group did not
        /// participate in the match.
        ///
        public private(set) lazy var subString: String? = ((range == nil) ? nil : String(string[range!]))

        @usableFromInline init(_ string: String, range: NSRange) {
            self.string = string
            self.range = ((range.location == NSNotFound) ? nil : Range<String.Index>(range, in: string))
        }
    }

    /*==========================================================================================================*/
    /// This class encapsulates a single named capture group.
    ///
    public class NamedGroup: Group {
        /*======================================================================================================*/
        /// The name of the capture group.
        ///
        public let name: String

        @usableFromInline init(_ string: String, name: String, range: NSRange) {
            self.name = name
            super.init(string, range: range)
        }
    }
}

extension RegularExpression.Match {
    /*==========================================================================================================*/
    /// Returns a named capture group.
    /// 
    /// - Parameter name: the name of the capture group
    /// - Returns: The named capture group or `nil` if the capture group does not exist.
    ///
    @inlinable public subscript(name: String) -> RegularExpression.NamedGroup? {
        if let ng = namedCache[name] { return ng }
        let range = nsMatch.range(withName: name)
        guard range.location != NSNotFound else { return nil }
        let ng = RegularExpression.NamedGroup(string, name: name, range: range)
        namedCache[name] = ng
        return ng
    }

    /*==========================================================================================================*/
    /// Returns the capture group for the given index.
    /// 
    /// - Parameter position: the index which must be between `startIndex` <= index < `endIndex`.
    /// - Returns: The capture group.
    ///
    @inlinable public subscript(position: Index) -> Element {
        guard position >= startIndex && position < endIndex else { fatalError("Index out of bounds.") }
        if let g = groupCache[position] { return g }
        let g = RegularExpression.Group(string, range: nsMatch.range(at: position))
        groupCache[position] = g
        return g
    }

    /*==========================================================================================================*/
    /// The index after the one given.
    /// 
    /// - Parameter i: the index.
    /// - Returns: The next index.
    ///
    @inlinable public func index(after i: Index) -> Index {
        guard i < endIndex else { fatalError("Index out of bounds.") }
        return i + 1
    }

    /*==========================================================================================================*/
    /// The index before the one given.
    /// 
    /// - Parameter i: the index.
    /// - Returns: The next index.
    ///
    @inlinable public func index(before i: Index) -> Index {
        guard i > 0 else { fatalError("Index out of bounds.") }
        return i - 1
    }

    /*==========================================================================================================*/
    /// Returns an iterator over all the capture groups.
    /// 
    /// - Returns: An iterator.
    ///
    @inlinable public func makeIterator() -> Iterator { Iterator(match: self) }

    /*==========================================================================================================*/
    /// The iterator class.
    ///
    public final class Iterator: IteratorProtocol {
        public typealias Element = RegularExpression.Group

        @usableFromInline var index: Int = 0
        @usableFromInline let match: RegularExpression.Match

        @inlinable init(match: RegularExpression.Match) {
            self.match = match
        }

        /*======================================================================================================*/
        /// Get the next element.
        /// 
        /// - Returns: The next element or `nil` if there are no more elements.
        ///
        @inlinable public func next() -> Element? { ((index < match.endIndex) ? match[index++] : nil) }
    }
}

extension RegularExpression.Options {
    @inlinable func convert() -> NSRegularExpression.Options {
        var o: NSRegularExpression.Options = []
        if contains(.caseInsensitive) { o.insert(.caseInsensitive) }
        if contains(.allowCommentsAndWhitespace) { o.insert(.allowCommentsAndWhitespace) }
        if contains(.ignoreMetacharacters) { o.insert(.ignoreMetacharacters) }
        if contains(.dotMatchesLineSeparators) { o.insert(.dotMatchesLineSeparators) }
        if contains(.anchorsMatchLines) { o.insert(.anchorsMatchLines) }
        if contains(.useUnixLineSeparators) { o.insert(.useUnixLineSeparators) }
        if contains(.useUnicodeWordBoundaries) { o.insert(.useUnicodeWordBoundaries) }
        return o
    }
}

extension RegularExpression.MatchingOptions {
    @inlinable func convert() -> NSRegularExpression.MatchingOptions {
        var o: NSRegularExpression.MatchingOptions = []
        if contains(.reportProgress) { o.insert(.reportProgress) }
        if contains(.reportCompletion) { o.insert(.reportCompletion) }
        if contains(.anchored) { o.insert(.anchored) }
        if contains(.withTransparentBounds) { o.insert(.withTransparentBounds) }
        if contains(.withoutAnchoringBounds) { o.insert(.withoutAnchoringBounds) }
        return o
    }
}
