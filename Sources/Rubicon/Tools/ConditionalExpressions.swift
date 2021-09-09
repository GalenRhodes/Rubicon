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

/*==============================================================================================================*/
/// <code>[Optional](https://developer.apple.com/documentation/swift/optional/)</code> conditional. To test an
/// optional for `nil` you can use an `if` statement like this:
/// ```
///     if let v = possiblyNil {
///         /* do something with v */
///     }
///     else {
///         /* do something when possiblyNil is 'nil' */
///     }
/// ```
///
/// This is fine but I wanted to do the same thing with a conditional expression like you can in C/C++/Objective-C:
/// ```
///     let x = (let v = possiblyNil ? v.name : "no name") // This will not compile. 😩
/// ```
///
/// I know I could always do this:
/// ```
///     let x = ((possiblyNil == nil) ? "no name" : v!.name) // This will compile.
/// ```
/// But the OCD side of me really dislikes that '!' being there even though I know it will never cause a fatal
/// error. It just rubs up against that nerve seeing it there. 🤢
///
/// So I created this function to simulate the functionality of the above using closures.
///
/// ```
///     let x = when(possiblyNil, isNil: "No Name") { $0.name } // This will compile. 😁
/// ```
///
/// - Parameters:
///   - expression: The expression to test for `nil`.
///   - c1: The closure to execute if `obj` IS `nil`.
///   - c2: The closure to execute if `obj` is NOT `nil`. The unwrapped value of `obj` is passed to the closure.
/// - Returns: The value returned from whichever closure is executed.
/// - Throws: Any exception thrown by whichever closure is executed.
///
@inlinable public func when<R, T>(_ expression: T?, isNil c1: @autoclosure () throws -> R, notNil c2: (T) throws -> R) rethrows -> R {
    guard let x = expression else { return try c1() }
    return try c2(x)
}
