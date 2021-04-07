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
    open     var position:  TextPosition { lock.withLock { pos        } }
    /*===========================================================================================================================================================================*/
    /// The number of marks on the stream.
    ///
    open     var markCount: Int          { lock.withLock { mstk.count } }
    /*===========================================================================================================================================================================*/
    /// The number of spaces in each tab stop.
    ///
    open     var tabWidth:  Int8         = 4
    /*===========================================================================================================================================================================*/
    /// The current line number.
    ///
    internal var pos:       TextPosition = (0, 0)
    /*===========================================================================================================================================================================*/
    /// The mark stack.
    ///
    internal var mstk:      [MarkItem]   = []
    // @f:1

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
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark but all operations happen on the most recently set mark.
    ///
    open func markSet() { lock.withLock { _markSet() } }

    /*===========================================================================================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    open func markReturn() { lock.withLock { _markReturn() } }

    /*===========================================================================================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    open func markDelete() { lock.withLock { _markDelete() } }

    /*===========================================================================================================================================================================*/
    /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markReturn()` followed immediately by a `markSet()`.
    ///
    open func markReset() { lock.withLock { _markReturn(); _markSet() } }

    /*===========================================================================================================================================================================*/
    /// Updates the most recently set mark to the current position. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markDelete()` followed immediately by a `markSet()`.
    ///
    open func markUpdate() { lock.withLock { _markDelete(); _markSet() } }

    /*===========================================================================================================================================================================*/
    /// Backs out the last `count` characters from the most recently set mark without actually removing the entire mark. You have to have previously called `markSet()` otherwise
    /// this method does nothing.
    /// 
    /// - Parameter count: the number of characters to back out.
    /// - Returns: the number of characters actually backed out in case there weren't `count` characters available.
    ///
    @discardableResult open func markBackup(count: Int) -> Int { lock.withLock { _markBackup(count: count) } }

    /*===========================================================================================================================================================================*/
    /// Open the stream for reading.
    ///
    override func _open() {
        pos = (1, 1)
        super._open()
    }

    /*===========================================================================================================================================================================*/
    /// Close the stream.
    ///
    override func _close() {
        super._close()
        mstk.removeAll(keepingCapacity: false)
        pos = (0, 0)
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark but all operations happen on the most recently set mark.
    ///
    func _markSet() { mstk <+ MarkItem(pos: pos) }

    /*===========================================================================================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    func _markDelete() { _ = mstk.popLast() }

    /*===========================================================================================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    func _markReturn() {
        if let mi = mstk.popLast() {
            pos = mi.pos
            buffer.insert(contentsOf: mi.chars, at: 0)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Backs out the last `count` characters from the most recently set mark without actually removing the entire mark. You have to have previously called `markSet()` otherwise
    /// this method does nothing.
    /// 
    /// - Parameter count: the number of characters to back out.
    /// - Returns: the number of characters actually backed out in case there weren't `count` characters available.
    ///
    func _markBackup(count: Int) -> Int {
        guard var mi = mstk.last else { return 0 }
        let data = mi.getLast(count: count)
        pos = data.1
        buffer.insert(contentsOf: data.2, at: 0)
        return data.0
    }

    /*===========================================================================================================================================================================*/
    /// Read one character.
    /// 
    /// - Returns: the next character or `nil` if EOF.
    /// - Throws: if an I/O error occurs.
    ///
    override func _read() throws -> Character? {
        guard let ch = try super._read() else { return nil }
        if var mi = mstk.last { mi.add(&pos, ch, tabWidth) }
        else { textPositionUpdate(ch, pos: &pos, tabWidth: tabWidth) }
        return ch
    }

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
    override func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
        let cc = try super._append(to: &chars, maxLength: maxLength)
        guard cc > 0 else { return cc }
        if var mi = mstk.last { for ch in chars { mi.add(&pos, ch, tabWidth) } }
        else { for ch in chars { textPositionUpdate(ch, pos: &pos, tabWidth: tabWidth) } }
        return cc
    }

    /*===========================================================================================================================================================================*/
    /// A class to hold the marked place in the input stream.
    ///
    struct MarkItem {
        //@f:0
        let pos:   TextPosition
        var data:  [(TextPosition, Character)] = []
        var chars: [Character]                 { data.map { $0.1 } }
        //@f:1

        init(pos: TextPosition) { self.pos = pos }

        mutating func add(_ pos: inout TextPosition, _ char: Character, _ tab: Int8) {
            data <+ (pos, char)
            textPositionUpdate(char, pos: &pos, tabWidth: tab)
        }

        mutating func getLast(count: Int) -> (Int, TextPosition, [Character]) {
            let i = min(count, data.count)
            guard i > 0 else { return (0, pos, []) }

            let j = data.endIndex
            let k = (j - i)
            let l = (k ..< j)
            let m = (i, data[k].0, data[l].map { $0.1 })

            data.removeSubrange(l)
            return m
        }
    }
}
