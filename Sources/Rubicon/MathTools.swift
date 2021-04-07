/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: MathTools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/7/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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

precedencegroup PowerPrecedence {
    higherThan: MultiplicationPrecedence
}

infix operator ^^: PowerPrecedence
prefix operator ~~
prefix operator ++
prefix operator --
postfix operator ++
postfix operator --
prefix operator +++
prefix operator ---
postfix operator +++
postfix operator ---

/*===============================================================================================================================================================================*/
/// Returns the two's compliment of the integer value.
/// 
/// - Parameter n: the integer value.
/// - Returns: the two's compliment.
///
public prefix func ~~ <T: FixedWidthInteger>(_ n: T) -> T {
    (~(n - 1))
}

/*===============================================================================================================================================================================*/
/// Raise a `base` number to a `power`. This is often written as base<sup><smaller>power</smaller></sup>. Throws a fatal error if `power` is negative (less than
/// <code>[zero](https://en.wikipedia.org/wiki/0)</code>).
/// 
/// For example 2<sup><smaller>7</smaller></sup> is:
/// ```
/// 2 ^^ 7 = 128
/// ```
/// 
/// - Parameters:
///   - base: the base number.
///   - power: the power.
/// - Returns: the base number raised to the power.
///
public func ^^ <T: BinaryInteger>(base: T, power: T) -> T {
    guard power >= 0 else {
        fatalError("Cannot raise a base number to a negative power.")
    }

    func expBySq(_ y: T, _ x: T, _ n: T) -> T {
        ((n == 0) ? y : ((n == 1) ? y * x : (n.isMultiple(of: 2) ? expBySq(y, x * x, n / 2) : expBySq(y * x, x * x, (n - 1) / 2))))
    }

    return expBySq(1, base, power)
}

/*===============================================================================================================================================================================*/
/// Implements the `++` prefix operator as found in C, C++, Objective-C, Java, and many other languages.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` AFTER incrementing it's value by 1.
///
@discardableResult public prefix func ++ <T: BinaryInteger>(operand: inout T) -> T {
    operand += 1
    return operand
}

/*===============================================================================================================================================================================*/
/// Implements the `--` prefix operator as found in C, C++, Objective-C, Java, and many other languages.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` AFTER decrementing it's value by 1.
///
@discardableResult public prefix func -- <T: BinaryInteger>(operand: inout T) -> T {
    operand -= 1
    return operand
}

/*===============================================================================================================================================================================*/
/// Implements the `++` postfix operator as found in C, C++, Objective-C, Java, and many other languages.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` BEFORE incrementing it's value by 1.
///
@discardableResult public postfix func ++ <T: BinaryInteger>(operand: inout T) -> T {
    let i: T = operand
    operand += 1
    return i
}

/*===============================================================================================================================================================================*/
/// Implements the `--` postfix operator as found in C, C++, Objective-C, Java, and many other languages.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` BEFORE decrementing it's value by 1.
///
@discardableResult public postfix func -- <T: BinaryInteger>(operand: inout T) -> T {
    let i: T = operand
    operand -= 1
    return i
}

/*===============================================================================================================================================================================*/
/// Implements the `++` prefix operator as found in C, C++, Objective-C, Java, and many other languages. This function allows overflow.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` AFTER incrementing it's value by 1.
///
@discardableResult public prefix func +++ <T: FixedWidthInteger>(operand: inout T) -> T {
    operand = (operand &+ 1)
    return operand
}

/*===============================================================================================================================================================================*/
/// Implements the `--` prefix operator as found in C, C++, Objective-C, Java, and many other languages. This function allows underflow.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` AFTER decrementing it's value by 1.
///
@discardableResult public prefix func --- <T: FixedWidthInteger>(operand: inout T) -> T {
    operand = (operand &- 1)
    return operand
}

/*===============================================================================================================================================================================*/
/// Implements the `++` postfix operator as found in C, C++, Objective-C, Java, and many other languages. This function allows overflow.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` BEFORE incrementing it's value by 1.
///
@discardableResult public postfix func +++ <T: FixedWidthInteger>(operand: inout T) -> T {
    let i: T = operand
    operand = (operand &+ 1)
    return i
}

/*===============================================================================================================================================================================*/
/// Implements the `--` postfix operator as found in C, C++, Objective-C, Java, and many other languages. This function allows underflow.
/// 
/// - Parameter operand: the integer variable.
/// - Returns: the value of the `operand` BEFORE decrementing it's value by 1.
///
@discardableResult public postfix func --- <T: FixedWidthInteger>(operand: inout T) -> T {
    let i: T = operand
    operand = (operand &- 1)
    return i
}
