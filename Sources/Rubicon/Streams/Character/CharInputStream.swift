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
import CoreFoundation

public typealias TextPosition = (lineNumber: Int32, columnNumber: Int32)

public protocol CharInputStream: SimpleCharInputStream {

    /*==========================================================================================================*/
    /// The number of marks on the stream.
    ///
    var markCount: Int { get }

    /*==========================================================================================================*/
    /// The current line and column numbers.
    ///
    var position:  TextPosition { get }

    /*==========================================================================================================*/
    /// The number of spaces in each tab stop.
    ///
    var tabWidth:  Int8 { get set }

    /*==========================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark
    /// but all operations happen on the most recently set mark.
    ///
    func markSet()

    /*==========================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    func markReturn()

    /*==========================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    func markDelete()

    /*==========================================================================================================*/
    /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a new
    /// one is created. This is functionally equivalent to performing a `markReturn()` followed immediately by a
    /// `markSet()`.
    ///
    func markReset()

    /*==========================================================================================================*/
    /// Updates the most recently set mark to the current position. If there was no previously set mark then a new
    /// one is created. This is functionally equivalent to performing a `markDelete()` followed immediately by a
    /// `markSet()`.
    ///
    func markUpdate()

    /*==========================================================================================================*/
    /// Backs out the last `count` characters from the most recently set mark without actually removing the entire
    /// mark. You have to have previously called `markSet()` otherwise this method does nothing.
    /// 
    /// - Parameter count: the number of characters to back out.
    /// - Returns: The number of characters actually backed out in case there weren't `count` characters available.
    ///
    @discardableResult func markBackup(count: Int) -> Int
}

extension CharInputStream {
    @discardableResult public func markBackup() -> Int { markBackup(count: 1) }
}
