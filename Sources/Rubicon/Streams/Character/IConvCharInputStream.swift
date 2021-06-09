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

#if !os(Windows)
    open class IConvCharInputStream: SimpleIConvCharInputStream, CharInputStream {
        //@f:0
        /*======================================================================================================*/
        /// The number of marks on the stream.
        ///
        open     var markCount:  Int          { withLock { _markStack.count } }
        /*======================================================================================================*/
        /// The current line and column numbers.
        ///
        open     var tabWidth:   Int8         { get { withLock { _tabWidth } } set { withLock { _tabWidth = newValue } } }
        /*======================================================================================================*/
        /// The number of spaces in each tab stop.
        ///
        open     var position:   TextPosition { withLock { _position } }
        internal var _position:  TextPosition = (0, 0)
        internal var _tabWidth:  Int8         = 4
        internal var _markStack: [MarkItem]   = []
        //@f:1

        /*======================================================================================================*/
        /// Creates a new instance of IConvCharInputStream with the given InputStream, encodingName, and whether
        /// or not the given InputStream should be closed when this stream is discarded or closed.
        /// 
        /// - Parameters:
        ///   - inputStream: The underlying byte InputStream.
        ///   - encodingName: The character encoding name.
        ///   - autoClose: If `true` then the underlying byte InputStream will be closed when this
        ///                IConvCharInputStream is closed or discarded.
        ///
        public override init(inputStream: InputStream, encodingName: String, autoClose: Bool) {
            super.init(inputStream: inputStream, encodingName: encodingName, autoClose: autoClose)
        }

        /*======================================================================================================*/
        /// Marks the current point in the stream so that it can be returned to later. You can set more than one
        /// mark but all operations happen on the most recently set mark.
        ///
        open func markSet() { withLock { _markSet() } }

        /*======================================================================================================*/
        /// Removes and returns to the most recently set mark.
        ///
        open func markReturn() { withLock { _markReturn() } }

        /*======================================================================================================*/
        /// Removes the most recently set mark WITHOUT returning to it.
        ///
        open func markDelete() { withLock { _markDelete() } }

        /*======================================================================================================*/
        /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a
        /// new one is created. This is functionally equivalent to performing a `markReturn()` followed
        /// immediately by a `markSet()`.
        ///
        open func markReset() { withLock { _markReset() } }

        /*======================================================================================================*/
        /// Updates the most recently set mark to the current position. If there was no previously set mark then a
        /// new one is created. This is functionally equivalent to performing a `markDelete()` followed
        /// immediately by a `markSet()`.
        ///
        open func markUpdate() { withLock { _markUpdate() } }

        /*======================================================================================================*/
        /// Backs out the last `count` characters from the most recently set mark without actually removing the
        /// entire mark. You have to have previously called `markSet()` otherwise this method does nothing.
        /// 
        /// - Parameter count: the number of characters to back out.
        /// - Returns: The number of characters actually backed out in case there weren't `count` characters
        ///            available.
        ///
        @discardableResult open func markBackup(count: Int = 1) -> Int { withLock { _markBackup(count: count) } }

        override func _open() {
            guard status == .notOpen else { return }
            _position = (1, 1)
            super._open()
        }

        override func _close() {
            super._close()
            _markStack.removeAll()
            _position = (0, 0)
        }

        override func _read() throws -> Character? {
            guard let ch = try super._read() else { return nil }
            if let m = _markStack.last { m.data <+ ch }
            textPositionUpdate(ch, pos: &_position, tabWidth: _tabWidth)
            return ch
        }

        override func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
            let eidx = chars.endIndex
            let cc   = try super._append(to: &chars, maxLength: maxLength)
            if let m = _markStack.last { chars[eidx ..< chars.endIndex].forEach { m.data <+ $0; textPositionUpdate($0, pos: &_position, tabWidth: _tabWidth) } }
            else { chars[eidx ..< chars.endIndex].forEach { textPositionUpdate($0, pos: &_position, tabWidth: _tabWidth) } }
            return cc
        }

        func _markSet() { if isOpen { _markStack <+ MarkItem(position: _position) } }

        func _markDelete() { if isOpen, let m = _markStack.popLast() { m.data.removeAll() } }

        func _markReturn() { if isOpen, let m = _markStack.popLast() { _markBackup(m, count: m.data.count) } }

        func _markReset() {
            if isOpen {
                if let m = _markStack.last { _markBackup(m, count: m.data.count) }
                else { _markSet() }
            }
        }

        func _markUpdate() {
            if isOpen {
                if let m = _markStack.last { m.data.removeAll() }
                else { _markSet() }
            }
        }

        func _markBackup(count: Int) -> Int {
            guard isOpen, let m: MarkItem = _markStack.last else { return 0 }
            return _markBackup(m, count: count)
        }

        @discardableResult func _markBackup(_ m: MarkItem, count: Int) -> Int {
            let s: Int = m.data.startIndex
            let e: Int = m.data.endIndex
            let c: Int = min((e - s), ((count < 0) ? 0 : count))

            if c > 0 {
                let p: Int        = (e - c)
                let r: Range<Int> = (p ..< e)

                _position = m.pos
                m.data[s ..< p].forEach { textPositionUpdate($0, pos: &_position, tabWidth: _tabWidth) }
                buffer.insert(contentsOf: m.data[r], at: 0)
                m.data.removeSubrange(r)
            }

            return c
        }

        final class MarkItem {
            let pos:  TextPosition
            var data: [Character] = []

            init(position pos: TextPosition) { self.pos = pos }
        }
    }
#endif
