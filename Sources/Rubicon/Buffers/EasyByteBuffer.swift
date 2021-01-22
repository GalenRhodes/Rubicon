/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: EasyByteBuffer.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/21/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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

open class EasyByteBuffer {

    public let bytes:  BytePointer
    public let length: Int
    open var   count:  Int = 0

    public init(length: Int) {
        self.length = length
        bytes = BytePointer.allocate(capacity: length)
        bytes.initialize(repeating: 0, count: length)
    }

    deinit {
        bytes.deinitialize(count: length)
        bytes.deallocate()
    }

    @discardableResult @inlinable open func relocateToFront(start idx: Int) -> Int {
        guard count >= 0 && count <= length else { fatalError("Internal count value is invalid.") }
        guard idx >= 0 && idx <= count else { fatalError("Start index out of bounds.") }

        if idx > 0 && count > 0 {
            count = (count - idx)
            _relocate(start: idx, count: count)
        }

        return count
    }

    @inlinable open func relocateToFront(start idx: Int, count cc: Int) {
        guard (idx >= 0) && (idx <= length) else { fatalError("Start index out of bounds.") }
        guard (cc >= 0) && ((idx + cc) <= length) else { fatalError("Count is invalid.") }
        _relocate(start: idx, count: cc)
    }

    @inlinable final func _relocate(start idx: Int, count cc: Int) {
        if (idx > 0) && (idx < length) && (cc > 0) {
            memmove(bytes, (bytes + idx), cc)
        }
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutablePointer<T>, Int, inout Int) throws -> V) rethrows -> V {
        var tCount:  Int                     = ((count * MemoryLayout<UInt8>.stride) / MemoryLayout<T>.stride)
        let tLength: Int                     = ((length * MemoryLayout<UInt8>.stride) / MemoryLayout<T>.stride)
        let t1Buff:  UnsafeMutableRawPointer = UnsafeMutableRawPointer(bytes)
        let t2Buff:  UnsafeMutablePointer<T> = t1Buff.bindMemory(to: T.self, capacity: tCount)

        let res: V = try body(t2Buff, tLength, &tCount)
        count = ((count * MemoryLayout<T>.stride) / MemoryLayout<UInt8>.stride)
        return res
    }
}
