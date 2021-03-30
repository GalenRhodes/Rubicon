/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: IConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/1/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
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
#if os(Linux)
    import iconv
#endif

open class IConvCharInputStream: SimpleIConvCharInputStream, CharInputStream {
    // @f:0
    /*===========================================================================================================================================================================*/
    /// The current line number.
    ///
    @inlinable open var lineNumber:                 Int           { lock.withLock { line                                          } }
    /*===========================================================================================================================================================================*/
    /// The current column number.
    ///
    @inlinable open var columnNumber:               Int           { lock.withLock { column                                        } }
    /*===========================================================================================================================================================================*/
    /// The number of marks on the stream.
    ///
    @inlinable open var markCount:                  Int           { lock.withLock { markStack.count                               } }

    /*===========================================================================================================================================================================*/
    /// `true` if the stream has characters ready to be read.
    ///
    @inlinable open override var hasCharsAvailable: Bool          { lock.withLock { (hasChars || !xbuffer.isEmpty) } }
    // @f:1

    /*===========================================================================================================================================================================*/
    /// The number of spaces in each tab stop.
    ///
    open var tabWidth: Int = 4

    /*===========================================================================================================================================================================*/
    /// The current line number.
    ///
    @usableFromInline      var line:      Int           = 1
    /*===========================================================================================================================================================================*/
    /// The current column number.
    ///
    @usableFromInline      var column:    Int           = 1
    /*===========================================================================================================================================================================*/
    /// The mark stack.
    ///
    @usableFromInline      var markStack: [MarkItem]    = []
    /*===========================================================================================================================================================================*/
    /// The character buffer to hold restored characters.
    ///
    @usableFromInline      var xbuffer:   [Character]   = []

    /*===========================================================================================================================================================================*/
    /// Create a new instance of this character input stream from an existing byte input stream.
    /// 
    /// - Parameters:
    ///   - inputStream: the underlying byte input stream.
    ///   - encodingName: the name of the incoming character encoding.
    ///   - autoClose: if `true` then the underlying input stream will be closed when this stream is closed or destroyed.
    ///
    public override init(inputStream: InputStream, encodingName: String, autoClose: Bool) { super.init(inputStream: inputStream, encodingName: encodingName, autoClose: autoClose) }

    /*===========================================================================================================================================================================*/
    /// Read one character.
    /// 
    /// - Returns: the next character or `nil` if EOF.
    /// - Throws: if an I/O error occurs.
    ///
    @inlinable open override func read() throws -> Character? {
        try lock.withLock {
            if let ch = try __read() {
                if let mi = markStack.last { (line, column) = mi.add(line, column, tabWidth, ch) }
                else { (line, column) = textPositionUpdate(ch, position: (line, column), tabSize: tabWidth) }
                return ch
            }
            return nil
        }
    }

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
    @inlinable open override func read(chars: inout [Character], maxLength: Int) throws -> Int {
        try lock.withLock {
            let cc = try _read(chars: &chars, maxLength: maxLength)
            if cc > 0 {
                if let mi = markStack.last { for ch in chars { (line, column) = mi.add(line, column, tabWidth, ch) } }
                else { for ch in chars { (line, column) = textPositionUpdate(ch, position: (line, column), tabSize: tabWidth) } }
            }
            return cc
        }
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark but all operations happen on the most recently set mark.
    ///
    @inlinable open func markSet() { lock.withLock { markStack <+ MarkItem() } }

    /*===========================================================================================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    @inlinable open func markReturn() { lock.withLock { _markReturn() } }

    /*===========================================================================================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    @inlinable open func markDelete() { lock.withLock { _ = markStack.popLast() } }

    /*===========================================================================================================================================================================*/
    /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markReturn()` followed immediately by a `markSet()`.
    ///
    @inlinable open func markReset() { lock.withLock { _markReturn(); markStack <+ MarkItem() } }

    /*===========================================================================================================================================================================*/
    /// Updates the most recently set mark to the current position. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markDelete()` followed immediately by a `markSet()`.
    ///
    @inlinable open func markUpdate() { lock.withLock { _ = markStack.popLast(); markStack <+ MarkItem() } }

    /*===========================================================================================================================================================================*/
    /// Backs out the last `count` characters from the most recently set mark without actually removing the entire mark. You have to have previously called `markSet()` otherwise
    /// this method does nothing.
    /// 
    /// - Parameter count: the number of characters to back out.
    /// - Returns: the number of characters actually backed out in case there weren't `count` characters available.
    ///
    @discardableResult open func markBackup(count: Int) -> Int {
        if count > 0 {
            return lock.withLock {
                if let mi = markStack.last {
                    for cc in (0 ..< count) {
                        guard let data = mi.data.popLast() else { return cc }
                        line = data.0
                        column = data.1
                        xbuffer.insert(data.2, at: 0)
                    }
                }
                return 0
            }
        }
        return 0
    }

    @inlinable open override func open() {
        lock.withLock {
            line = 1
            column = 1
            _open()
        }
    }

    @inlinable open override func close() {
        lock.withLock {
            _close()
            markStack.removeAll(keepingCapacity: false)
            xbuffer.removeAll(keepingCapacity: false)
            line = 0
            column = 0
        }
    }

    /*===========================================================================================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    @inlinable func _markReturn() {
        if let mi = markStack.popLast(), let data = mi.data.first {
            line = data.0
            column = data.1
            xbuffer.insert(contentsOf: mi.data.map({ $0.2 }), at: 0)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Read one character.
    /// 
    /// - Returns: the next character or `nil` if EOF.
    /// - Throws: if an I/O error occurs.
    ///
    @inlinable func __read() throws -> Character? {
        if xbuffer.isEmpty { return try _read() }
        return xbuffer.popFirst()
    }

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
    @usableFromInline func __read(chars: inout [Character], maxLength: Int) throws -> Int {
        if !chars.isEmpty { chars.removeAll(keepingCapacity: true) }

        let cc1 = xbuffer.count
        if cc1 > 0 {
            let r = (0 ..< min(maxLength, cc1))
            chars.append(contentsOf: xbuffer[r])
            xbuffer.removeSubrange(r)
        }

        let cc2 = chars.count
        if cc2 < maxLength {
            var xchars: [Character] = []
            let cc3:    Int         = try _read(chars: &xchars, maxLength: (maxLength - cc2))
            if cc3 > 0 { chars.append(contentsOf: xchars) }
        }

        return chars.count
    }

    /*===========================================================================================================================================================================*/
    /// A class to hold the marked place in the input stream.
    ///
    @usableFromInline class MarkItem {
        @usableFromInline var data: [(Int, Int, Character)] = []

        @inlinable init() {}

        @inlinable func add(_ line: Int, _ column: Int, _ sz: Int, _ char: Character) -> (Int, Int) {
            data <+ (line, column, char)
            return textPositionUpdate(char, position: (line, column), tabSize: sz)
        }
    }
}
