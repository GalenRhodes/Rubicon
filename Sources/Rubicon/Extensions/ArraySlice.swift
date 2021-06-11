/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: ArraySlice.swift
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

extension ArraySlice {
    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// aSlice[aSlice.index(aSlice.endIndex, offsetBy: -Swift.min(cc, aSlice.count)) ..< aSlice.endIndex]
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
    /// aSlice[aSlice.startIndex ..< aSlice.index(aSlice.startIndex, offsetBy: Swift.min(cc, aSlice.count))]
    /// ```
    /// 
    /// - Parameter cc: The number of elements to get.
    /// - Returns: An array slice of the first `cc` elements.
    ///
    @inlinable public func first(count cc: Int) -> ArraySlice<Element> { self[startIndex ..< index(startIndex, offsetBy: Swift.min(cc, count))] }
}

extension ArraySlice where Element: Equatable {
    /*==========================================================================================================*/
    /// Convienience method to allow direct comparison of Arrays and ArraySlices for equality. Instead of having
    /// to write:
    /// 
    /// ```
    /// if aSlice == anArray[anArray.startIndex ..< anArray.endIndex] { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// if aSlice == anArray { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: an instance of ArraySlice
    ///   - rhs: an instance of Array
    /// - Returns: `true` if the ArraySlice and the Array have the same elements in the same order.
    ///
    @inlinable public static func == (lhs: Self, rhs: [Element]) -> Bool { (lhs == rhs[rhs.indexRange]) }

    /*==========================================================================================================*/
    /// Convienience method to allow direct comparison of Arrays and ArraySlices for equality. Instead of having
    /// to write:
    /// 
    /// ```
    /// if anArray[anArray.startIndex ..< anArray.endIndex] == aSlice { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// if anArray == aSlice { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: an instance of Array
    ///   - rhs: an instance of ArraySlice
    /// - Returns: `true` if the ArraySlice and the Array have the same elements in the same order.
    ///
    @inlinable public static func == (lhs: [Element], rhs: Self) -> Bool { (lhs[lhs.indexRange] == rhs) }

    /*==========================================================================================================*/
    /// Convienience method to allow direct comparison of Arrays and ArraySlices for inequality. Instead of having
    /// to write:
    /// 
    /// ```
    /// if aSlice != anArray[anArray.startIndex ..< anArray.endIndex] { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// if aSlice != anArray { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: an instance of ArraySlice
    ///   - rhs: an instance of Array
    /// - Returns: `true` if the ArraySlice and the Array do not have the same elements in the same order.
    ///
    @inlinable public static func != (lhs: Self, rhs: [Element]) -> Bool { !(lhs == rhs) }

    /*==========================================================================================================*/
    /// Convienience method to allow direct comparison of Arrays and ArraySlices for inequality. Instead of having
    /// to write:
    /// 
    /// ```
    /// if anArray[anArray.startIndex ..< anArray.endIndex] != aSlice { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// if anArray != aSlice { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: an instance of Array
    ///   - rhs: an instance of ArraySlice
    /// - Returns: `true` if the ArraySlice and the Array do not have the same elements in the same order.
    ///
    @inlinable public static func != (lhs: [Element], rhs: Self) -> Bool { !(lhs == rhs) }
}

extension ArraySlice where Element == Character {
    /*==========================================================================================================*/
    /// Allows for easy equality check between Strings and Character ArraySlices. Instead of having to write:
    /// 
    /// ```
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The Character ArraySlice.
    ///   - rhs: The String
    /// - Returns: `true` if the array slice contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: Self, rhs: String) -> Bool { (String(lhs) == rhs) }

    /*==========================================================================================================*/
    /// Allows for easy inequality check between Strings and Character ArraySlices. Instead of having to write:
    /// 
    /// ```
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if string != String(array) { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array:  ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String                = "Galen"
    /// if string != array { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The Character ArraySlice.
    ///   - rhs: The String
    /// - Returns: `true` if the array slice does not contain the same characters, in the same order, as the
    ///            string.
    ///
    @inlinable public static func != (lhs: Self, rhs: String) -> Bool { (String(lhs) != rhs) }

    /*==========================================================================================================*/
    /// Allows for easy equality check between Strings and Character ArraySlices. Instead of having to write:
    /// 
    /// ```
    /// let array: ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if String(array) == string { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array: ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if array == string { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The String
    ///   - rhs: The Character ArraySlice.
    /// - Returns: `true` if the array slice contains the same characters, in the same order, as the string.
    ///
    @inlinable public static func == (lhs: String, rhs: Self) -> Bool { (lhs == String(rhs)) }

    /*==========================================================================================================*/
    /// Allows for easy inequality check between Strings and Character ArraySlices. Instead of having to write:
    /// 
    /// ```
    /// let array: ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if string != String(array) { /* do something */ }
    /// ```
    /// You can now just write:
    /// 
    /// ```
    /// let array: ArraySlice<Character> = [ "G", "a", "l", "e", "n" ]
    /// let string: String = "Galen"
    /// if string != array { /* do something */ }
    /// ```
    /// 
    /// - Parameters:
    ///   - lhs: The Character ArraySlice.
    ///   - rhs: The String
    /// - Returns: `true` if the array slice does not contain the same characters, in the same order, as the
    ///            string.
    ///
    @inlinable public static func != (lhs: String, rhs: Self) -> Bool { (lhs != String(rhs)) }
}
