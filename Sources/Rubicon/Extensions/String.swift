/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: String.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 3/19/20
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

extension String {
    /*==========================================================================================================*/
    /// Allows creating a <code>[String](https://developer.apple.com/documentation/swift/string/)</code> from the
    /// contents of an
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream)</code>.
    /// 
    /// - Parameters:
    ///   - inputStream: The input stream.
    ///   - encoding: The encoding. Defaults to
    ///               <code>[String.Encoding.utf8](https://developer.apple.com/documentation/swift/string/encoding/1780106-utf8)</code>
    ///
    public init?(inputStream: InputStream, encoding: String.Encoding = String.Encoding.utf8) {
        if inputStream.status(in: .notOpen) {
            inputStream.open()
        }
        if let data = Data(inputStream: inputStream) {
            self.init(data: data, encoding: encoding)
        }
        else {
            return nil
        }
    }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// for _ in (0 ..< count) { aString.append(char) }
    /// ```
    /// 
    /// - Parameters:
    ///   - char: The character to append to this string.
    ///   - count: The number of times to append the character.
    ///
    @inlinable mutating func append(_ char: Character, count: Int) { for _ in (0 ..< count) { append(char) } }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// for _ in (0 ..< count) { aString.insert(char, at: aString.startIndex) }
    /// ```
    /// 
    /// - Parameters:
    ///   - char: The character to prepend to the beginning of this string.
    ///   - count: The number of times to prepend the character.
    /// - Returns: The index of first character in the string BEFORE calling this method.
    ///
    @inlinable @discardableResult mutating func prepend(_ char: Character, count: Int = 1) -> String.Index {
        for _ in (0 ..< count) { insert(char, at: startIndex) }
        return (index(startIndex, offsetBy: count, limitedBy: endIndex) ?? endIndex)
    }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// aString.insert(contentsOf: aCollection, at: aString.startIndex)
    /// ```
    /// 
    /// - Parameter c: The collection of characters to prepend.
    /// - Returns: The index of first character in the string BEFORE calling this method.
    ///
    @inlinable @discardableResult mutating func prepend<C>(contentsOf c: C) -> String.Index where C: Collection, C.Element == Character {
        insert(contentsOf: c, at: startIndex)
        return (index(startIndex, offsetBy: c.count, limitedBy: endIndex) ?? endIndex)
    }
}
