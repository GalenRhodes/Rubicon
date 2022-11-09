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
@discardableResult public func whenNotNil<T, R>(_ value: T?, _ notNilAction: (T) throws -> R, else nilAction: () throws -> R) rethrows -> R {
    guard let value = value else { return try nilAction() }
    return try notNilAction(value)
}

public func isValue<T>(_ value: T, in values: T...) -> Bool where T: Equatable {
    for v in values { if v == value { return true } }
    return false
}

public func isValue<T>(_ value: T, in values: T...) -> Bool where T: AnyObject {
    for o in values { if o === value { return true } }
    return false
}
