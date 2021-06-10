/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Array.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/10/20
 *
 * Copyright © 2020 ProjectGalen. All rights reserved.
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

extension RangeReplaceableCollection {
    /*==========================================================================================================*/
    /// Pops the first element off the collection. If the collection is empty then returns `nil`.
    ///
    /// - Returns: The first element off the collection or `nil` if the collection is empty.
    ///
    @inlinable public mutating func popFirst() -> Self.Element? { (isEmpty ? nil : removeFirst()) }

    /*==========================================================================================================*/
    /// Works like `removeAll(where:)` except this version returns an array containing the elements that were
    /// removed.
    ///
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a
    ///                        Boolean value indicating whether the element should be removed from the collection.
    /// - Returns: An array containing the elements that were removed.
    /// - Throws: Any error thrown by the predicate closure.
    ///
    @inlinable public mutating func removeAllGet(where predicate: (Element) throws -> Bool) rethrows -> [Element] {
        var temp: [Element] = []
        try removeAll {
            let r: Bool = try predicate($0)
            if r {
                temp.append($0)
            }
            return r
        }
        return temp
    }
}

extension Collection {
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

    @inlinable public var isNotEmpty: Bool { !isEmpty }
}

extension Array {
    @inlinable public func last(count cc: Int) -> ArraySlice<Element> { self[index(endIndex, offsetBy: -Swift.min(cc, count)) ..< endIndex] }

    @inlinable public func first(count cc: Int) -> ArraySlice<Element> { self[startIndex ..< index(startIndex, offsetBy: Swift.min(cc, count))] }
}

extension ArraySlice {
    @inlinable public func last(count cc: Int) -> ArraySlice<Element> { self[index(endIndex, offsetBy: -Swift.min(cc, count)) ..< endIndex] }

    @inlinable public func first(count cc: Int) -> ArraySlice<Element> { self[startIndex ..< index(startIndex, offsetBy: Swift.min(cc, count))] }
}

extension ArraySlice where Element: Equatable {
    @inlinable public static func == (lhs: Self, rhs: [Element]) -> Bool { (lhs == rhs[rhs.startIndex ..< rhs.endIndex]) }

    @inlinable public static func == (lhs: [Element], rhs: Self) -> Bool { (lhs[lhs.startIndex ..< lhs.endIndex] == rhs) }

    @inlinable public static func != (lhs: Self, rhs: [Element]) -> Bool { !(lhs == rhs) }

    @inlinable public static func != (lhs: [Element], rhs: Self) -> Bool { !(lhs == rhs) }
}

extension Array where Element == Character {
    /// Allows for easy equality check between Strings and Character Arrays. Instead of having to write:
    /// ```Swift
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// ```Swift
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The Character Array.
    ///   - rhs: The String
    /// - Returns: true if the array contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: Self, rhs: String) -> Bool { (String(lhs) == rhs) }
    @inlinable public static func != (lhs: Self, rhs: String) -> Bool { (String(lhs) != rhs) }

    /// Allows for easy equality check between Strings and Character Arrays. Instead of having to write:
    /// ```Swift
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// ```Swift
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The String
    ///   - rhs: The Character Array.
    /// - Returns: true if the array contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: String, rhs: Self) -> Bool { (lhs == String(rhs)) }
    @inlinable public static func != (lhs: String, rhs: Self) -> Bool { (lhs != String(rhs)) }
}

extension ArraySlice where Element == Character {
    /// Allows for easy equality check between Strings and Character ArraySlices. Instead of having to write:
    /// ```Swift
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// ```Swift
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The Character ArraySlice.
    ///   - rhs: The String
    /// - Returns: true if the array slice contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: Self, rhs: String) -> Bool { (String(lhs) == rhs) }
    @inlinable public static func != (lhs: Self, rhs: String) -> Bool { (String(lhs) != rhs) }

    /// Allows for easy equality check between Strings and Character ArraySlices. Instead of having to write:
    /// ```Swift
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// ```Swift
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The String
    ///   - rhs: The Character ArraySlice.
    /// - Returns: true if the array slice contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: String, rhs: Self) -> Bool { (lhs == String(rhs)) }

    /// Allows for easy inequality check between Strings and Character ArraySlices. Instead of having to write:
    /// ```Swift
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if string != String(array) { /* do something */ }
    /// ```
    /// You can now just write:
    /// ```Swift
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if string != array { /* do something */ }
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The Character ArraySlice.
    ///   - rhs: The String
    /// - Returns: false if the array slice contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func != (lhs: String, rhs: Self) -> Bool { (lhs != String(rhs)) }
}
