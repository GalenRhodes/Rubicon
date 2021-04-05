/*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 3/30/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*============================================================================================================================================================================*/

import Foundation
import CoreFoundation

public let UnicodeReplacementChar: Character = "�"

public protocol SimpleCharInputStream: CharStream {
    /*===========================================================================================================================================================================*/
    /// `true` if the stream is at the end-of-file.
    ///
    var isEOF:             Bool { get }

    /*===========================================================================================================================================================================*/
    /// `true` if the stream has characters ready to be read.
    ///
    var hasCharsAvailable: Bool { get }

    /*===========================================================================================================================================================================*/
    /// Read one character.
    /// 
    /// - Returns: the next character or `nil` if EOF.
    /// - Throws: if an I/O error occurs.
    ///
    func read() throws -> Character?

    /*===========================================================================================================================================================================*/
    /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the stream.
    /// 
    /// - Parameters:
    ///   - chars: the <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive the
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s. This array will be cleared before the new characters are added to it.
    ///   - maxLength: the maximum number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to receive. If -1 then all
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s are read until the end-of-file.
    /// - Returns: the number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will return 0
    ///            (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at end-of-file.
    /// - Throws: if an I/O error occurs.
    ///
    func read(chars: inout [Character], maxLength: Int) throws -> Int

    /*===========================================================================================================================================================================*/
    /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the stream and append them to the given character array. This method is
    /// identical to `read(chars:,maxLength:)` except that the receiving array is not cleared before the data is read.
    /// 
    /// - Parameters:
    ///   - chars: the <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive the
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
    ///   - maxLength: the maximum number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to receive. If -1 then all
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s are read until the end-of-file.
    /// - Returns: the number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will return 0
    ///            (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at end-of-file.
    /// - Throws: if an I/O error occurs.
    ///
    func append(to chars: inout [Character], maxLength len: Int) throws -> Int
}

extension SimpleCharInputStream {
    /*===========================================================================================================================================================================*/
    /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the stream and append them to the given character array. This method is
    /// identical to `read(chars:,maxLength:)` except that the receiving array is not cleared before the data is read.
    /// 
    /// - Parameters:
    ///   - chars: the <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive the
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
    ///   - maxLength: the maximum number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to receive. If -1 then all
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s are read until the end-of-file.
    /// - Returns: the number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will return 0
    ///            (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at end-of-file.
    /// - Throws: if an I/O error occurs.
    ///
    @inlinable public func append(to chars: inout [Character], maxLength len: Int = -1) throws -> Int {
        var newChars = [ Character ]()
        let cc       = try read(chars: &newChars, maxLength: ((len < 0) ? Int.max : len))
        if cc > 0 { chars.append(contentsOf: newChars) }
        return cc
    }
}
