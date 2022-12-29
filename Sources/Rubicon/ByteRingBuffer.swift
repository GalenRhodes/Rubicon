// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: ByteRingBuffer.swift
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

/*==============================================================================================================================================================================*/
public class ByteRingBuffer {

    @usableFromInline var ringBuffer: UnsafeMutablePointer<PGRingBuffer>
    @usableFromInline let byteBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    @usableFromInline let lock:       NSRecursiveLock             = NSRecursiveLock()
/*@f0*/
    @inlinable public var count:   Int  { PGRingBufferCount(ringBuffer) }
    @inlinable public var isEmpty: Bool { count == 0 }
/*@f1*/
    /*==========================================================================================================================================================================*/
    public init(initialSize: Int = 1024) {
        ringBuffer = PGCreateRingBuffer(initialSize)
    }

    /*==========================================================================================================================================================================*/
    deinit {
        PGDiscardRingBuffer(ringBuffer)
        byteBuffer.deallocate()
    }

    /*==========================================================================================================================================================================*/
    @inlinable public subscript(index: Int) -> UInt8 {
        get {
            guard index >= 0 && index < count else { fatalError(IndexOutOfBoundsError) }
            return PGGetByteFromRingBuffer(ringBuffer, index)
        }
        set {
            guard index >= 0 && index < count else { fatalError(IndexOutOfBoundsError) }
            PGSetByteOnRingBuffer(ringBuffer, index, newValue)
        }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func defragment() {
        lock.withLock { PGDefragRingBuffer(ringBuffer) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func clear(keepCapacity: Bool = false) {
        PGClearRingBuffer(ringBuffer, keepCapacity)
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func throwAway(length: Int) -> Int {
        lock.withLock { let cc = min(length, PGRingBufferCount(ringBuffer)); PGRingBufferConsume(ringBuffer, length); return cc }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getNext(into data: inout Data, maxLength limit: Int = Int.max) -> Int {
        lock.withLock { _get(into: &data, maxLength: limit) { _getNext(into: $0, maxLength: $1) } }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getNextByte() -> UInt8? {
        lock.withLock { _getNext(into: byteBuffer, maxLength: 1) == 1 ? byteBuffer.pointee : nil }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getNext(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        lock.withLock { _getNext(into: buffer, maxLength: limit) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getNext(maxLength limit: Int = Int.max) -> Data {
        var data = Data(); _ = getNext(into: &data, maxLength: limit); return data
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getNext(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        buffer.withBaseAddress { getNext(into: $0, maxLength: $1) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getLastByte() -> UInt8? {
        lock.withLock { _getLast(into: byteBuffer, maxLength: 1) == 1 ? byteBuffer.pointee : nil }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getLast(maxLength limit: Int = Int.max) -> Data {
        var data = Data(); _ = getLast(into: &data, maxLength: limit); return data
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getLast(into data: inout Data, maxLength limit: Int = Int.max) -> Int {
        lock.withLock { _get(into: &data, maxLength: limit) { _getLast(into: $0, maxLength: $1) } }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getLast(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        lock.withLock { _getLast(into: buffer, maxLength: limit) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func getLast(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        buffer.withBaseAddress { getLast(into: $0, maxLength: $1) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func append(_ byte: UInt8) {
        lock.withLock { byteBuffer.pointee = byte; _append(data: byteBuffer, length: 1) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func append(_ byte: Int8) {
        append(UInt8(bitPattern: byte))
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func append(data: Data) {
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in append(data: ptr) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func append(data: UnsafeRawPointer, length: Int) {
        lock.withLock { _append(data: data, length: length) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func append(data: UnsafeRawBufferPointer) {
        data.withBaseAddress { append(data: $0, length: $1) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(_ byte: UInt8) {
        lock.withLock { byteBuffer.pointee = byte; _prepend(data: byteBuffer, length: 1) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(_ byte: Int8) {
        prepend(UInt8(bitPattern: byte))
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(data: UnsafeRawPointer, length: Int) {
        lock.withLock { _prepend(data: data, length: length) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(data: UnsafeRawBufferPointer) {
        data.withBaseAddress { prepend(data: $0, length: $1) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(data: UnsafePointer<UInt8>, length: Int) {
        prepend(data: UnsafeRawPointer(data), length: length)
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(data: UnsafePointer<Int8>, length: Int) {
        prepend(data: UnsafeRawPointer(data), length: length)
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(data: UnsafeBufferPointer<UInt8>) {
        prepend(data: UnsafeRawBufferPointer(data))
    }

    /*==========================================================================================================================================================================*/
    @inlinable public func prepend(data: UnsafeBufferPointer<Int8>) {
        prepend(data: UnsafeRawBufferPointer(data))
    }

    /*==========================================================================================================================================================================*/
    @inlinable func _prepend(data: UnsafeRawPointer, length: Int) {
        guard PGPrependToRingBuffer(ringBuffer, data, length) else { fatalError(InsufficientMemoryError) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable func _append(data: UnsafeRawPointer, length: Int) {
        guard PGAppendToRingBuffer(ringBuffer, data, length) else { fatalError(InsufficientMemoryError) }
    }

    /*==========================================================================================================================================================================*/
    @inlinable func _getNext(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        PGReadFromRingBuffer(ringBuffer, buffer, limit)
    }

    /*==========================================================================================================================================================================*/
    @inlinable func _getLast(into buffer: UnsafeMutableRawPointer, maxLength limit: Int) -> Int {
        PGReadLastFromRingBuffer(ringBuffer, buffer, limit)
    }

    /*==========================================================================================================================================================================*/
    @inlinable func _get(into data: inout Data, maxLength limit: Int, using block: (UnsafeMutablePointer<UInt8>, Int) -> Int) -> Int {
        let bufferSize = min(8192, limit)
        let buffer     = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        return _get(&data, buffer, bufferSize, limit, block)
    }

    /*==========================================================================================================================================================================*/
    @usableFromInline func _get(_ data: inout Data, _ buffer: UnsafeMutablePointer<UInt8>, _ bufferSize: Int, _ limit: Int, _ block: (UnsafeMutablePointer<UInt8>, Int) -> Int) -> Int {
        var bytesRead = 0
        while bytesRead < limit {
            let bc = block(buffer, min(bufferSize, (limit - bytesRead)))
            guard bc > 0 else { break }
            bytesRead += bc
            data.append(buffer, count: bc)
        }
        return bytesRead
    }
}
