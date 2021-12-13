/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/8/21
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

/*===========================================================================================================================================================================*/
/// Iterate through two collections simultaniously. Both collections must have the same number of elements.
///
/// - Parameters:
///   - c1: The first collection.
///   - c2: The second collection.
///   - body: The closure called for each element in both collections. If you want the iteration to stop then set the third parameter to true.
/// - Throws: Any error thrown by the closure.
///
public func syncIterate<T>(c1: T, c2: T, do body: (T.Element, T.Element, inout Bool) throws -> Void) rethrows where T: Collection, T.Index == Int {
    guard c1.count == c2.count else { fatalError("The collections to not have the same number of elements.") }
    var stop: Bool = false
    for i in (0 ..< c1.count) {
        try body(c1[i + c1.startIndex], c2[i + c2.startIndex], &stop)
        if stop { break }
    }
}

/*==============================================================================================================*/
/// Operator for appending new elements to an
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator <+: AssignmentPrecedence

/*==============================================================================================================*/
/// Operator for removing elements from an
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator >-: AssignmentPrecedence

/*==============================================================================================================*/
/// Operator for finding elements in an
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator <?: ComparisonPrecedence

/*==============================================================================================================*/
/// Append a new element to an <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
/// - Parameters:
///   - lhs: The <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>
///   - rhs: The new element
///
@inlinable public func <+ <T>(lhs: inout [T], rhs: T) { lhs.append(rhs) }

/*==============================================================================================================*/
/// Append the contents of the right-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> oprand to the left-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> oprand.
///
/// - Parameters:
///   - lhs: The receiving <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: The source <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
@inlinable public func <+ <T>(lhs: inout [T], rhs: [T]) { lhs.append(contentsOf: rhs) }

/*==============================================================================================================*/
/// Checks to see if the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> (left-hand
/// operand) contains the right-hand operand.
///
/// - Parameters:
///   - lhs: The <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: The object to search for in the
///          <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// - Returns: `true` if the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains
///            the object.
///
@inlinable public func <? <T: Equatable>(lhs: [T], rhs: T) -> Bool { lhs.contains { (obj: T) in rhs == obj } }

/*==============================================================================================================*/
/// Checks to see if the left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>
/// contains all of the elements in the right-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
/// - Parameters:
///   - lhs: The left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: The right-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// - Returns: `true` if the left-hand
///            <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains all of the
///            elements in the right-hand
///            <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
@inlinable public func <? <T: Equatable>(lhs: [T], rhs: [T]) -> Bool {
    for o: T in rhs { if !(lhs <? o) { return false } }
    return true
}
