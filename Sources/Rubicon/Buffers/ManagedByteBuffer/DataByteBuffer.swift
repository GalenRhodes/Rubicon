/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: DataByteBuffer.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/15/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

open class DataByteBuffer: MutableManagedByteBuffer {
    public var length: Int { data.count }
    public var count:  Int

    private var data: Data

    public init(data: Data) {
        self.data = data
        count = data.count
    }

    @discardableResult open func append<S>(contentsOf s: S) -> Int where S: Sequence, S.Element == UInt8 {
        for byte in s { append(byte: byte) }
        return count
    }

    @discardableResult open func append(byte: UInt8) -> Int? {
        if count < length {
            data[count++] = byte
            return count
        }
        else {
            data.append(byte)
            count = length
            return count
        }
    }

    open func relocateToFront(start idx: Int) -> Int {
        guard idx.inRange(0 ... length) else { fatalError("Invalid index: \(idx)") }
        guard idx > 0 && idx < length else { return 0 }
        let cc = (length - idx)

        data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) -> Void in
            guard let p = raw.baseAddress else { return }
            memcpy(p, (p + idx), cc)
        }
        return cc
    }

    open func relocateToFront(start idx: Int, count cc: Int) {
        guard idx.inRange(0 ... length) else { fatalError("Invalid index: \(idx)") }
        guard cc.inRange(0 ... (length - idx)) else { fatalError("Invalid count: \(cc)") }
        guard idx > 0 && cc > 0 else { return }

        data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) -> Void in
            guard let p = raw.baseAddress else { return }
            memcpy(p, (p + idx), cc)
        }
    }

    @discardableResult open func withBytes<V>(_ body: (ByteROPointer, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> V in
            if let p = raw.baseAddress {
                var cc = count
                let rs = try body(p.bindMemory(to: UInt8.self, capacity: cc), &cc)
                count = cc.clamp(minValue: 0, maxValue: raw.count)
                return rs
            }
            else {
                var bs: UInt8 = 0
                var cc        = 0
                count = 0
                return try body(&bs, &cc)
            }
        }
    }

    @discardableResult open func withBytes<V>(_ body: (UnsafeBufferPointer<UInt8>, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeBytes { (p: UnsafeRawBufferPointer) -> V in
            var cc = count
            let rs = try body(p.bindMemory(to: UInt8.self), &cc)
            count = cc.clamp(minValue: 0, maxValue: p.count)
            return rs
        }
    }

    @discardableResult open func withBytes<V>(_ body: (BytePointer, Int, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) -> V in
            if let p = raw.baseAddress {
                var cc = count
                let rs = try body(p.bindMemory(to: UInt8.self, capacity: raw.count), raw.count, &cc)
                count = cc.clamp(minValue: 0, maxValue: raw.count)
                return rs
            }
            else {
                var bs: UInt8 = 0
                var cc        = 0
                count = 0
                return try body(&bs, 0, &cc)
            }
        }
    }

    @discardableResult open func withBytes<V>(_ body: (UnsafeMutableBufferPointer<UInt8>, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) -> V in
            var cc = count
            let rs = try body(raw.bindMemory(to: UInt8.self), &cc)
            count = cc.clamp(minValue: 0, maxValue: raw.count)
            return rs
        }
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafePointer<T>, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> V in
            if let p = raw.baseAddress {
                var cc = fromBytes(type: T.self, count)
                let rs = try body(p.bindMemory(to: T.self, capacity: fromBytes(type: T.self, raw.count)), &cc)
                count = toBytes(type: T.self, cc).clamp(minValue: 0, maxValue: raw.count)
                return rs
            }
            else {
                let p = getEmptyBuffer(type: T.self)
                defer { p.deallocate() }
                var cc = 0
                count = 0
                return try body(p.bindMemory(to: T.self, capacity: 1), &cc)
            }
        }
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutablePointer<T>, Int, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) -> V in
            if let p = raw.baseAddress {
                var cc = fromBytes(type: T.self, count)
                let rs = try body(p.bindMemory(to: T.self, capacity: fromBytes(type: T.self, raw.count)), fromBytes(type: T.self, raw.count), &cc)
                count = toBytes(type: T.self, cc).clamp(minValue: 0, maxValue: raw.count)
                return rs
            }
            else {
                let p = getEmptyBuffer(type: T.self)
                defer { p.deallocate() }
                var cc = 0
                count = 0
                return try body(p.bindMemory(to: T.self, capacity: 1), 0, &cc)
            }
        }
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeBufferPointer<T>, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> V in
            var cc = fromBytes(type: T.self, count)
            let rs = try body(raw.bindMemory(to: T.self), &cc)
            count = toBytes(type: T.self, cc).clamp(minValue: 0, maxValue: raw.count)
            return rs
        }
    }

    @discardableResult open func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutableBufferPointer<T>, inout Int) throws -> V) rethrows -> V {
        try data.withUnsafeMutableBytes { (raw: UnsafeMutableRawBufferPointer) -> V in
            var cc = fromBytes(type: T.self, count)
            let rs = try body(raw.bindMemory(to: T.self), &cc)
            count = toBytes(type: T.self, cc).clamp(minValue: 0, maxValue: raw.count)
            return rs
        }
    }

    private func getEmptyBuffer<T>(type: T.Type) -> UnsafeMutableRawPointer {
        let p = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<T>.size, alignment: MemoryLayout<T>.alignment)
        p.initializeMemory(as: UInt8.self, repeating: 0, count: MemoryLayout<T>.size)
        return p
    }
}
