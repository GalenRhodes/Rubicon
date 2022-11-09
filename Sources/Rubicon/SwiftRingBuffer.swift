// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: RingBuffer.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 09, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation
import RingBuffer

public class SwiftRingBuffer {

    @usableFromInline var ringBuffer: UnsafeMutablePointer<PGRingBuffer>
    @usableFromInline let byteBuffer: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: MemoryLayout<UInt8>.alignment)
    @usableFromInline let lock:       NSRecursiveLock         = NSRecursiveLock()

    @inlinable public var count:   Int { PGRingBufferCount(ringBuffer) }
    @inlinable public var isEmpty: Bool { count == 0 }

    public init(initialSize: Int = 1024) {
        ringBuffer = PGCreateRingBuffer(initialSize)
    }

    deinit {
        PGDiscardRingBuffer(ringBuffer)
        byteBuffer.deallocate()
    }

    @inlinable public func defragment() {
        lock.withLock { PGDefragRingBuffer(ringBuffer) }
    }

    @inlinable func _prepend(data: UnsafeRawPointer, length: Int) {
        guard PGPrependToRingBuffer(ringBuffer, data, length) else { fatalError("Insufficient Memory") }
    }

    @inlinable func _append(data: UnsafeRawPointer, length: Int) {
        guard PGAppendToRingBuffer(ringBuffer, data, length) else { fatalError("Insufficient Memory") }
    }

    @inlinable func _getNext(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        PGReadFromRingBuffer(ringBuffer, buffer, limit)
    }

    @inlinable func _getLast(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        PGReadLastFromRingBuffer(ringBuffer, buffer, limit)
    }

    @inlinable func _getByte() -> UInt8 {
        byteBuffer.withMemoryRebound(to: UInt8.self, capacity: 1) { $0.pointee }
    }

    @inlinable func _setByte(_ byte: UInt8) -> UnsafeMutableRawPointer {
        byteBuffer.withMemoryRebound(to: UInt8.self, capacity: 1) { $0.pointee = byte }
        return byteBuffer
    }

    @usableFromInline func _get(into data: inout Data, maxLength limit: Int, using block: (UnsafeMutablePointer<UInt8>, Int) -> Int) -> Int {
        lock.withLock {
            var bytesRead  = 0
            let bufferSize = min(8192, limit)
            let buffer     = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

            defer { buffer.deallocate() }

            while bytesRead < limit {
                let bc = block(buffer, min(bufferSize, (limit - bytesRead)))
                guard bc > 0 else { break }
                bytesRead += bc
                data.append(buffer, count: bc)
            }

            return bytesRead
        }
    }
}

extension SwiftRingBuffer {

    @inlinable public func getNext(into data: inout Data, maxLength limit: Int = Int.max) -> Int {
        lock.withLock { _get(into: &data, maxLength: limit) { _getNext(into: $0, maxLength: $1) } }
    }

    @inlinable public func getLast(into data: inout Data, maxLength limit: Int = Int.max) -> Int {
        lock.withLock { _get(into: &data, maxLength: limit) { _getLast(into: $0, maxLength: $1) } }
    }

    @inlinable public func getLastByte() -> UInt8? {
        lock.withLock { _getLast(into: byteBuffer, maxLength: 1) == 1 ? _getByte() : nil }
    }

    @inlinable public func getNextByte() -> UInt8? {
        lock.withLock { _getNext(into: byteBuffer, maxLength: 1) == 1 ? _getByte() : nil }
    }

    @inlinable public func append(_ byte: UInt8) {
        lock.withLock { _append(data: _setByte(byte), length: 1) }
    }

    @inlinable public func getNext(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        lock.withLock { _getNext(into: buffer, maxLength: limit) }
    }

    @inlinable public func getLast(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        lock.withLock { _getLast(into: buffer, maxLength: limit) }
    }

    @inlinable public func append(data: UnsafeRawPointer, length: Int) {
        lock.withLock { _append(data: data, length: length) }
    }

    @inlinable public func prepend(data: UnsafeRawPointer, length: Int) {
        lock.withLock { _prepend(data: data, length: length) }
    }

    @inlinable public func prepend(_ byte: UInt8) {
        lock.withLock { _prepend(data: _setByte(byte), length: 1) }
    }

    @inlinable public func getNext(maxLength limit: Int = Int.max) -> Data {
        var data = Data()
        _ = getNext(into: &data, maxLength: limit)
        return data
    }

    @inlinable public func getLast(maxLength limit: Int = Int.max) -> Data {
        var data = Data()
        _ = getLast(into: &data, maxLength: limit)
        return data
    }

    @inlinable public func getNext(into buffer: UnsafeMutablePointer<UInt8>, maxLength limit: Int) -> Int {
        getNext(into: UnsafeMutableRawPointer(buffer), maxLength: limit)
    }

    @inlinable public func getNext(into buffer: UnsafeMutablePointer<Int8>, maxLength limit: Int) -> Int {
        getNext(into: UnsafeMutableRawPointer(buffer), maxLength: limit)
    }

    @inlinable public func getLast(into buffer: UnsafeMutablePointer<UInt8>, maxLength limit: Int) -> Int {
        getLast(into: UnsafeMutableRawPointer(buffer), maxLength: limit)
    }

    @inlinable public func getLast(into buffer: UnsafeMutablePointer<Int8>, maxLength limit: Int) -> Int {
        getLast(into: UnsafeMutableRawPointer(buffer), maxLength: limit)
    }

    @inlinable public func getNext(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        guard let ptr = buffer.baseAddress else { fatalError() }
        return getNext(into: ptr, maxLength: buffer.count)
    }

    @inlinable public func getNext(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int {
        getNext(into: UnsafeMutableRawBufferPointer(buffer))
    }

    @inlinable public func getNext(into buffer: UnsafeMutableBufferPointer<Int8>) -> Int {
        getNext(into: UnsafeMutableRawBufferPointer(buffer))
    }

    @inlinable public func getLast(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        guard let ptr = buffer.baseAddress else { fatalError() }
        return getLast(into: ptr, maxLength: buffer.count)
    }

    @inlinable public func getLast(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int {
        getLast(into: UnsafeMutableRawBufferPointer(buffer))
    }

    @inlinable public func getLast(into buffer: UnsafeMutableBufferPointer<Int8>) -> Int {
        getLast(into: UnsafeMutableRawBufferPointer(buffer))
    }

    @inlinable public func append(data: Data) {
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in append(data: ptr) }
    }

    @inlinable public func append(data: UnsafeRawBufferPointer) {
        data.withBaseAddress { append(data: $0, length: $1) }
    }

    @inlinable public func append(data: UnsafePointer<UInt8>, length: Int) {
        append(data: UnsafeRawPointer(data), length: length)
    }

    @inlinable public func append(data: UnsafePointer<Int8>, length: Int) {
        append(data: UnsafeRawPointer(data), length: length)
    }

    @inlinable public func append(data: UnsafeBufferPointer<UInt8>) {
        append(data: UnsafeRawBufferPointer(data))
    }

    @inlinable public func append(data: UnsafeBufferPointer<Int8>) {
        append(data: UnsafeRawBufferPointer(data))
    }

    @inlinable public func append(_ byte: Int8) {
        append(UInt8(bitPattern: byte))
    }

    @inlinable public func prepend(data: UnsafeRawBufferPointer) {
        data.withBaseAddress { prepend(data: $0, length: $1) }
    }

    @inlinable public func prepend(data: UnsafePointer<UInt8>, length: Int) {
        prepend(data: UnsafeRawPointer(data), length: length)
    }

    @inlinable public func prepend(data: UnsafePointer<Int8>, length: Int) {
        prepend(data: UnsafeRawPointer(data), length: length)
    }

    @inlinable public func prepend(data: UnsafeBufferPointer<UInt8>) {
        prepend(data: UnsafeRawBufferPointer(data))
    }

    @inlinable public func prepend(data: UnsafeBufferPointer<Int8>) {
        prepend(data: UnsafeRawBufferPointer(data))
    }

    @inlinable public func prepend(_ byte: Int8) {
        prepend(UInt8(bitPattern: byte))
    }
}
