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

public func == <T: Equatable>(lhs: ArraySlice<T>, rhs: [T]) -> Bool { ((lhs.count == rhs.count) && (lhs == rhs[rhs.startIndex ..< rhs.endIndex])) }

public func == <T: Equatable>(lhs: [T], rhs: ArraySlice<T>) -> Bool { ((lhs.count == rhs.count) && (lhs[lhs.startIndex ..< lhs.endIndex] == rhs)) }

extension RangeReplaceableCollection {
    /*==========================================================================================================*/
    /// Pops the first element off the collection. If the collection is empty then returns `nil`.
    /// 
    /// - Returns: the first element off the collection or `nil` if the collection is empty.
    ///
    public mutating func popFirst() -> Self.Element? { (isEmpty ? nil : removeFirst()) }

    /*==========================================================================================================*/
    /// Works like `removeAll(where:)` except this version returns an array containing the elements that were
    /// removed.
    /// 
    /// - Parameter predicate: A closure that takes an element of the sequence as its argument and returns a
    ///                        Boolean value indicating whether the element should be removed from the collection.
    /// - Returns: An array containing the elements that were removed.
    /// - Throws: any error thrown by the predicate closure.
    ///
    public mutating func removeAllGet(where predicate: (Element) throws -> Bool) rethrows -> [Element] {
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
    /// - Returns: a new array.
    /// - Throws: any error thrown by the predicate closure.
    ///
    public func all(where predicate: (Element) throws -> Bool) rethrows -> [Element] {
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
    /// - Throws: any error thrown by the closure.
    ///
    public func isAny(predicate body: (Element) throws -> Bool) rethrows -> Bool {
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
    /// - Throws: any error thrown by the closure.
    ///
    public func areAll(predicate body: (Element) throws -> Bool) rethrows -> Bool {
        for e in self { guard try body(e) else { return false } }
        return true
    }
}

extension Array {
    public func last(count cc: Int) -> ArraySlice<Element> { self[index(endIndex, offsetBy: -Swift.min(cc, count)) ..< endIndex] }

    public func first(count cc: Int) -> ArraySlice<Element> { self[startIndex ..< index(startIndex, offsetBy: Swift.min(cc, count))] }
}

extension ArraySlice {
    public func last(count cc: Int) -> ArraySlice<Element> { self[index(endIndex, offsetBy: -Swift.min(cc, count)) ..< endIndex] }

    public func first(count cc: Int) -> ArraySlice<Element> { self[startIndex ..< index(startIndex, offsetBy: Swift.min(cc, count))] }
}
