/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: ByteBuffer.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 8/7/20
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
import RingBuffer

public enum RingByteBufferError: Error {
    case IllegalResponse(description: String = "Closure returned an invalid response.")
    case InvalidArgument(description: String = "Invalid argument.")
}

let OneMB:  Int = (1024 * 1024)
let HalfGB: Int = (OneMB * 512)

/*==============================================================================================================*/
/// This class is a simple wrapper around a
/// <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> object that allows for
/// treating the data like a stream of bytes. The three basic operations are `get(buffer:maxLength:)`,
/// `append(buffer:length:)`, and `prepend(buffer:length:)`.
///
/// NOTE: This class is NOT thread safe.
///
open class RingByteBuffer {

    /*==========================================================================================================*/
    /// The ring buffer.
    ///
    let buffer: UnsafeMutablePointer<PGRingBuffer>

    /*==========================================================================================================*/
    /// The number of bytes in the available.
    ///
    public final var count:             Int { PGRingBufferCount(buffer) }

    /*==========================================================================================================*/
    /// Returns `true` if there are bytes in the ring buffer.
    ///
    @available(*, deprecated, renamed: "isNotEmpty")
    public final var hasBytesAvailable: Bool { isNotEmpty }

    /*==========================================================================================================*/
    /// The total capacity of the buffer.
    ///
    public final var capacity:          Int { PGRingBufferCapacity(buffer) }

    /*==========================================================================================================*/
    /// The room in the buffer for new bytes.
    ///
    public final var headroom:          Int { PGRingBufferRemaining(buffer) }

    /*==========================================================================================================*/
    /// Returns `true` if the buffer is empty.
    ///
    public final var isEmpty:           Bool { (PGRingBufferCount(buffer) == 0) }
    public final var isNotEmpty:        Bool { (PGRingBufferCount(buffer) > 0) }

    /*==========================================================================================================*/
    /// Creates a new instance of `ByteBuffer`.
    /// - Parameter initialCapacity: the initial capacity of the buffer.
    ///
    public init(initialCapacity: Int = BasicBufferSize) { buffer = PGCreateRingBuffer(initialCapacity) }

    deinit { PGDiscardRingBuffer(buffer) }

    /*==========================================================================================================*/
    /// Clear the buffer.
    ///
    /// - Parameter keepingCapacity: `true` if the capacity should be retained. `false` if the buffer should
    ///                              shrink to it's original size.
    ///
    public final func clear(keepingCapacity: Bool = false) { PGClearRingBuffer(buffer, keepingCapacity) }

    /*==========================================================================================================*/
    /// Read a byte from the buffer.
    ///
    /// - Parameter byte: a pointer to the variable to receive the byte.
    /// - Returns: `true` if the byte was retrived or `false` if the buffer was empty.
    ///
    public final func get(byte: inout UInt8) -> Bool { (PGReadFromRingBuffer(buffer, &byte, 1) == 1) }

    /*==========================================================================================================*/
    /// Read a byte from the buffer.
    ///
    /// - Returns: The next byte or `nil` if the buffer is empty.
    ///
    public final func get() -> UInt8? { var byte: UInt8 = 0; return ((PGReadFromRingBuffer(buffer, &byte, 1) == 1) ? byte : nil) }

    /*==========================================================================================================*/
    /// Get, at most, the first `maxLength` bytes from the buffer.
    ///
    /// - Parameters:
    ///   - dest: The destination buffer.
    ///   - maxLength: The maximum number of bytes the destination buffer can hold.
    ///
    /// - Returns: The number of bytes actually gotten.
    ///
    public final func get(dest: BytePointer, maxLength: Int) -> Int { PGReadFromRingBuffer(buffer, dest, maxLength) }

    /*==========================================================================================================*/
    /// Get bytes from the buffer into the instance of `EasyByteBuffer`.
    ///
    /// - Parameters:
    ///   - dest: The destination buffer.
    ///
    /// - Returns: The number of bytes actually gotten.
    ///
    @discardableResult public final func get(dest: EasyByteBuffer) -> Int {
        dest.withBytes { bytes, length, count -> Int in
            guard count >= 0 && count < length else { return 0 }
            let cx = count
            let cy = PGReadFromRingBuffer(buffer, (bytes + cx), (length - cx))
            count = (cx + cy)
            return cy
        }
    }

    /*==========================================================================================================*/
    /// Get the bytes from the buffer.
    ///
    /// - Parameters:
    ///   - destData: The instance of
    ///               <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> that will
    ///               receive the bytes.
    ///   - maxLength: The maximum number of bytes to get. If -1 then all available bytes will be fetched.
    ///   - overWrite: `true` if `destData` should be cleared of any existing bytes first.
    ///
    /// - Returns: The number of bytes added to `destData`.
    ///
    public final func get(dest: inout Data, maxLength: Int = -1, overWrite: Bool = true) -> Int {
        if overWrite { dest.removeAll(keepingCapacity: true) }
        return _foo(maxLength: maxLength) { buff, x in dest.append(buff, count: x) }
    }

    public final func get(dest: inout [UInt8], maxLength: Int = -1, overWrite: Bool = true) -> Int {
        if overWrite { dest.removeAll(keepingCapacity: true) }
        return _foo(maxLength: maxLength) { buff, x in dest.append(contentsOf: UnsafeBufferPointer<UInt8>(start: buff, count: x)) }
    }

    private func _foo(maxLength: Int, _ body: (ByteROPointer, Int) -> Void) -> Int {
        guard maxLength != 0 && count > 0 else { return 0 }

        var cc: Int = 0
        let mx      = min(count, ((maxLength < 0) ? Int.max : maxLength))
        let bLen    = min(mx, 1024)
        let buff    = BytePointer.allocate(capacity: bLen)
        defer { buff.deallocate() }

        while cc < mx && count > 0 {
            let x = PGReadFromRingBuffer(buffer, UnsafeMutableRawPointer(buff), min(bLen, (mx - cc)))
            body(buff, x)
            cc += x
        }

        return cc
    }

    /*==========================================================================================================*/
    /// Get bytes from the END of the buffer.
    ///
    /// - Parameters:
    ///   - dest: The destination buffer.
    ///   - maxLength: The maximum number of bytes to read.
    /// - Returns: The number of bytes actually read.
    ///
    public final func getFromEnd(dest: UnsafeMutableRawPointer, maxLength: Int) -> Int {
        PGReadLastFromRingBuffer(buffer, dest, maxLength)
    }

    /*==========================================================================================================*/
    /// Append the given RingByteBuffer to this RingByteBuffer.
    ///
    /// - Parameter ringBuffer: the source ring buffer.
    ///
    public final func append(src: RingByteBuffer) { PGAppendRingBufferToRingBuffer(buffer, src.buffer) }

    /*==========================================================================================================*/
    /// Append the given byte to the buffer.
    ///
    /// - Parameter byte: the byte to append.
    ///
    public final func append(byte: UInt8) { PGAppendByteToRingBuffer(buffer, byte) }

    /*==========================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameters:
    ///   - src: The source buffer.
    ///   - length: The number of bytes in the source buffer.
    ///
    public final func append<T>(src: UnsafePointer<T>, length: Int) { append(src: UnsafeRawPointer(src), length: length) }

    /*==========================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameters:
    ///   - ezBuffer: The buffer to append bytes from.
    ///
    public final func append(src: EasyByteBuffer, reset: Bool = true) {
        src.withBytes { (bytes: ByteROPointer, count: inout Int) -> Void in
            if count > 0 {
                append(src: bytes, length: count)
                if reset { count = 0 }
            }
        }
    }

    /*==========================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameters:
    ///   - src: The source buffer.
    ///   - length: The number of bytes in the source buffer.
    ///
    public final func append(src: UnsafeRawPointer, length: Int) {
        if length > 0 { PGAppendToRingBuffer(buffer, src, length) }
    }

    /*==========================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameter buffSrc: the source buffer.
    ///
    public final func append<T>(src: UnsafeBufferPointer<T>) { append(src: UnsafeRawBufferPointer(src)) }

    /*==========================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameter rawBuffSrc: the source buffer.
    ///
    public final func append(src: UnsafeRawBufferPointer) { if let bp: UnsafeRawPointer = src.baseAddress { append(src: bp, length: src.count) } }

    /*==========================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameter dataSrc: the source data.
    ///
    public final func append(src: Data) { src.withUnsafeBytes { (p: UnsafeRawBufferPointer) in append(src: p) } }

    /*==========================================================================================================*/
    /// Prepend the given byte to the buffer. This byte will be prepended so that it is the next byte that will be
    /// read via `get(buffer:maxLength:)`.
    ///
    /// - Parameters:
    ///   - byte: The byte to prepend.
    ///
    public final func prepend(byte: UInt8) { PGPrependByteToRingBuffer(buffer, byte) }

    /*==========================================================================================================*/
    /// Prepend the given RingByteBuffer to this RingByteBuffer.
    ///
    /// - Parameter ringBuffer: the source ring buffer.
    ///
    public final func prepend(src: RingByteBuffer) { PGPrependRingBufferToRingBuffer(buffer, src.buffer) }

    /*==========================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that
    /// will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameters:
    ///   - rawSrc: The source buffer.
    ///   - length: The number of bytes in the source buffer.
    ///
    public final func prepend(src: UnsafeRawPointer, length: Int) { if length > 0 { PGPrependToRingBuffer(buffer, src.bindMemory(to: UInt8.self, capacity: length), length) } }

    /*==========================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that
    /// will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameters:
    ///   - src: The source buffer.
    ///   - length: The number of bytes in the source buffer.
    ///
    public final func prepend<T>(src: UnsafePointer<T>, length: Int) { prepend(src: UnsafeRawPointer(src), length: length) }

    /*==========================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that
    /// will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter rawBuffSrc: the source buffer.
    ///
    public final func prepend(src: UnsafeRawBufferPointer) { if let pointer: UnsafeRawPointer = src.baseAddress { prepend(src: pointer, length: src.count) } }

    /*==========================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that
    /// will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter buffSrc: the source buffer.
    ///
    public final func prepend<T>(src: UnsafeBufferPointer<T>) { prepend(src: UnsafeRawBufferPointer(src)) }

    /*==========================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that
    /// will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter srcData: the source data.
    ///
    public final func prepend(src: Data) { src.withUnsafeBytes { (b: UnsafeRawBufferPointer) in prepend(src: b) } }

    /*==========================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that
    /// will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter ezBuffer: the source data.
    ///
    public final func prepend(src b: EasyByteBuffer, reset: Bool = true) {
        b.withBytes { (bytes: ByteROPointer, count: inout Int) -> Void in
            if count > 0 {
                prepend(src: bytes, length: count)
                if reset { count = 0 }
            }
        }
    }

    /*==========================================================================================================*/
    /// Get's the data one contiguous range at a time.
    ///
    /// - Parameter body: the closure to call for each block of data.
    /// - Returns: The bytes read.
    /// - Throws: Any error thrown by the closure.
    ///
    public final func forEachContiguousRange(_ body: (ByteROPointer, Int) throws -> Int) throws -> Int {
        let b: BytePointer = buffer.pointee.buffer!
        let h: Int         = buffer.pointee.head
        let t: Int         = buffer.pointee.tail
        let s: Int         = buffer.pointee.size

        if h < t {
            return try forContiguousRange(buff: b, head: h, size: s, length: (t - h), body)
        }
        else if h > t {
            let l:  Int = (s - h)
            var cc: Int = try forContiguousRange(buff: b, head: h, size: s, length: l, body)
            if cc == l { cc += try forContiguousRange(buff: b, head: 0, size: s, length: t, body) }
            return cc
        }

        return 0
    }

    private func forContiguousRange(buff: BytePointer, head: Int, size: Int, length: Int, _ body: (ByteROPointer, Int) throws -> Int) rethrows -> Int {
        let cc: Int = max(0, min(try body((buff + head), length), length))
        buffer.pointee.head = ((head + cc) % size)
        return cc
    }

    /*==========================================================================================================*/
    /// Swap every 2 bytes of data.
    ///
    /// - Returns: The number of bytes swapped.
    ///
    public final func swapEndian16() -> Int { PGSwapRingBufferEndian16(buffer) }

    /*==========================================================================================================*/
    /// Swap every 4 bytes of data.
    ///
    /// - Returns: The number of bytes swapped.
    ///
    public final func swapEndian32() -> Int { PGSwapRingBufferEndian32(buffer) }

    /*==========================================================================================================*/
    /// Swap every 8 bytes of data.
    ///
    /// - Returns: The number of bytes swapped.
    ///
    public final func swapEndian64() -> Int { PGSwapRingBufferEndian64(buffer) }
}
