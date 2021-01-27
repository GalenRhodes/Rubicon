/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: CharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 8/9/20
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

public let UnicodeReplacementChar: Character = "�"

public protocol CharInputStream: CharStream {

    /*===========================================================================================================================================================================*/
    /// `true` if the stream is at the end-of-file.
    ///
    var isEOF:             Bool { get }

    /*===========================================================================================================================================================================*/
    /// `true` if the stream has characters ready to be read.
    ///
    var hasCharsAvailable: Bool { get }

    /*===========================================================================================================================================================================*/
    /// The error.
    ///
    var streamError:       Error? { get }

    /*===========================================================================================================================================================================*/
    /// The current line number.
    ///
    var lineNumber:        Int { get }

    /*===========================================================================================================================================================================*/
    /// The current column number.
    ///
    var columnNumber:      Int { get }

    /*===========================================================================================================================================================================*/
    /// The number of spaces in each tab stop.
    ///
    var tabWidth:          Int { get set }

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
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
    ///   - maxLength: the maximum number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to receive. If -1 then all
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s are read until the end-of-file.
    /// - Returns: the number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will return 0
    ///            (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at end-of-file.
    /// - Throws: if an I/O error occurs.
    ///
    func read(chars: inout [Character], maxLength: Int) throws -> Int

    /*===========================================================================================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark but all operations happen on the most recently set mark.
    ///
    func markSet()

    /*===========================================================================================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    func markReturn()

    /*===========================================================================================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    func markDelete()

    /*===========================================================================================================================================================================*/
    /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markReturn()` followed immediately by a `markSet()`.
    ///
    func markReset()

    /*===========================================================================================================================================================================*/
    /// Updates the most recently set mark to the current position. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markDelete()` followed immediately by a `markSet()`.
    ///
    func markUpdate()

    func markBackup(count: Int) -> Int
}

public extension CharInputStream {

    /*===========================================================================================================================================================================*/
    /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the stream.
    /// 
    /// - Parameters:
    ///   - chars: the <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive the
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
    /// - Returns: the number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will return 0
    ///            (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at end-of-file.
    /// - Throws: if an I/O error occurs.
    ///
    @inlinable func read(chars: inout [Character]) throws -> Int {
        try read(chars: &chars, maxLength: -1)
    }

    @inlinable func append(to chars: inout [Character], maxLength len: Int = -1) throws -> Int {
        var newChars: [Character] = []
        let cc                    = try read(chars: &newChars, maxLength: len)
        if cc > 0 { chars.append(contentsOf: newChars) }
        return cc
    }
}
