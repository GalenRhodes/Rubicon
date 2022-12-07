// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Functions.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: July 09, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation

/*-------------------------------------------------------------------------------------------------------------------------*/
/// Simpler handling of taking one of two actions depending on if the given value is `nil` or not `nil`.
///
/// - Parameters:
///   - value:        The value to test for `nil`.
///   - notNilAction: The closure to execute if the value is NOT `nil`. This closure takes the non-`nil` value as it's only parameter.
///   - nilAction:    The closure to execute if the value IS `nil`. This closure takes no parameters.
/// - Returns: The value returned by the closure that was executed.
/// - Throws:  Any error thrown by the closure that was executed.
///
@discardableResult @inlinable public func whenNotNil<T, R>(_ value: T?, _ notNilAction: (T) throws -> R, else nilAction: () throws -> R) rethrows -> R {
    guard let value = value else { return try nilAction() }
    return try notNilAction(value)
}

/*-------------------------------------------------------------------------------------------------------------------------*/
/// Tests if the given `value` is equal to and of the values in the list `values`.
///
/// - Parameters:
///   - value: The `value` to test for equality.
///   - values: The list of `values` to test `value` against for equality.
/// - Returns: `true` if any of the `values` is equal to the given `value`.  Otherwise, `false`.
///
@inlinable public func isValue<T>(_ value: T, in values: T...) -> Bool where T: Equatable {
    for v in values { if v == value { return true } }
    return false
}

/*-------------------------------------------------------------------------------------------------------------------------*/
/// Tests if the given `object` is the exact same as one of the `objects` in the list. This function tests for identity
/// `===` rather than equality `==`.  In other words, are the two values occupying the exact same location in memory.
///
/// - Parameters:
///   - object: The `object` to test.
///   - objects: The list of `objects` to test `object` against.
/// - Returns: `true` if any of the `objects` is the same as `object`.  Otherwise, `false`.
///
@inlinable public func isObject<T>(_ object: T, in objects: T...) -> Bool where T: AnyObject {
    for o in objects { if o === object { return true } }
    return false
}

/*==============================================================================================================*/
/// Get a hash value from just about anything.
///
/// - Parameter v: The item you want the hash of.
/// - Returns: The hash.
///
@inlinable public func HashOfAnything(_ v: Any) -> Int {
    if let x = (v as? AnyHashable) { return x.hashValue }
    return ObjectIdentifier(v as AnyObject).hashValue
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
