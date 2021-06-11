/*
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
 *//*============================================================================================================================================================================*/

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
}
