/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: String.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: July 08, 2022
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

public typealias StringIndex = String.Index
public typealias StringRange = Range<StringIndex>

extension String {

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `str.startIndex ..< str.endIndex`.
    public var allRange:     StringRange { startIndex ..< endIndex }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    // Shorthand for `NSRange(str.startIndex ..< str.endIndex, in: str)`
    public var allNSRange:   NSRange { NSRange(startIndex ..< endIndex, in: self) }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `str.trimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters)`.
    public var trimmed:      String { trimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    public var leftTrimmed:  String { leftTrimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    public var rightTrimmed: String { rightTrimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    public func leftTrimmingCharacters(in cs: CharacterSet) -> String {
        whenNotNil(firstIndex { !cs.satisfies(character: $0) }) { substring($0...) } else: { "" }
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    public func rightTrimmingCharacters(in cs: CharacterSet) -> String {
        // I'm not certain that `lastIndex` does or will always search from the end of the string going forward
        // so we'll just do it ourselves.
        var idx: StringIndex = endIndex
        while idx > startIndex {
            formIndex(before: &idx)
            guard cs.satisfies(character: self[idx]) else { return substring(...idx) }
        }
        return ""
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `StringIndex(utf16Offset: o,in: str)`.
    ///
    /// - Parameter o: The integer offset measured in UTF-16 code points.
    /// - Returns: The string index.
    ///
    public func index(utf16Offset o: Int) -> StringIndex {
        StringIndex(utf16Offset: o, in: self)
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    public func range(_ nsRange: NSRange) -> StringRange {
        whenNotNil(StringRange(nsRange, in: self), { $0 }, else: { fatalError("Range indices not valid.") })
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    public func utf16Offset(index: StringIndex) -> Int {
        index.utf16Offset(in: self)
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `NSRange(range, in: str)`
    ///
    /// - Parameter range: An instance of `Range<String.Index>`
    /// - Returns: An instance of `NSRange`
    ///
    public func nsRange(range: StringRange) -> NSRange {
        NSRange(range, in: self)
    }

    public func substring(_ range: NSRange) -> String? {
        guard let r = StringRange(range, in: self) else { return nil }
        return String(self[r])
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `Range<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    public func substring(_ range: StringRange) -> String {
        String(self[range])
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `ClosedRange<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    public func substring(_ range: ClosedRange<StringIndex>) -> String {
        String(self[range])
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `PartialRangeUpTo<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    public func substring(_ range: PartialRangeUpTo<StringIndex>) -> String {
        String(self[range])
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `PartialRangeThrough<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    public func substring(_ range: PartialRangeThrough<StringIndex>) -> String {
        String(self[range])
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `String(str[range])`.
    ///
    /// - Parameter range: An instance of `PartialRangeFrom<String.Index>`.
    /// - Returns: A new string containing the substring from the given range.
    ///
    public func substring(_ range: PartialRangeFrom<StringIndex>) -> String {
        String(self[range])
    }

    /*-------------------------------------------------------------------------------------------------------------------------*/
    /// Shorthand for `str[StringIndex(utf16Offset: i, in: str)]`.
    ///
    /// - Parameter i: the UTF-16 offset.
    /// - Returns: The character at UTF-16 offset.
    ///
    public func charAt(utf16Offset i: Int) -> Character {
        self[StringIndex(utf16Offset: i, in: self)]
    }
}
