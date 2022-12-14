// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: String.swift
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

public typealias StringIndex = String.Index
public typealias StringRange = Range<StringIndex>

extension String {

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `str.startIndex ..< str.endIndex`.
    @inlinable public var allRange:     StringRange { startIndex ..< endIndex }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    // Shorthand for `NSRange(str.startIndex ..< str.endIndex, in: str)`
    @inlinable public var allNSRange:   NSRange { NSRange(startIndex ..< endIndex, in: self) }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `str.trimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters)`.
    @inlinable public var trimmed:      String { trimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public var leftTrimmed:  String { leftTrimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public var rightTrimmed: String { rightTrimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public func leftTrimmingCharacters(in cs: CharacterSet) -> String {
        whenNotNil(firstIndex { !cs.satisfies(character: $0) }) { substring($0...) } else: { "" }
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public var escapedForCommandLine: String {
        let str = replacing("\\", with: "\\\\").replacing("\"", with: "\\\"")
        #if os(Windows)
            return str
        #else
            return str.replacing(" ", with: "\\ ")
        #endif
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public func rightTrimmingCharacters(in cs: CharacterSet) -> String {
        // I'm not certain that `lastIndex` does or will always search from the end of the string going forward
        // so we'll just do it ourselves.
        var idx: StringIndex = endIndex
        while idx > startIndex {
            formIndex(before: &idx)
            guard cs.satisfies(character: self[idx]) else { return substring(...idx) }
        }
        return ""
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `StringIndex(utf16Offset: o,in: str)`.
    ///
    /// - Parameter o: The integer offset measured in UTF-16 code points.
    /// - Returns: The string index.
    ///
    @inlinable public func index(utf16Offset o: Int) -> StringIndex {
        StringIndex(utf16Offset: o, in: self)
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public func range(_ nsRange: NSRange) -> StringRange {
        whenNotNil(StringRange(nsRange, in: self), { $0 }, else: { fatalError("Range indices not valid.") })
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    @inlinable public func utf16Offset(index: StringIndex) -> Int {
        index.utf16Offset(in: self)
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `NSRange(range, in: str)`
    ///
    /// - Parameter range: An instance of `Range<String.Index>`
    /// - Returns: An instance of `NSRange`
    ///
    @inlinable public func nsRange(range: StringRange) -> NSRange {
        NSRange(range, in: self)
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[Range<String.Index>(range, in: str)!])`.
    ///
    /// - Parameter range: An instance of `Range<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    @inlinable public func substring(_ range: NSRange) -> String? {
        guard let r = StringRange(range, in: self) else { return nil }
        return String(self[r])
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `Range<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    @inlinable public func substring(_ range: StringRange) -> String {
        String(self[range])
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `ClosedRange<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    @inlinable public func substring(_ range: ClosedRange<StringIndex>) -> String {
        String(self[range])
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `PartialRangeUpTo<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    @inlinable public func substring(_ range: PartialRangeUpTo<StringIndex>) -> String {
        String(self[range])
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `PartialRangeThrough<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    @inlinable public func substring(_ range: PartialRangeThrough<StringIndex>) -> String {
        String(self[range])
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `PartialRangeFrom<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    @inlinable public func substring(_ range: PartialRangeFrom<StringIndex>) -> String {
        String(self[range])
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `str[StringIndex(utf16Offset: i, in: str)]`.
    ///
    /// - Parameter i: the UTF-16 offset.
    /// - Returns: The character at UTF-16 offset.
    ///
    @inlinable public func charAt(utf16Offset i: Int) -> Character {
        self[StringIndex(utf16Offset: i, in: self)]
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Returns an array of strings from the array of string ranges.
    ///
    /// - Parameter ranges: the array of string ranges.
    /// - Returns: an array of strings.
    ///
    @inlinable public func strings(fromRanges ranges: [StringRange]) -> [String] {
        ranges.map { String(self[$0]) }
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Splits this string around matches of the given regular expression.
    ///
    /// Works like the <a href="https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/lang/String.html#split(java.lang.String,int)">java.lang.String.split(String, int)</a>
    /// method in Java.
    ///
    /// <b>UNLIKE</b> the Java version, this method also contains an option to also retrieve the separators too.
    ///
    /// The array returned by this method contains each substring of this string that is terminated by another substring that
    /// matches the given expression or is terminated by the end of the string. The substrings in the array are in the order in
    /// which they occur in this string. If the expression does not match any part of the input then the resulting array has
    /// just one element, namely this string.
    ///
    /// When there is a positive-width match at the beginning of this string then an empty leading substring is included at the
    /// beginning of the resulting array. A zero-width match at the beginning however never produces such empty leading
    /// substring.
    ///
    /// The limit parameter controls the number of times the pattern is applied and therefore affects the length of the
    /// resulting array.
    ///
    /// If the limit is positive then the pattern will be applied at most limit - 1 times, the array's length will be no
    /// greater than limit, and the array's last entry will contain all input beyond the last matched delimiter.
    ///
    /// If the limit is zero then the pattern will be applied as many times as possible, the array can have any length, and
    /// trailing empty strings will be discarded.
    ///
    /// If the limit is negative then the pattern will be applied as many times as possible and the array can have any length.
    ///
    /// The string "boo:and:foo", for example, yields the following results with these parameters:
    ///
    /// | Regex | Limit | Keep&nbsp;</br>Separators | Result                                            |
    /// |:-----:|:-----:|:-------------------------:|:--------------------------------------------------|
    /// |   :   |   2   |        false              | { "boo", "and:foo" }                              |
    /// |   :   |   5   |        false              | { "boo", "and", "foo" }                           |
    /// |   :   |  -2   |        false              | { "boo", "and", "foo" }                           |
    /// |   o   |   5   |        false              | { "b", "", ":and:f", "", "" }                     |
    /// |   o   |  -2   |        false              | { "b", "", ":and:f", "", "" }                     |
    /// |   o   |   0   |        false              | { "b", "", ":and:f" }                             |
    /// |   :   |   3   |        true               | { "boo", ":", "and:foo" }                         |
    /// |   :   |   5   |        true               | { "boo", ":", "and", ":", "foo" }                 |
    /// |   :   |  -2   |        true               | { "boo", ":", "and", ":", "foo" }                 |
    /// |   o   |  15   |        true               | { "b", "o", "", "o", ":and:f", "o", "", "o", "" } |
    /// |   o   |  -2   |        true               | { "b", "o", "", "o", ":and:f", "o", "", "o", "" } |
    /// |   o   |   0   |        true               | { "b", "o", "", "o", ":and:f", "o", "", "o" }     |
    ///
    /// - Parameters:
    ///   - regex:          The delimiting regular expression
    ///   - limit:          The result threshold, as described above. The default is 0 (zero).
    ///   - keepSeparators: If true then the separators are also included as separate elements in between the match elements.
    ///                     If false (the default) they are not included.
    /// - Returns: The array of strings computed by splitting this string around matches of the given regular expression.
    ///            This array will always contain at least one element.
    ///
    public func split(regex: String, limit: Int = 0, keepSeparators: Bool = false) -> [String] {
        guard limit != 1 && !isEmpty else { return [ self ] }

        var error:     Error?        = nil
        var list:      [StringRange] = []
        var lastIndex: StringIndex   = startIndex

        guard let rx = RegularExpression(pattern: regex, error: &error) else { fatalError(error?.localizedDescription ?? "InvalidPattern: \(regex)") }
        rx.enumerateMatches(in: self) { match, _, stop in if let range = match?.range { doSplit(range, limit, keepSeparators, &lastIndex, &stop, &list) } }
        return limit == 0 ? trimRangeList(&list) : strings(fromRanges: list)
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Trim empty ranges from the end of the list and return an array of the remaining strings.
    ///
    /// - Parameter list: The list of string ranges.
    /// - Returns: An array of strings.
    ///
    @inlinable func trimRangeList(_ list: inout [StringRange]) -> [String] {
        while let rng = list.last, rng.isEmpty { list.removeLast() }
        if list.count == 0 { return [ "" ] }
        return strings(fromRanges: list)
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Process a single match range.
    ///
    /// - Parameters:
    ///   - range: The range of the substring encompassing the separator.
    ///   - limit: If greater than zero then this is the maximum number of items we can have in our list.
    ///   - keepSeparators: A flag that indicates whether or not the caller wants the separator substring included in the results.
    ///   - lastIndex: The end of the previous match range.
    ///   - stop: A boolean flag that, if set to `true`, will indicate that splitting should cease.
    ///   - list: The list of substring ranges.
    ///
    @inlinable func doSplit(_ range: StringRange, _ limit: Int, _ keepSeparators: Bool, _ lastIndex: inout StringIndex, _ stop: inout Bool, _ list: inout [StringRange]) {
        appendSplitItem(range, &lastIndex, &list)
        guard endSplit(limit, &lastIndex, &stop, &list) && keepSeparators else { return }
        list.append(range)
        endSplit(limit, &lastIndex, &stop, &list)
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// Append a split item range.
    ///
    /// - Parameters:
    ///   - range: The range of the substring encompassing the separator.
    ///   - lastIndex: The end of the previous match range.
    ///   - list: The list of substring ranges.
    ///
    @inlinable func appendSplitItem(_ range: StringRange, _ lastIndex: inout StringIndex, _ list: inout [StringRange]) {
        if (range.lowerBound > startIndex) || (!range.isEmpty) { list.append(lastIndex ..< range.lowerBound) }
        lastIndex = range.upperBound
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /// If we've reached the limit for the number of items we can have in our array then we append the remainder of the string and set the stop flag to true.
    ///
    /// - Parameters:
    ///   - limit: If greater than zero then this is the maximum number of items we can have in our list.
    ///   - lastIndex: The end of the previous match range.
    ///   - stop: A boolean flag that, if set to `true`, will indicate that splitting should cease.
    ///   - list: The list of substring ranges.
    /// - Returns: `true` if we should continue.
    ///
    @inlinable @discardableResult func endSplit(_ limit: Int, _ lastIndex: inout StringIndex, _ stop: inout Bool, _ list: inout [StringRange]) -> Bool {
        if (limit > 0) && (list.count >= (limit - 1)) {
            list.append(lastIndex ..< endIndex)
            lastIndex = endIndex
            stop = true
        }
        return !stop
    }
}
