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

extension Array {
    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// anArray[anArray.index(anArray.endIndex, offsetBy: -Swift.min(cc, anArray.count)) ..< anArray.endIndex]
    /// ```
    /// 
    /// - Parameter cc: The number of elements to get.
    /// - Returns: An array slice of the last `cc` elements.
    ///
    @inlinable public func last(count cc: Int) -> ArraySlice<Element> { self[index(endIndex, offsetBy: -Swift.min(cc, count)) ..< endIndex] }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// anArray[anArray.startIndex ..< anArray.index(anArray.startIndex, offsetBy: Swift.min(cc, anArray.count))]
    /// ```
    /// 
    /// - Parameter cc: The number of elements to get.
    /// - Returns: An array slice of the first `cc` elements.
    ///
    @inlinable public func first(count cc: Int) -> ArraySlice<Element> { self[startIndex ..< index(startIndex, offsetBy: Swift.min(cc, count))] }
}
extension Array where Element == Character {
    /*==========================================================================================================*/
    /// Allows for easy equality check between Strings and Character Arrays. Instead of having to write:
    /// 
    /// ```
    /// let array: [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The Character Array.
    ///   - rhs: The String
    /// - Returns: `true` if the array contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: Self, rhs: String) -> Bool { (String(lhs) == rhs) }

    /*==========================================================================================================*/
    /// Allows for easy inequality check between Strings and Character Arrays. Instead of having to write:
    /// 
    /// ```
    /// let array: [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if String(array) != string { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if array != string { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The Character Array.
    ///   - rhs: The String
    /// - Returns: `true` if the array does not contain the same characters, in the same order, as the string.
    ///
    @inlinable public static func != (lhs: Self, rhs: String) -> Bool { (String(lhs) != rhs) }

    /*==========================================================================================================*/
    /// Allows for easy equality check between Strings and Character Arrays. Instead of having to write:
    /// 
    /// ```
    /// let array: [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The String
    ///   - rhs: The Character Array.
    /// - Returns: `true` if the array contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: String, rhs: Self) -> Bool { (lhs == String(rhs)) }

    /*==========================================================================================================*/
    /// Allows for easy inequality check between Strings and Character Arrays. Instead of having to write:
    /// 
    /// ```
    /// let array: [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if String(array) != string { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array:  [Character] = [ "G", "a", "l", "e", "n" ]
    /// let string: String      = "Galen"
    /// if array != string { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The String
    ///   - rhs: The Character Array.
    /// - Returns: `true` if the array does not contain the same characters, in the same order, as the string.
    ///
    @inlinable public static func != (lhs: String, rhs: Self) -> Bool { (lhs != String(rhs)) }
}
