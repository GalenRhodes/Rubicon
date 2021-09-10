/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Tools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/30/20
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
import CoreFoundation
#if os(Windows)
    import WinSDK
#endif

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

/*==============================================================================================================*/
/// If the `maxLength` is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then return the largest
/// integer possible (<code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>)
/// otherwise returns the value of `maxLength`.
/// 
/// - Parameter maxLength: the length to fix.
/// - Returns: Either the value of `maxLength` or
///            <code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>.
///
@inlinable public func fixLength(_ maxLength: Int) -> Int { ((maxLength < 0) ? Int.max : maxLength) }

/*==============================================================================================================*/
/// Tests one value to see if it is one of the listed values. Instead of doing this:
/// ```
///     if number == 1 || number == 5 || number == 99 { /* do something */ }
/// ```
/// 
/// You can now do this:
/// ```
///     if `value(number, isOneOf: 1, 5, 99)` { /* do something */ }
/// ```
/// 
/// - Parameters:
///   - value: The value to be tested.
///   - isOneOf: The desired values.
/// - Returns: `true` of the value is one of the desired values.
///
@inlinable public func value<T: Equatable>(_ value: T, isOneOf: T...) -> Bool { isOneOf.isAny { value == $0 } }

@inlinable public func value<T: Equatable>(_ value: T, isOneOf: [T]) -> Bool { isOneOf.isAny { value == $0 } }

/*==============================================================================================================*/
/// Calculate the number of instances of a given datatype will occupy a given number of bytes. For example, if
/// given a type of `Int64.self` and a byte count of 16 then this function will return a value of 2.
/// 
/// - Parameters:
///   - type: The target datatype.
///   - value: The number of bytes.
/// - Returns: The number of instances of the datatype that can occupy the given number of bytes.
///
@inlinable public func fromBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<UInt8>.stride) / MemoryLayout<T>.stride) }

/*==============================================================================================================*/
/// Calculate the number of bytes that make up a given number of instances of the given datatype. For example if
/// given a datatype of `Int64.self` and a count of 2 then this function will return 16.
/// 
/// - Parameters:
///   - type: The target datatype.
///   - value: The number of instances of the datatype.
/// - Returns: The number of bytes that make up that many instances of that datatype.
///
@inlinable public func toBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<T>.stride) / MemoryLayout<UInt8>.stride) }

/*==============================================================================================================*/
/// Get a hash value from just about anything.
/// 
/// - Parameter v: The item you want the hash of.
/// - Returns: The hash.
///
@inlinable public func HashOfAnything(_ v: Any) -> Int {
    if let x = (v as? AnyHashable) { return x.hashValue }
    else { return ObjectIdentifier(v as AnyObject).hashValue }
}

/*==============================================================================================================*/
/// Somewhat shorthand for:
/// ```
/// type(of: o) == t.self
/// ```
/// 
/// - Parameters:
///   - o: The instance to check the type of.
///   - t: The type to check for.
/// - Returns: `true` if the type of `o` is equal to `t`.
///
@inlinable public func isType<O, T>(_ o: O, _ t: T.Type) -> Bool { (type(of: o) == t) }
