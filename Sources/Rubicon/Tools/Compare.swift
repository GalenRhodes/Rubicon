/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: Compare.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/10/21
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

/*==============================================================================================================*/
/// Less-than comparison function that allows for nil values. In this case a nil value will always be less-than
/// a non-nil value.
///
/// - Parameters:
///   - l: The left-hand operand.
///   - r: The right-hand operand.
/// - Returns: true if the right-hand operand is not nil and the left-hand operand is nil or less-than the
///            right-hand operand.
///
@inlinable public func < <T>(l: T?, r: T?) -> Bool where T: Comparable {
    ((r != nil) && ((l == nil) || (l! < r!)))
}

/*==============================================================================================================*/
/// Less-than-or-equal comparison function that allows for nil values. In this case a nil value will always be
/// less-than a non-nil value.
///
/// - Parameters:
///   - l: The left-hand operand.
///   - r: The right-hand operand.
/// - Returns: true if both operands are nil or the right-hand operand is not nil and the left-hand operand is
///            nil or less-than-or-equal to the right-hand operand.
///
@inlinable public func <= <T>(l: T?, r: T?) -> Bool where T: Comparable {
    ((l == r) || (l < r))
}

/*==============================================================================================================*/
/// Greater-than comparison function that allows for nil values. In this case a non-nil value will always be
/// greater-than a nil value.
///
/// - Parameters:
///   - l: The left-hand operand.
///   - r: The right-hand operand.
/// - Returns: true if the left-hand operand is not nil and the right-hand operand is nil or greater-than the
///            left-hand operand.
///
@inlinable public func > <T>(l: T?, r: T?) -> Bool where T: Comparable {
    ((l != nil) && ((r == nil) || (l! > r!)))
}

/*==============================================================================================================*/
/// Greater-than-or-equal comparison function that allows for nil values. In this case a non-nil value will
/// always be greater-than a nil value.
///
/// - Parameters:
///   - l: The left-hand operand.
///   - r: The right-hand operand.
/// - Returns: true if both operands are nil or the left-hand operand is not nil and the right-hand operand is
///            nil or greater-than-or-equal to the left-hand operand.
///
@inlinable public func >= <T>(l: T?, r: T?) -> Bool where T: Comparable {
    ((l == r) || (l > r))
}

/*==============================================================================================================*/
/// Values that indicate should be sorted against another object.
///
public enum SortOrdering: Int {
    /*==========================================================================================================*/
    /// One object comes before another object.
    ///
    case LessThan    = -1
    /*==========================================================================================================*/
    /// One object holds the same place as another object.
    ///
    case EqualTo     = 0
    /*==========================================================================================================*/
    /// One object comes after another object.
    ///
    case GreaterThan = 1
}

/*==============================================================================================================*/
/// A new operator for comparing two objects.
///
infix operator <=>: ComparisonPrecedence

/*==============================================================================================================*/
/// Compares two objects to see what their `SortOrdering` is. Both objects have to conform to the
/// [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol.
///
/// Usage:
/// ```
///     func `foo(str1: String, str2: String)` { switch str1 <=> str2 { case .LessThan: `print("'\(str1)`' comes
///     before '\(str2)'") case .EqualTo: `print("'\(str1)`' is the same as '\(str2)'") case .GreaterThan:
///     `print("'\(str1)`' comes after '\(str2)'") } }
/// ```
///
/// - Parameters:
///   - l: The left hand operand
///   - r: The right hand operand
///
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand
///            operand should be sorted before, at the same place as, or after the right-hand operand.
///
@inlinable public func <=> <T: Comparable>(l: T?, r: T?) -> SortOrdering {
    (l == nil ? (r == nil ? .EqualTo : .LessThan) : (r == nil ? .GreaterThan : (l! < r! ? .LessThan : (l! > r! ? .GreaterThan : .EqualTo))))
}

/*==============================================================================================================*/
/// Compares two arrays to see what their `SortOrdering` is. The objects of both arrays have to conform to the
/// [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol. This method first compares the number
/// of objects in each array. If they are not the same then the function will return `SortOrdering.Before` or
/// `SortOrdering.After` as the left-hand array has fewer or more objects than the right-hand array. If the both
/// hold the same number of objects then the function compares each object in the left-hand array to the object in
/// the same position in the right-hand array. In other words it compares `leftArray[0]` to `rightArray[0]`,
/// `leftArray[1]` to `rightArray[1]` and so on until it finds the first pair of objects that do not of the same
/// sort ordering and returns ordering. If all the objects in the same positions in both arrays are
/// `SortOrdering.Same` then this function returns `SortOrdering.Same`.
///
/// Example:
/// ```
///     let array1: [Int] = [ 1, 2, 3, 4 ] let array2: [Int] = [ 1, 2, 3, 4 ] let array3: [Int] = [ 1, 2, 3 ] let
///     array4: [Int] = [ 1, 2, 5, 6 ]
///
///     let result1: SortOrdering = array1 <=> array2 // result1 is set to `SortOrdering.EqualTo` let result2:
///     SortOrdering = array1 <=> array3 // result2 is set to `SortOrdering.GreaterThan` let result3: SortOrdering
///     = array1 <=> array4 // result3 is set to `SortOrdering.LessThan`
/// ```
///
/// - Parameters:
///   - l: The left hand array operand
///   - r: The right hand array operand
///
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand array
///            comes before, in the same place as, or after the right-hand array.
///
@inlinable public func <=> <T: Comparable>(l: [T?], r: [T?]) -> SortOrdering {
    var cc: SortOrdering = (l.count <=> r.count)

    if cc == .EqualTo {
        for i: Int in (0 ..< l.count) {
            cc = (l[i] <=> r[i])
            guard cc == .EqualTo else { break }
        }
    }

    return cc
}

