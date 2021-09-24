/*
 *     PROJECT: Rubicon
 *    FILENAME: StringCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/2/21
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

open class StringCharInputStream: SimpleStringCharInputStream, CharInputStream {
    typealias MarkItem = (TextPosition, StringIndex)

    //@f:0
    open     var markCount: Int          { lck.withLock { mstk.count } }
    open     var position:  TextPosition { lck.withLock { pos        } }
    open     var tabWidth:  Int8         = 4

    internal var pos:       TextPosition = (0, 0)
    internal var mstk:      [MarkItem]   = []
    //@f:1

    public override init(string: String) { super.init(string: string) }

    open func markSet() { lck.withLock { _markSet() } }

    open func markReturn() { lck.withLock { _markReturn() } }

    open func markDelete() { lck.withLock { _markDelete() } }

    open func markReset() { lck.withLock { _markReturn(); _markSet() } }

    open func markClear() { lck.withLock { _markDelete(); _markSet() } }

    @discardableResult open func markBackup(count: Int) -> Int { lck.withLock { _markBackup(count: count) } }

    func _markSet() { mstk <+ (pos, index) }

    func _markDelete() { _ = mstk.popLast() }

    func _markReturn() { if let mi = mstk.popLast() { (pos, index) = mi } }

    func _markBackup(count: Int) -> Int {
        guard count > 0, let mi = mstk.last else { return 0 }
        var idx1 = mi.1
        let idx2 = (string.index(index, offsetBy: -count, limitedBy: idx1) ?? idx1)
        pos = mi.0
        while idx1 < idx2 {
            textPositionUpdate(string[idx1], pos: &pos, tabWidth: tabWidth)
            string.formIndex(after: &idx1)
        }
        return string.distance(from: idx2, to: index)
    }

    override func _open() {
        pos = (1, 1)
        mstk.removeAll(keepingCapacity: true)
        super._open()
    }

    override func _close() {
        super._close()
        pos = (0, 0)
        mstk.removeAll(keepingCapacity: false)
    }

    override func _read() throws -> Character? {
        guard let ch = try super._read() else { return nil }
        textPositionUpdate(ch, pos: &pos, tabWidth: tabWidth)
        return ch
    }

    override func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
        let cc = try super._append(to: &chars, maxLength: maxLength)
        guard cc > 0 else { return 0 }
        for ch in chars { textPositionUpdate(ch, pos: &pos, tabWidth: tabWidth) }
        return cc
    }
}
