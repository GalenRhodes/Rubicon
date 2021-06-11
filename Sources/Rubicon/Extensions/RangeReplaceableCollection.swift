/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: RangeReplaceableCollection.swift
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

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// for _ in (0 ..< count) { aCollection.append(e) }
    /// ```
    /// 
    /// - Parameters:
    ///   - e: The element to append to this collection.
    ///   - count: The number of times to append the element.
    ///
    @inlinable public mutating func append(_ e: Element, count: Int) { for _ in (0 ..< count) { append(e) } }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// for _ in (0 ..< count) { aCollection.insert(e, at: aCollection.startIndex) }
    /// ```
    /// 
    /// - Parameters:
    ///   - e: The element to prepend to the beginning of this collection.
    ///   - count: The number of times to prepend the element.
    /// - Returns: The index of first element in this collection BEFORE calling this method.
    ///
    @inlinable public mutating func prepend(_ e: Element, count: Int = 1) -> Index {
        for _ in (0 ..< count) { insert(e, at: startIndex) }
        return (index(startIndex, offsetBy: count, limitedBy: endIndex) ?? endIndex)
    }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// aCollection.insert(contentsOf: anotherCollection, at: aCollection.startIndex)
    /// ```
    /// 
    /// - Parameter c: The collection of elements to prepend.
    /// - Returns: The index of first element in this collection BEFORE calling this method.
    ///
    @inlinable public mutating func prepend<C>(contentsOf c: C) -> Index where C: Collection, C.Element == Element {
        insert(contentsOf: c, at: startIndex)
        return (index(startIndex, offsetBy: c.count, limitedBy: endIndex) ?? endIndex)
    }
}
