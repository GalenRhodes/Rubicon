/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: Collections.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/6/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
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

extension Collection {
    /*==========================================================================================================*/
    /// Unlike Collection.indices, this property simply builds a range as (`startIndex` ..< `endIndex`).
    ///
    @inlinable public var indexRange: Range<Self.Index> { (startIndex ..< endIndex) }

    /*==========================================================================================================*/
    /// Returns an array of all the elements of this array for which the predicate closure returns `true`.
    ///
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a
    ///                        Boolean value indicating whether the element should be included in the returned
    ///                        array.
    /// - Returns: A new array.
    /// - Throws: Any error thrown by the predicate closure.
    ///
    @inlinable public func all(where predicate: (Element) throws -> Bool) rethrows -> [Element] {
        var temp: [Element] = []
        try forEach {
            if try predicate($0) {
                temp.append($0)
            }
        }
        return temp
    }

    /*==========================================================================================================*/
    /// Iterates over the collection executing the closure for each element. If the closure returns `true` for an
    /// element then iteration halts and `true` is returned. If the closure returns `false` for all the elements
    /// then `false` is returned.
    ///
    /// - Parameter body: the closure which takes the element as it's only parameter and returns a boolean.
    /// - Returns: `false` if the closure returns `false` for all the elements in the collection.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func isAny(predicate body: (Element) throws -> Bool) rethrows -> Bool {
        for e in self { if try body(e) { return true } }
        return false
    }

    /*==========================================================================================================*/
    /// Iterates over the collection executing the closure for each element. If the closure returns `false` for an
    /// element then iteration halts and `false` is returned. If the closure returns `true` for all the elements
    /// then `true` is returned.
    ///
    /// - Parameter body: the closure which takes the element as it's only parameter and returns a boolean.
    /// - Returns: `true` if the closure returns `true` for all the elements in the collection.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable public func areAll(predicate body: (Element) throws -> Bool) rethrows -> Bool {
        for e in self { guard try body(e) else { return false } }
        return true
    }

    /*==========================================================================================================*/
    /// The same as writing `!array.isEmpty`.
    ///
    @inlinable public var isNotEmpty: Bool { !isEmpty }

    /*==========================================================================================================*/
    /// Returns the index of the last element in the collection. If the collection is empty then the `startIndex`,
    /// which is the same as the `endIndex`, is returned.
    ///
    @inlinable public var lastIndex:  Self.Index {
        var i = startIndex
        guard i < endIndex else { return i }
        var j = index(after: i)
        while j < endIndex {
            i = j
            formIndex(after: &j)
        }
        return i
    }
}

extension Collection where Element == Character {
    /*==========================================================================================================*/
    /// Return this collection as a string.  If this collection is actually a string then it simply returns itself.
    ///
    @inlinable public var asString:  String { ((self as? String) ?? String(self)) }

    /*==========================================================================================================*/
    /// Returns the first character in the collection.
    ///
    /// - Precondition: There has to be at least one character in the collection or a fatal error will be thrown.
    ///
    @inlinable public var firstChar: Character { self[startIndex] }

    /*==========================================================================================================*/
    /// Returns the last character in the collection.
    ///
    /// - Precondition: There has to be at least one character in the collection or a fatal error will be thrown.
    ///
    @inlinable public var lastChar:  Character { self[lastIndex] }

    @inlinable public func surroundedWith(_ s1: String, _ s2: String? = nil) -> String { "\(s1)\(self)\(s2 ?? s1)" }

    @inlinable public func quoted(quote: Character = "\"") -> String { surroundedWith(String(quote)) }

    /*==========================================================================================================*/
    /// If this character collection starts and ends with either a single or double quote then those quotes are
    /// remove from the returned string.
    ///
    /// - Precondition: The starting and ending character must be the same. If, for example, the string is
    ///                 "Robert' then the quotes
    ///                 *are not* removed.
    /// - Parameters:
    ///   - trimBefore: If set to `true` then the string will be trimmed of whitespace before looking for quotes.
    ///   - quotes: A list of possible quotation marks. Defaults to the set " and '.
    /// - Returns: A string with the quotes removed.
    ///
    public func unQuoted(trimBefore: Bool = true, quotes: Character...) -> String {
        let q:   [Character] = ((quotes.count > 0) ? quotes : [ "\"", "'" ])
        let str: String      = (trimBefore ? asString.trimmed : asString)

        guard str.count > 1 else { return str }

        let si: StringIndex = str.startIndex
        let ei: StringIndex = str.index(before: str.endIndex)
        let sc: Character    = str[si]

        guard value(sc, isOneOf: q) && sc == str[ei] else { return str }
        return String(str[str.index(after: si) ..< ei])
    }

    /*==========================================================================================================*/
    /// Returns a String with all XML entity references converted to their characters.
    ///
    /// - Returns: A String.
    ///
    public func decodeXMLEntities() -> String {
        var out: String     = ""
        var idx: Self.Index = startIndex

        while idx < endIndex {
            let ch = self[idx]
            formIndex(after: &idx)

            if ch == "&" {
                var i1 = idx
                while (i1 < endIndex) && (self[i1] != ";") { formIndex(after: &i1) }

                if idx < endIndex, let rep: Character = StandardEntities1[self[idx ..< i1].asString] {
                    out.append(rep)
                    idx = index(after: i1)
                }
                else {
                    out.append(ch)
                }
            }
            else {
                out.append(ch)
            }
        }

        return out
    }

    /*==========================================================================================================*/
    /// Returns a string with all XML entities converted to their references. For example, the character '&' will
    /// be converted to the reference "&amp;".
    ///
    /// - Returns: A String
    ///
    public func encodeXMLEntities() -> String {
        var out: String = ""
        for ch in self {
            if let rep = StandardEntities2[ch] { out += rep }
            else { out.append(ch) }
        }
        return out
    }
}

private let StandardEntities1: [String: Character] = [ "amp": "&", "lt": "<", "gt": ">", "apos": "'", "quot": "\"" ]
private let StandardEntities2: [Character: String] = StandardEntities1.mapKV { (key, value) in (value, key) }

extension BidirectionalCollection {
    /*==========================================================================================================*/
    /// Returns the index of the last element in the collection. If the collection is empty then the `startIndex`,
    /// which is the same as the `endIndex`, is returned.
    ///
    @inlinable public var lastIndex: Self.Index { ((startIndex < endIndex) ? index(before: endIndex) : startIndex) }
}
