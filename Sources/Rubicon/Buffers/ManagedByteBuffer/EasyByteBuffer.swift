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
import CoreFoundation

open class EasyByteBuffer: MutableManagedByteBuffer {
    //@f:0
    public let length: Int
    public var count:  Int = 0
    public let bytes:  BytePointer
    //@f:1

    public init(length: Int) {
        self.length = length
        bytes = BytePointer.allocate(capacity: length)
        bytes.initialize(repeating: 0, count: length)
    }

    public init?(buffer: UnsafeRawBufferPointer) {
        length = buffer.count
        count = length

        guard length > 0 else { return nil }
        guard let p = buffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
        bytes = BytePointer.allocate(capacity: length)
        bytes.initialize(from: p, count: length)
    }

    deinit {
        bytes.deinitialize(count: length)
        bytes.deallocate()
    }

    @discardableResult open func append(byte: UInt8) -> Int? {
        guard count < length else { return nil }
        bytes[count++] = byte
        return count
    }

    @discardableResult open func append<S>(contentsOf: S) -> Int where S: Sequence, S.Element == UInt8 {
        var cc: Int = 0

        for byte: UInt8 in contentsOf {
            guard count < length else { return cc }
            bytes[count++] = byte
            cc += 1
        }

        return cc
    }

    @discardableResult open func relocateToFront(start idx: Int) -> Int {
        guard count >= 0 && count <= length else { fatalError("Internal count value is invalid.") }
        guard idx >= 0 && idx <= count else { fatalError("Start index out of bounds.") }

        if idx > 0 && count > 0 {
            count = (count - idx)
            _relocate(start: idx, count: count)
        }

        return count
    }

    open func relocateToFront(start idx: Int, count cc: Int) {
        guard (idx >= 0) && (idx <= length) else { fatalError("Start index out of bounds.") }
        guard (cc >= 0) && ((idx + cc) <= length) else { fatalError("Count is invalid.") }
        _relocate(start: idx, count: cc)
    }

    final func _relocate(start idx: Int, count cc: Int) {
        if (idx > 0) && (idx < length) && (cc > 0) {
            memmove(bytes, (bytes + idx), cc)
        }
        count = cc
    }

    @discardableResult open func withBytes<V>(_ body: (BytePointer, Int, inout Int) throws -> V) rethrows -> V {
        var cc = count
        let r  = try body(bytes, length, &cc)
        count = cc.clamp(minValue: 0, maxValue: length)
        return r
    }

    @discardableResult open func withBytes<V>(_ body: (UnsafeMutableBufferPointer<UInt8>, inout Int) throws -> V) rethrows -> V {
        var cc = count
        let r  = try body(UnsafeMutableBufferPointer<UInt8>(start: bytes, count: length), &cc)
        count = cc.clamp(minValue: 0, maxValue: length)
        return r
    }

    @discardableResult open func withBytes<V>(_ body: (ByteROPointer, inout Int) throws -> V) rethrows -> V {
        var cc = count
        let rs = try body(bytes, &cc)
        count = cc.clamp(minValue: 0, maxValue: length)
        return rs
    }

    @discardableResult open func withBytes<V>(_ body: (UnsafeBufferPointer<UInt8>, inout Int) throws -> V) rethrows -> V {
        var cc = count
        let rs = try body(UnsafeBufferPointer<UInt8>(start: bytes, count: count), &cc)
        count = cc.clamp(minValue: 0, maxValue: length)
        return rs
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeBufferPointer<T>, inout Int) throws -> V) rethrows -> V {
        var cc = fromBytes(type: T.self, count)
        let bf = UnsafeBufferPointer<T>(start: UnsafeRawPointer(bytes).bindMemory(to: T.self, capacity: cc), count: cc)
        let rs = try body(bf, &cc)
        count = toBytes(type: T.self, cc).clamp(minValue: 0, maxValue: length)
        return rs
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafePointer<T>, inout Int) throws -> V) rethrows -> V {
        var c = fromBytes(type: T.self, count)
        let p = UnsafeRawPointer(bytes).bindMemory(to: T.self, capacity: c)
        let r = try body(p, &c)
        count = toBytes(type: T.self, c).clamp(minValue: 0, maxValue: length)
        return r
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutablePointer<T>, Int, inout Int) throws -> V) rethrows -> V {
        var c = fromBytes(type: T.self, count)
        let l = fromBytes(type: T.self, length)
        let r = try body(UnsafeMutableRawPointer(bytes).bindMemory(to: T.self, capacity: l), l, &c)
        count = toBytes(type: T.self, c).clamp(minValue: 0, maxValue: length)
        return r
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutableBufferPointer<T>, inout Int) throws -> V) rethrows -> V {
        var c = fromBytes(type: T.self, count)
        let r = try body(UnsafeMutableBufferPointer<T>(start: UnsafeMutableRawPointer(bytes).bindMemory(to: T.self, capacity: c), count: c), &c)
        count = toBytes(type: T.self, c).clamp(minValue: 0, maxValue: length)
        return r
    }
}
