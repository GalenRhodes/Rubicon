/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: String.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 3/19/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
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

extension CharacterSet {

    /*===========================================================================================================================================================================*/
    /// A simple concatenation of the
    /// <code>[CharacterSet.whitespacesAndNewlines](https://developer.apple.com/documentation/foundation/characterset/1779801-whitespacesandnewlines)</code> and
    /// <code>[CharacterSet.controlCharacters](https://developer.apple.com/documentation/foundation/characterset/1779846-controlcharacters)</code> character sets.
    ///
    public static let whitespacesAndNewlinesAndControlCharacters: CharacterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet.controlCharacters)
}

extension String {

    /*===========================================================================================================================================================================*/
    /// Allows creating a <code>[String](https://developer.apple.com/documentation/swift/string/)</code> from the contents of an
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream)</code>.
    /// 
    /// - Parameters:
    ///   - inputStream: the input stream.
    ///   - encoding: the encoding. Defaults to <code>[String.Encoding.utf8](https://developer.apple.com/documentation/swift/string/encoding/1780106-utf8)</code>
    ///
    public init?(inputStream: InputStream, encoding: String.Encoding = String.Encoding.utf8) {
        if inputStream.status(in: .notOpen) {
            inputStream.open()
        }
        if let data = Data(inputStream: inputStream) {
            self.init(data: data, encoding: encoding)
        }
        else {
            return nil
        }
    }
}

public func tabCalc(pos i: Int32, tabSize sz: Int8 = 4) -> Int32 { let s = Int32(sz); return (((((i - 1) + s) / s) * s) + 1) }

public func textPositionUpdate(_ char: Character, pos: inout TextPosition, tabWidth sz: Int8 = 4) { pos = nextCharPosition(currentPosition: pos, character: char, tabWidth: sz) }

public func nextCharPosition(currentPosition pos: TextPosition, character char: Character, tabWidth sz: Int8 = 4) -> TextPosition {
    switch char {
        case "\n", "\r", "\r\n": return (pos.0 + 1, 1)
        case "\t":               return (pos.0, tabCalc(pos: pos.1, tabSize: sz))
        case "\u{0c}":           return (pos.0 + 24, 1)
        case "\u{0b}":           return (tabCalc(pos: pos.0, tabSize: sz), pos.1)
        default:                 return (pos.0, pos.1 + 1)
    }
}

infix operator ==~: ComparisonPrecedence
infix operator !=~: ComparisonPrecedence

extension StringProtocol {

    /*===========================================================================================================================================================================*/
    /// This property returns `true` if the string is empty after trimming whitespaces, newlines, and control characters.
    ///
    public var isTrimEmpty: Bool { trimmed.isEmpty }

    /*===========================================================================================================================================================================*/
    /// Returns an array that cover the entire string.
    ///
    public var fullRange:   Range<String.Index> { (startIndex ..< endIndex) }

    /*===========================================================================================================================================================================*/
    /// This property returns a copy of the string with whitespaces, newlines, and control characters trimmed from both ends of the string.
    ///
    public var trimmed:     String { trimmingCharacters(in: CharacterSet.whitespacesAndNewlinesAndControlCharacters) }

    /*===========================================================================================================================================================================*/
    /// A copy of this string with '+' characters replaced with spaces and percent encodings decoded.
    ///
    public var urlDecoded:  String { replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String(self) }

    /*===========================================================================================================================================================================*/
    /// This property returns an instance of <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> that covers the entire string.
    ///
    public var fullNSRange: NSRange { NSRange(fullRange, in: self) }

    /*===========================================================================================================================================================================*/
    /// Case insensitive equals.
    /// 
    /// - Parameters:
    ///   - lhs: the left-hand string
    ///   - rhs: the right-hand string
    /// - Returns: `true` if they are equal when compared case insensitively.
    ///
    public static func ==~ (lhs: Self, rhs: Self) -> Bool { (lhs.localizedCaseInsensitiveCompare(rhs) == ComparisonResult.orderedSame) }

    /*===========================================================================================================================================================================*/
    /// Case insensitive NOT equals.
    /// 
    /// - Parameters:
    ///   - lhs: the left-hand string
    ///   - rhs: the right-hand string
    /// - Returns: `true` if they are not equal when compared case insensitively.
    ///
    public static func !=~ (lhs: Self, rhs: Self) -> Bool { (lhs.localizedCaseInsensitiveCompare(rhs) != ComparisonResult.orderedSame) }

    /*===========================================================================================================================================================================*/
    /// Calls the given closure on each element in the sub-sequence defined by the given range in the same order as a for-in loop.
    /// 
    /// - Parameters:
    ///   - inRange: The range of characters to iterate over.
    ///   - body: A closure that takes an element of the sequence as a parameter.
    /// - Throws: Any error thrown by the closure.
    ///
    public func forEach(inRange: Range<String.Index>, _ body: (Character) throws -> Void) rethrows {
        var idx = inRange.lowerBound
        while idx < inRange.upperBound {
            try body(self[idx])
            formIndex(after: &idx)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Calls the given closure on each element in the sub-sequence defined by the given match and group in the same order as a for-in loop. In this method the range of the
    /// sub-sequence is taken from the given `RegularExpression.Match` object and an optional index for the capture group. If the group is not provided then the entire match
    /// region is assumed.
    /// 
    /// - Parameters:
    ///   - match: The `RegularExpression.Match` object from a previously executed `RegularExpression` search.
    ///   - group: The index of a capture group (`RegularExpression.Group`) within the given match.
    ///   - body: A closure that takes a character of the String or SubString as a parameter.
    /// - Returns: `false` if the match or the group are `nil`, otherwise returns `true`.
    /// - Throws: Any error thrown by the closure.
    ///
    @discardableResult public func forEach(match: RegularExpression.Match?, group: Int = 0, _ body: (Character) throws -> Void) rethrows -> Bool {
        if let m = match, let r = m[group].range {
            try forEach(inRange: r, body)
            return true
        }
        return false
    }

    /*===========================================================================================================================================================================*/
    /// Get the position (line, column) of the index in the given string relative to the given starting position (line, column).
    /// 
    /// - Parameters:
    ///   - idx: the index.
    ///   - position: the starting position. Defaults to (1, 1).
    ///   - tx: the tab size. Defaults to 4.
    /// - Returns: the position (line, column) of the index within the string.
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

    /*===========================================================================================================================================================================*/
    /// Returns the <code>[Character](https://developer.apple.com/documentation/swift/Character)</code> at the `idx`th integer position in the string.
    /// 
    /// - Parameter idx: the integer offset into the <code>[String](https://developer.apple.com/documentation/swift/String)</code>.
    /// - Returns: the <code>[Character](https://developer.apple.com/documentation/swift/Character)</code> at the offset indicated by `idx`.
    ///
    public subscript(_ idx: Int) -> Character {
        self[self.index(self.startIndex, offsetBy: idx)]
    }

    /*===========================================================================================================================================================================*/
    /// Returns the <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code> of the given
    /// <code>[Range](https://developer.apple.com/documentation/swift/Range)</code>. A fatal error is thrown if the range is invalid for the string.
    /// 
    /// - Parameter range: the <code>[Range](https://developer.apple.com/documentation/swift/Range)</code> of the
    ///                    <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    /// - Returns: the <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    ///
    public subscript(_ range: Range<Int>) -> Substring {
        Substring(self[index(idx: range.lowerBound) ..< index(idx: range.upperBound)])
    }

    /*===========================================================================================================================================================================*/
    /// Returns the index of the first encounter of any of the given characters starting at the given index.
    /// 
    /// - Parameters:
    ///   - chars: the characters to look for.
    ///   - idx: the index in this string to start looking.
    /// - Returns: the index or `nil` if none of the characters are found.
    ///
    public func firstIndex(ofAnyOf chars: Character..., from idx: String.Index) -> String.Index? {
        var oIdx = idx
        while oIdx < endIndex {
            if chars.contains(self[oIdx]) { return oIdx }
            formIndex(after: &oIdx)
        }
        return nil
    }

    /*===========================================================================================================================================================================*/
    /// Returns a `[String.Index](https://developer.apple.com/documentation/swift/string/index)>` into this string from an integer offset.
    /// 
    /// - Parameter idx: the integer offset into the string
    /// - Returns: an instance of `[String.Index](https://developer.apple.com/documentation/swift/string/index)>`
    ///
    public func index(idx: Int) -> String.Index {
        index(startIndex, offsetBy: idx)
    }

    /*===========================================================================================================================================================================*/
    /// Returns an instance of `[Range](https://developer.apple.com/documentation/swift/range)<[String.Index](https://developer.apple.com/documentation/swift/string/index)>` from
    /// an instance of <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code>. If
    /// <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> is invalid for this string then `nil` is returned.
    /// 
    /// - Parameter nsRange: the <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> to convert to
    ///                      `[Range](https://developer.apple.com/documentation/swift/range/)<Index>`
    /// - Returns: an instance of `[Range](https://developer.apple.com/documentation/swift/range)<[String.Index](https://developer.apple.com/documentation/swift/string/index)>` or
    ///            `nil` if the <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> was invalid for this string.
    ///
    public func range(nsRange: NSRange) -> Range<String.Index>? {
        guard nsRange.location != NSNotFound else {
            return nil
        }
        return nsRange.strRange(string: self)
    }

    /*===========================================================================================================================================================================*/
    /// Checks to see if this string has any of the given prefixes.
    /// 
    /// - Parameter prefixes: the list of prefixes.
    /// - Returns: `true` if this string has any of the prefixes.
    ///
    public func hasAnyPrefix(_ prefixes: String...) -> Bool {
        for p in prefixes { if hasPrefix(p) { return true } }
        return false
    }

    /*===========================================================================================================================================================================*/
    /// Checks to see if this string has any of the given suffixes.
    /// 
    /// - Parameter suffixes: the list of suffixes.
    /// - Returns: `true` if this string has any of the suffixes.
    ///
    public func hasAnySuffix(_ suffixes: String...) -> Bool {
        for s in suffixes { if hasSuffix(s) { return true } }
        return false
    }

    /*===========================================================================================================================================================================*/
    /// Extract the characters of this <code>[String](https://developer.apple.com/documentation/swift/String)</code> into an
    /// <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s. If
    /// `splitClusters` is `true` then characters that are [Grapheme Clusters](https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID293) will be split into
    /// there individual character components. For example, the American Flag Emoji (🇺🇸) will be split into the individual unicode characters 🇺 and 🇸 instead of the single American
    /// Flag Emoji.
    /// 
    /// - Parameter splitClusters: `true` if [Grapheme Clusters](https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID293) should be broken apart.
    /// - Returns: the array of characters.
    ///
    public func getCharacters(splitClusters: Bool = true) -> [Character] {
        var characters: [Character] = []
        for char in self {
            if splitClusters { for scalar in char.unicodeScalars { characters <+ Character(scalar) } }
            else { characters <+ char }
        }
        return characters
    }

    /*===========================================================================================================================================================================*/
    /// Test this string to see if it matches the given regular expression pattern.
    /// 
    /// - Parameter pattern: the pattern.
    /// - Returns: `true` if the pattern matches this entire string exactly once.
    /// - Throws: if the pattern is malformed.
    ///
    public func matches(pattern: String) throws -> Bool {
        var e: Error? = nil
        if let regex = RegularExpression(pattern: pattern, error: &e) {
            if let match = regex.firstMatch(in: String(self)) {
                if let r = match[0].range {
                    return (r.lowerBound == startIndex) && (r.upperBound == endIndex)
                }
            }
            return false
        }
        throw e!
    }

    /*===========================================================================================================================================================================*/
    /// Given a valid range for for this string, return a UTF-16 based NSRange structure.
    /// 
    /// - Parameter range: the range.
    /// - Returns: the NSRange.
    ///
    public func nsRange(_ range: Range<String.Index>) -> NSRange { NSRange(range, in: self) }

    /*===========================================================================================================================================================================*/
    /// Returns a new <code>[String](https://developer.apple.com/documentation/swift/string/)</code> instance that contains the
    /// <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code> of the given `from:` and `to:` bounds. A <code>[fatal
    /// error](https://developer.apple.com/documentation/swift/1538698-fatalerror)</code> is thrown if the bounds are invalid for the string.
    /// 
    /// - Parameters:
    ///   - from: The index of the start of the substring.
    ///   - to: The index (exclusive) of the end of the string.
    /// - Returns: the substring
    ///
    public func substr(from fromIdx: Int = 0, to toIdx: Int) -> String {
        String(self[fromIdx ..< toIdx])
    }

    /*===========================================================================================================================================================================*/
    /// Returns a new <code>[String](https://developer.apple.com/documentation/swift/string/)</code> instance that contains the
    /// <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code> of the given `from:` index for the `length:` characters. A <code>[fatal
    /// error](https://developer.apple.com/documentation/swift/1538698-fatalerror)</code> is thrown if the bounds are invalid for the string.
    /// 
    /// - Parameters:
    ///   - from: The index of the start of the substring.
    ///   - length: The number of characters to include in the substring.
    /// - Returns: the substring
    ///
    public func substr(from fromIdx: Int = 0, length: Int) -> String {
        substr(from: fromIdx, to: (fromIdx + length))
    }

    /*===========================================================================================================================================================================*/
    /// Returns a new <code>[String](https://developer.apple.com/documentation/swift/string/)</code> instance that contains the
    /// <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code> of the given
    /// <code>[Range](https://developer.apple.com/documentation/swift/Range)</code>. A <code>[fatal
    /// error](https://developer.apple.com/documentation/swift/1538698-fatalerror)</code> is thrown if the bounds are invalid for the string.
    /// 
    /// - Parameter range: the <code>[Range](https://developer.apple.com/documentation/swift/Range)</code> of the
    ///                    <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    /// - Returns: a new <code>[String](https://developer.apple.com/documentation/swift/string/)</code> instance that contains the
    ///            <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    ///
    public func substr(from fromIdx: Int) -> String {
        String(self[index(idx: fromIdx) ..< endIndex])
    }

    /*===========================================================================================================================================================================*/
    /// Returns a new <code>[String](https://developer.apple.com/documentation/swift/string/)</code> instance that contains the
    /// <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code> of the given
    /// <code>[NSRange](https://developer.apple.com/documentation/foundation/NSRange)</code>. A <code>[fatal
    /// error](https://developer.apple.com/documentation/swift/1538698-fatalerror)</code> is thrown if the bounds are invalid for the string.
    /// 
    /// - Parameter nsRange: the <code>[NSRange](https://developer.apple.com/documentation/foundation/NSRange)</code> of the
    ///                      <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>
    /// - Returns: a new <code>[String](https://developer.apple.com/documentation/swift/string/)</code> instance that contains the
    ///            <code>[Substring](https://developer.apple.com/documentation/swift/Substring)</code>.
    ///
    public func substr(nsRange: NSRange) -> String {
        guard let range: Range<String.Index> = self.range(nsRange: nsRange) else {
            fatalError("NSRange values invalid for this string.")
        }
        return String(self[range])
    }

    /*===========================================================================================================================================================================*/
    /// Splits this string around matches of the given regular expression. This method works [just like it does in
    /// Java](https://docs.oracle.com/javase/10/docs/api/java/lang/[String](https://developer.apple.com/documentation/swift/string/).html#`split(java.lang.String,int)`). The array
    /// returned by this method contains each substring of this string that is terminated by another substring that matches the given expression or is terminated by the end of the
    /// string. The substrings in the array are in the order in which they occur in this string. If the expression does not match any part of the input then the resulting array
    /// has just one element, namely this string. When there is a positive-width match at the beginning of this string then an empty leading substring is included at the beginning
    /// of the resulting array. A <code>[zero](https://en.wikipedia.org/wiki/0)</code>-width match at the beginning however never produces such empty leading substring. The
    /// `limit` parameter controls the number of times the pattern is applied and therefore affects the length of the resulting array. If the limit n is greater than
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the pattern will be applied at most n - 1 times, the array's length will be no greater than n, and the array's
    /// last entry will contain all input beyond the last matched delimiter. If n is non-positive then the pattern will be applied as many times as possible and the array can have
    /// any length. If n is <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the pattern will be applied as many times as possible, the array can have any length, and
    /// trailing empty strings will be discarded.
    /// 
    /// The string "`boo:and:foo`", for example, yields the following results with these parameters:
    /// 
    /// <table class="gsr">
    ///     <thead>
    ///         <tr>
    ///             <th align="left">Regex</th>
    ///             <th align="left">Limit</th>
    ///             <th align="left">[Result](https://developer.apple.com/documentation/swift/result/)</th>
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
    ///   - pattern: the delimiting regular expression
    ///   - lim: the result threshold, as described above
    /// 
    /// - Returns: the array of strings computed by splitting this string around matches of the given regular expression
    ///
    public func split(on pattern: String, limit lim: Int = 0) -> [String] {
        if lim != 1, let regex: RegEx = try? RegEx(pattern: pattern) {
            var results: [String]     = []
            var last:    String.Index = startIndex

            regex.enumerateMatches(in: String(self), range: fullNSRange) { m, _, p in if let m = m { if self.split(m.range, ((lim > 0) ? (lim - 1) : Int.max), &results, &last) { p.pointee = true } } }

            if !results.isEmpty {
                return ((lim == 0) ? trimSplitArray(array: &results) : results)
            }
        }

        return [ String(self) ]
    }

    /*===========================================================================================================================================================================*/
    /// The body of the closure for `split(pattern:lim:)`.
    /// 
    /// - Parameters:
    ///   - nsRng: the NSRange of the match.
    ///   - lim:  the limit.
    ///   - results: the results array.
    ///   - last: the last split point.
    /// - Returns: `true` if further matching should stop because the limit has been reached.
    ///
    private func split(_ nsRng: NSRange, _ lim: Int, _ results: inout [String], _ last: inout String.Index) -> Bool {
        if nsRng.location != NSNotFound, let rng: Range<Index> = nsRng.strRange(string: self) {
            let subStringRange: Range<String.Index> = (last ..< rng.lowerBound)

            if !(rng.isEmpty && subStringRange.isEmpty) {
                results.append(String(self[subStringRange]))
            }

            last = rng.upperBound

            if results.count >= lim {
                results.append(String(self[last ..< self.endIndex]))
                return true
            }
        }

        return false
    }

    /*===========================================================================================================================================================================*/
    /// Trim the empty strings off of the array of strings. Used by `split(pattern:lim:)`.
    /// 
    /// - Parameter results: the array of strings.
    /// - Returns: the trimmed array.
    ///
    private func trimSplitArray(array results: inout [String]) -> [String] {
        let cc: Int = results.count

        if (cc > 1) && results.last!.isEmpty {
            for i in stride(from: (cc - 1), through: 0, by: -1) {
                if !results[i].isEmpty {
                    results.removeSubrange((i + 1) ..< cc)
                    return results
                }
            }

            return [ results[0] ]
        }

        return results
    }
}
