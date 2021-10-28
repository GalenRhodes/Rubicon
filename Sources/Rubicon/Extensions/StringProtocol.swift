/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: StringProtocol.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/11/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation

infix operator ==~: ComparisonPrecedence
infix operator !=~: ComparisonPrecedence

let CTRLS: [Character] = [
    "␀", // 0
    "␁", // 1
    "␂", // 2
    "␃", // 3
    "␄", // 4
    "␅", // 5
    "␆", // 6
    "␇", // 7
    "␈", // 8
    "␉", // 9
    "␊", // 10
    "␋", // 11
    "␌", // 12
    "␍", // 13
    "␎", // 14
    "␏", // 15
    "␐", // 16
    "␑", // 17
    "␒", // 18
    "␓", // 19
    "␔", // 20
    "␕", // 21
    "␖", // 22
    "␗", // 23
    "␘", // 24
    "␙", // 25
    "␚", // 26
    "␛", // 27
    "␜", // 28
    "␝", // 29
    "␞", // 30
    "␟", // 31
    "␠", // 32
]

extension StringProtocol {

    @inlinable public var lastIndex: StringIndex? { startIndex < endIndex ? index(before: endIndex) : nil }

    public var visCtrl: String {
        var out: String = ""

        for ch in self {
            let utf8Ch = ch.utf8
            let _b     = (utf8Ch.count == 1 ? utf8Ch[utf8Ch.startIndex] : nil)
            guard let b = _b, ((b < 32) || (b == 127)) else { out.append(ch); continue }
            out.append(b == 127 ? "␡" : CTRLS[Int(b)])
        }

        return out
    }

    @inlinable public func toInteger(defaultValue: Int = 0) -> Int { (Int(self.asString) ?? defaultValue) }

    @inlinable func withLastCharsRemoved(_ count: Int) -> String {
        guard let idx = index(endIndex, offsetBy: -count, limitedBy: startIndex) else { return "" }
        return String(self[startIndex ..< idx])
    }

    /*==========================================================================================================*/
    /// This property returns `true` if the string is empty after trimming whitespaces, newlines, and control
    /// characters.
    ///
    public var isTrimEmpty: Bool { trimmed.isEmpty }

    /*==========================================================================================================*/
    /// Returns an array that cover the entire string.
    ///
    public var fullRange:   StringRange { (startIndex ..< endIndex) }

    /*==========================================================================================================*/
    /// This property returns a copy of the string with whitespaces, newlines, and control characters trimmed from
    /// both ends of the string.
    ///
    public var trimmed:     String { trimmingCharacters(in: CharacterSet.whitespacesAndNewlinesAndControlCharacters) }

    /*==========================================================================================================*/
    /// A copy of this string with '+' characters replaced with spaces and percent encodings decoded.
    ///
    public var urlDecoded:  String { replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? self.asString }

    /*==========================================================================================================*/
    /// This property returns an instance of
    /// <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> that covers the
    /// entire string.
    ///
    public var fullNSRange: NSRange { NSRange(fullRange, in: self) }

    /*==========================================================================================================*/
    /// Case insensitive equals.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand string
    ///   - rhs: The right-hand string
    /// - Returns: `true` if they are equal when compared case insensitively.
    ///
    public static func ==~ (lhs: Self, rhs: Self) -> Bool { (lhs.localizedCaseInsensitiveCompare(rhs) == ComparisonResult.orderedSame) }

    /*==========================================================================================================*/
    /// Case insensitive NOT equals.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand string
    ///   - rhs: The right-hand string
    /// - Returns: `true` if they are not equal when compared case insensitively.
    ///
    public static func !=~ (lhs: Self, rhs: Self) -> Bool { (lhs.localizedCaseInsensitiveCompare(rhs) != ComparisonResult.orderedSame) }

    /*==========================================================================================================*/
    /// Calls the given closure on each element in the sub-sequence defined by the given range in the same order
    /// as a for-in loop.
    ///
    /// - Parameters:
    ///   - inRange: The range of characters to iterate over.
    ///   - body: A closure that takes an element of the sequence as a parameter.
    /// - Throws: Any error thrown by the closure.
    ///
    public func forEach(inRange rng: StringRange, _ body: (Character) throws -> Void) rethrows { for ch in self[rng] { try body(ch) } }

    /*==========================================================================================================*/
    /// Calls the given closure on each element in the sub-sequence defined by the given match and group in the
    /// same order as a for-in loop. In this method the range of the sub-sequence is taken from the given
    /// `RegularExpression.Match` object and an optional index for the capture group. If the group is not provided
    /// then the entire match region is assumed.
    ///
    /// - Parameters:
    ///   - match: The `RegularExpression.Match` object from a previously executed `RegularExpression` search.
    ///   - group: The index of a capture group (`RegularExpression.Group`) within the given match.
    ///   - body: A closure that takes a character of the String or SubString as a parameter.
    /// - Returns: `false` if the match or the group are `nil`, otherwise returns `true`.
    /// - Throws: Any error thrown by the closure.
    ///
    @discardableResult public func forEach(match: RegularExpression.Match?, group: Int = 0, _ body: (Character) throws -> Void) rethrows -> Bool {
        guard let m = match, let r = m[group].range else { return false }
        try forEach(inRange: r, body)
        return true
    }

    /*==========================================================================================================*/
    /// Get the position (line, column) of the index in the given string relative to the given starting position
    /// (line, column).
    ///
    /// - Parameters:
    ///   - idx: The index.
    ///   - position: The starting position. Defaults to (1, 1).
    ///   - tx: The tab size. Defaults to 4.
    /// - Returns: The position (line, column) of the index within the string.
    ///
    public func positionOfIndex(_ idx: Index, position: TextPosition = (1, 1), tabSize tx: Int8 = 4) -> TextPosition {
        var idx = idx
        var pos = position
        while idx < endIndex {
            textPositionUpdate(self[idx], pos: &pos, tabWidth: tx)
            formIndex(after: &idx)
        }
        return pos
    }

    /*==========================================================================================================*/
    /// Returns the <code>[Character](https://developer.apple.com/documentation/swift/Character)</code> at the
    /// `idx`th integer position in the string.
    ///
    /// - Parameter idx: the integer offset into the
    ///                  <code>[String](https://developer.apple.com/documentation/swift/String)</code>.
    /// - Returns: The <code>[Character](https://developer.apple.com/documentation/swift/Character)</code> at the
    ///            offset indicated by `idx`.
    ///
    @inlinable public subscript(_ idx: Int) -> Character {
        self[self.index(self.startIndex, offsetBy: idx)]
    }

    /*==========================================================================================================*/
    /// Returns the <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code> of the
    /// given <code>[Range](https://developer.apple.com/documentation/swift/Range)</code>. A fatal error is thrown
    /// if the range is invalid for the string.
    ///
    /// - Parameter range: the <code>[Range](https://developer.apple.com/documentation/swift/Range)</code> of the
    ///                    <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    /// - Returns: The <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    ///
    @inlinable public subscript(_ range: Range<Int>) -> SubSequence {
        self[index(idx: range.lowerBound) ..< index(idx: range.upperBound)]
    }

    @inlinable public subscript(_ range: ClosedRange<Int>) -> SubSequence {
        self[index(idx: range.lowerBound) ... index(idx: range.upperBound)]
    }

    @inlinable public subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        self[index(idx: range.lowerBound)...]
    }

    @inlinable public subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        self[..<index(idx: range.upperBound)]
    }

    @inlinable public subscript(_ range: PartialRangeThrough<Int>) -> SubSequence {
        self[...index(idx: range.upperBound)]
    }

    @inlinable public func padding<S>(toLength l: Int, withPad p: S, startingAt i: Int = 0, onRight f: Bool) -> String where S: StringProtocol {
        guard !f else { return padding(toLength: l, withPad: p, startingAt: i) }
        return (l > 0 ? (l > count ? "\(p.shift(count: i).fill(count: l - count))\(self)" : String(self[..<l])) : "")
    }

    @inlinable public func fill(count cc: Int) -> String {
        cc > 0 ? String(String(repeating: String(self), count: ((cc / count) + 1))[..<cc]) : ""
    }

    @inlinable public func shift(count cc: Int) -> String {
        guard (1 ..< count).contains(cc) else { return asString }
        return "\(self[cc...])\(self[..<cc])"
    }

    @inlinable func left(count cc: Int) -> String {
        guard cc < count else { return asString }
        return String(self[..<cc])
    }

    @inlinable func right(count cc: Int) -> String {
        guard cc < count else { return asString }
        return String(self[(count - cc)...])
    }

    /*==========================================================================================================*/
    /// Return a copy of this string truncated to a certain number of characters. If the number of characters in
    /// this string is less than `count` then a copy of this string is returned.
    ///
    /// - Parameters:
    ///   - cc: The maximum number of characters in the returned string.
    ///   - f: If true the characters will be removed from the end of the string. If false the characters
    ///        will be removed from the front of the string. The default is true.
    /// - Returns: A copy of this string with, at most, `count` characters.
    ///
    @inlinable func truncate(count cc: Int, backEnd f: Bool = true) -> String {
        ((cc <= 0) ? "" : ((cc >= count) ? asString : String(f ? self[..<cc] : self[(count - cc)...])))
    }

    /*==========================================================================================================*/
    /// Returns the index of the first encounter of any of the given characters starting at the given index.
    ///
    /// - Parameters:
    ///   - chars: The characters to look for.
    ///   - idx: The index in this string to start looking.
    /// - Returns: The index or `nil` if none of the characters are found.
    ///
    public func firstIndex(ofAnyOf chars: Character..., from idx: StringIndex) -> StringIndex? {
        var oIdx = idx
        while oIdx < endIndex {
            if chars.contains(self[oIdx]) { return oIdx }
            formIndex(after: &oIdx)
        }
        return nil
    }

    /*==========================================================================================================*/
    /// Returns a `[StringIndex](https://developer.apple.com/documentation/swift/string/index)>` into this string
    /// from an integer offset.
    ///
    /// - Parameter idx: the integer offset into the string
    /// - Returns: An instance of `[StringIndex](https://developer.apple.com/documentation/swift/string/index)>`
    ///
    public func index(idx: Int) -> StringIndex {
        index(startIndex, offsetBy: idx)
    }

    /*==========================================================================================================*/
    /// Checks to see if this string has any of the given prefixes.
    ///
    /// - Parameter prefixes: the list of prefixes.
    /// - Returns: `true` if this string has any of the prefixes.
    ///
    public func hasAnyPrefix(_ prefixes: String...) -> Bool {
        for p in prefixes { if hasPrefix(p) { return true } }
        return false
    }

    /*==========================================================================================================*/
    /// Checks to see if this string has any of the given suffixes.
    ///
    /// - Parameter suffixes: the list of suffixes.
    /// - Returns: `true` if this string has any of the suffixes.
    ///
    public func hasAnySuffix(_ suffixes: String...) -> Bool {
        for s in suffixes { if hasSuffix(s) { return true } }
        return false
    }

    /*==========================================================================================================*/
    /// Extract the characters of this
    /// <code>[String](https://developer.apple.com/documentation/swift/String)</code> into an
    /// <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> of
    /// <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s. If `splitClusters`
    /// is `true` then characters that are [Grapheme
    /// Clusters](https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID293) will be split
    /// into there individual character components. For example, the American Flag Emoji (🇺🇸) will be split into
    /// the individual unicode characters 🇺 and 🇸 instead of the single American Flag Emoji.
    ///
    /// - Parameter splitClusters: `true` if [Grapheme
    ///                            Clusters](https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID293)
    ///                            should be broken apart.
    /// - Returns: The array of characters.
    ///
    public func getCharacters(splitClusters: Bool = true) -> [Character] {
        var characters: [Character] = []
        for char in self {
            if splitClusters { for scalar in char.unicodeScalars { characters <+ Character(scalar) } }
            else { characters <+ char }
        }
        return characters
    }

    /*==========================================================================================================*/
    /// Test this string to see if it matches the given regular expression pattern.
    ///
    /// - Parameter pattern: the pattern.
    /// - Returns: `true` if the pattern matches this entire string exactly once.
    /// - Throws: If the pattern is malformed.
    ///
    public func matches(pattern: String) throws -> Bool {
        var e: Error? = nil
        guard let regex = RegularExpression(pattern: pattern, error: &e) else { throw e! }
        guard let match = regex.firstMatch(in: String(self)) else { return false }
        return (match.range.lowerBound == startIndex) && (match.range.upperBound == endIndex)
    }

    /*==========================================================================================================*/
    /// Splits this string around matches of the given regular expression pattern. This method works [just like it
    /// does in
    /// Java](https://docs.oracle.com/javase/10/docs/api/java/lang/String.html#split%28java.lang.String,int%29).
    /// The array returned by this method contains each substring of this string that is terminated by another
    /// substring that matches the given regular expression pattern or is terminated by the end of the string. The
    /// substrings in the array are in the order in which they occur in this string. If the regular expression
    /// pattern does not match any part of the input or if the regular expression pattern is invalid then the
    /// resulting array has just one element, namely this string. When there is a positive-width match at the
    /// beginning of this string then an empty leading substring is included at the beginning of the resulting
    /// array. A <code>[zero](https://en.wikipedia.org/wiki/0)</code>-width match at the beginning however never
    /// produces such empty leading substring. The `limit` parameter controls the number of times the regular
    /// expression pattern is applied and therefore affects the length of the resulting array. If the limit n is
    /// greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the regular expression pattern will
    /// be applied at most n - 1 times, the array's length will be no greater than n, and the array's last entry
    /// will contain all input beyond the last matched delimiter. If n is non-positive then the regular expression
    /// pattern will be applied as many times as possible and the array can have any length. If n is
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the regular expression pattern will be applied
    /// as many times as possible, the array can have any length, and trailing empty strings will be discarded.
    ///
    /// The string "`boo:and:foo`", for example, yields the following results with these parameters:
    ///
    /// <table class="gsr">
    ///     <thead>
    ///         <tr>
    ///             <th align="left">Regex</th>
    ///             <th align="left">Limit</th>
    ///             <th align="left">Result</th>
    ///         </tr>
    ///     </thead>
    ///     <tbody>
    ///         <tr>
    ///             <td align="left"><code>:</code></td>
    ///             <td align="left"><code>2</code></td>
    ///             <td align="left"><code>[ "boo", "and:foo" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>:</code></td>
    ///             <td align="left"><code>5</code></td>
    ///             <td align="left"><code>[ "boo", "and", "foo" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>:</code></td>
    ///             <td align="left"><code>-2</code></td>
    ///             <td align="left"><code>[ "boo", "and", "foo" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>o</code></td>
    ///             <td align="left"><code>5</code></td>
    ///             <td align="left"><code>[ "b", "", ":and:f", "", "" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>o</code></td>
    ///             <td align="left"><code>-2</code></td>
    ///             <td align="left"><code>[ "b", "", ":and:f", "", "" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>o</code></td>
    ///             <td align="left"><code>0</code></td>
    ///             <td align="left"><code>[ "b", "", ":and:f" ]</code></td>
    ///         </tr>
    ///     </tbody>
    /// </table>
    ///
    /// - Parameters:
    ///   - pattern: The delimiting regular expression pattern.
    ///   - lim: The result threshold, as described above.
    ///   - error: If the pattern was invalid then this pass-by-reference parameter will hold the error.
    ///
    /// - Returns: The array of strings computed by splitting this string around matches of the given regular
    ///            expression pattern. If the regular expression pattern is invalid then this string will be
    ///            returned as the only element.
    ///
    public func split(on pattern: String, limit: Int = 0, error: inout Error?) -> [String] {
        guard limit != 1 else { return [ asString ] }
        guard let rx = RegularExpression(pattern: pattern, error: &error) else { return [ asString ] }
        return _split(string: asString, regex: rx, limit: limit > 0 ? limit - 1 : Int.max, truncateEmpties: limit == 0)
    }

    /*==========================================================================================================*/
    /// Splits this string around matches of the given regular expression pattern. This method works [just like it
    /// does in
    /// Java](https://docs.oracle.com/javase/10/docs/api/java/lang/String.html#split%28java.lang.String,int%29).
    /// The array returned by this method contains each substring of this string that is terminated by another
    /// substring that matches the given regular expression pattern or is terminated by the end of the string. The
    /// substrings in the array are in the order in which they occur in this string. If the regular expression
    /// pattern does not match any part of the input or the regular expression pattern is invalid then the
    /// resulting array has just one element, namely this string. When there is a positive-width match at the
    /// beginning of this string then an empty leading substring is included at the beginning of the resulting
    /// array. A <code>[zero](https://en.wikipedia.org/wiki/0)</code>-width match at the beginning however never
    /// produces such empty leading substring. The `limit` parameter controls the number of times the regular
    /// expression pattern is applied and therefore affects the length of the resulting array. If the limit n is
    /// greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the regular expression pattern will
    /// be applied at most n - 1 times, the array's length will be no greater than n, and the array's last entry
    /// will contain all input beyond the last matched delimiter. If n is non-positive then the regular expression
    /// pattern will be applied as many times as possible and the array can have any length. If n is
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the regular expression pattern will be applied
    /// as many times as possible, the array can have any length, and trailing empty strings will be discarded.
    ///
    /// The string "`boo:and:foo`", for example, yields the following results with these parameters:
    ///
    /// <table class="gsr">
    ///     <thead>
    ///         <tr>
    ///             <th align="left">Regex</th>
    ///             <th align="left">Limit</th>
    ///             <th align="left">Result</th>
    ///         </tr>
    ///     </thead>
    ///     <tbody>
    ///         <tr>
    ///             <td align="left"><code>:</code></td>
    ///             <td align="left"><code>2</code></td>
    ///             <td align="left"><code>[ "boo", "and:foo" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>:</code></td>
    ///             <td align="left"><code>5</code></td>
    ///             <td align="left"><code>[ "boo", "and", "foo" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>:</code></td>
    ///             <td align="left"><code>-2</code></td>
    ///             <td align="left"><code>[ "boo", "and", "foo" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>o</code></td>
    ///             <td align="left"><code>5</code></td>
    ///             <td align="left"><code>[ "b", "", ":and:f", "", "" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>o</code></td>
    ///             <td align="left"><code>-2</code></td>
    ///             <td align="left"><code>[ "b", "", ":and:f", "", "" ]</code></td>
    ///         </tr>
    ///         <tr>
    ///             <td align="left"><code>o</code></td>
    ///             <td align="left"><code>0</code></td>
    ///             <td align="left"><code>[ "b", "", ":and:f" ]</code></td>
    ///         </tr>
    ///     </tbody>
    /// </table>
    ///
    /// - Parameters:
    ///   - pattern: The delimiting regular expression pattern
    ///   - lim: The result threshold, as described above
    ///
    /// - Returns: The array of strings computed by splitting this string around matches of the given regular
    ///            expression pattern. If the regular expression pattern is invalid then this string will be
    ///            returned as the only element.
    ///
    @inlinable public func split(on pattern: String, limit lim: Int = 0) -> [String] {
        var error: Error? = nil
        return split(on: pattern, limit: lim, error: &error)
    }
}

fileprivate func _split(string str: String, regex rx: RegularExpression, limit lm: Int, truncateEmpties tr: Bool) -> [String] {
    let ranges = _collectRanges(string: str, regex: rx, limit: lm, startIndex: str.startIndex)
    var rIdx   = ranges.endIndex
    if tr { while ranges.startIndex < rIdx && ranges[ranges.index(before: rIdx)].isEmpty { ranges.formIndex(before: &rIdx) } }
    return ranges[ranges.startIndex ..< rIdx].map { String(str[$0]) }
}

private func _collectRanges(string str: String, regex rx: RegularExpression, limit lm: Int, startIndex sIdx: StringIndex) -> [StringRange] {
    var eIdx:   StringIndex   = sIdx
    var ranges: [StringRange] = []
    rx.forEach(in: str) { m, _, f in if let _m = m { f = _split(range: _m.range, startIndex: sIdx, lastIndex: &eIdx, limit: lm, ranges: &ranges) } }
    ranges.append(eIdx ..< str.endIndex)
    return ranges
}

private func _split(range r: StringRange, startIndex: StringIndex, lastIndex: inout StringIndex, limit: Int, ranges: inout [StringRange]) -> Bool {
    guard !(lastIndex == startIndex && lastIndex == r.lowerBound && r.isEmpty) else { return false }
    ranges.append(lastIndex ..< r.lowerBound)
    lastIndex = r.upperBound
    return ranges.count >= limit
}
