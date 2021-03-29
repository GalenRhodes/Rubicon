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

@usableFromInline let OneMB:  Int = (1024 * 1024)
@usableFromInline let HalfGB: Int = (OneMB * 512)

/*===============================================================================================================================================================================*/
/// This class is a simple wrapper around a <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> object that allows for treating the data like a stream
/// of bytes. The three basic operations are `get(buffer:maxLength:)`, `append(buffer:length:)`, and `prepend(buffer:length:)`.
///
/// NOTE: This class is NOT thread safe.
///
open class RingByteBuffer {

    /*===========================================================================================================================================================================*/
    /// The ring buffer.
    ///
    @usableFromInline let buffer: UnsafeMutablePointer<PGRingBuffer>

    /*===========================================================================================================================================================================*/
    /// The number of bytes in the available.
    ///
    open var available:         Int {
        PGRingBufferCount(buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Returns `true` if there are bytes in the ring buffer.
    ///
    open var hasBytesAvailable: Bool {
        (PGRingBufferCount(buffer) > 0)
    }

    /*===========================================================================================================================================================================*/
    /// The total capacity of the buffer.
    ///
    open var capacity:          Int {
        PGRingBufferCapacity(buffer)
    }

    /*===========================================================================================================================================================================*/
    /// The room in the buffer for new bytes.
    ///
    open var headroom:          Int {
        PGRingBufferRemaining(buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Returns `true` if the buffer is empty.
    ///
    open var isEmpty:           Bool {
        (PGRingBufferCount(buffer) == 0)
    }

    /*===========================================================================================================================================================================*/
    /// Creates a new instance of `ByteBuffer`.
    /// - Parameter initialCapacity: the initial capacity of the buffer.
    ///
    public init(initialCapacity: Int = BasicBufferSize) {
        buffer = PGCreateRingBuffer(initialCapacity)
    }

    deinit {
        PGDiscardRingBuffer(buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Clear the buffer.
    ///
    /// - Parameter keepingCapacity: `true` if the capacity should be retained. `false` if the buffer should shrink to it's original size.
    ///
    open func clear(keepingCapacity: Bool) {
        PGClearRingBuffer(buffer, keepingCapacity)
    }

    /*===========================================================================================================================================================================*/
    /// Read a byte from the buffer.
    ///
    /// - Parameter byte: a pointer to the variable to receive the byte.
    /// - Returns: `true` if the byte was retrived or `false` if the buffer was empty.
    ///
    open func get(byte: inout UInt8) -> Bool {
        (PGReadFromRingBuffer(buffer, &byte, 1) == 1)
    }

    /*===========================================================================================================================================================================*/
    /// Read a byte from the buffer.
    ///
    /// - Returns: the next byte or `nil` if the buffer is empty.
    ///
    open func get() -> UInt8? {
        var byte: UInt8 = 0
        return ((PGReadFromRingBuffer(buffer, &byte, 1) == 1) ? byte : nil)
    }

    /*===========================================================================================================================================================================*/
    /// Get, at most, the first `maxLength` bytes from the buffer.
    ///
    /// - Parameters:
    ///   - dest: the destination buffer.
    ///   - maxLength: the maximum number of bytes the destination buffer can hold.
    ///
    /// - Returns: the number of bytes actually gotten.
    ///
    open func get(dest: BytePointer, maxLength: Int) -> Int {
        PGReadFromRingBuffer(buffer, dest, maxLength)
    }

    /*===========================================================================================================================================================================*/
    /// Get the bytes from the buffer.
    ///
    /// - Parameters:
    ///   - destData: The instance of <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> that will receive the bytes.
    ///   - maxLength: The maximum number of bytes to get. If -1 then all available bytes will be fetched.
    ///   - overWrite: `true` if `destData` should be cleared of any existing bytes first.
    ///
    /// - Returns: The number of bytes added to `destData`.
    ///
    open func get(destData: inout Data, maxLength: Int = -1, overWrite: Bool = true) -> Int {
        if overWrite {
            destData.removeAll(keepingCapacity: true)
        }

        let mx: Int = min(available, ((maxLength < 0) ? Int.max : maxLength))
        var cc: Int = 0

        if mx > 0 {
            let bLen: Int         = min(mx, 1024)
            let buff: BytePointer = BytePointer.allocate(capacity: bLen)

            defer { buff.deallocate() }
            while (cc < mx) && (available > 0) {
                let x: Int = PGReadFromRingBuffer(buffer, buff, min(bLen, (mx - cc)))
                cc += x
                destData.append(buff, count: x)
            }
        }

        return cc
    }

    /*===========================================================================================================================================================================*/
    /// Append the given RingByteBuffer to this RingByteBuffer.
    ///
    /// - Parameter ringBuffer: the source ring buffer.
    ///
    public final func append(ringBuffer: RingByteBuffer) {
        PGAppendRingBufferToRingBuffer(buffer, ringBuffer.buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given RingByteBuffer to this RingByteBuffer.
    ///
    /// - Parameter ringBuffer: the source ring buffer.
    ///
    public final func prepend(ringBuffer: RingByteBuffer) {
        PGPrependRingBufferToRingBuffer(buffer, ringBuffer.buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Append the given byte to the buffer.
    ///
    /// - Parameter byte: the byte to append.
    ///
    open func append(byte: UInt8) {
        PGAppendByteToRingBuffer(buffer, byte)
    }

    /*===========================================================================================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameters:
    ///   - src: the source buffer.
    ///   - length: the number of bytes in the source buffer.
    ///
    open func append<T>(src: UnsafePointer<T>, length: Int) {
        append(rawSrc: UnsafeRawPointer(src), length: length)
    }

    /*===========================================================================================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameters:
    ///   - rawSrc: the source buffer.
    ///   - length: the number of bytes in the source buffer.
    ///
    open func append(rawSrc: UnsafeRawPointer, length: Int) {
        if length > 0 {
            PGAppendToRingBuffer(buffer, rawSrc, length)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameter buffSrc: the source buffer.
    ///
    open func append<T>(buffSrc: UnsafeBufferPointer<T>) {
        append(rawBuffSrc: UnsafeRawBufferPointer(buffSrc))
    }

    /*===========================================================================================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameter rawBuffSrc: the source buffer.
    ///
    open func append(rawBuffSrc: UnsafeRawBufferPointer) {
        if let bp: UnsafeRawPointer = rawBuffSrc.baseAddress {
            append(rawSrc: bp, length: rawBuffSrc.count)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Append the given bytes to the buffer.
    ///
    /// - Parameter dataSrc: the source data.
    ///
    open func append(dataSrc: Data) {
        dataSrc.withUnsafeBytes { (p: UnsafeRawBufferPointer) in append(rawBuffSrc: p) }
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given byte to the buffer. This byte will be prepended so that it is the next byte that will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameters:
    ///   - byte: the byte to prepend.
    ///
    open func prepend(byte: UInt8) {
        PGPrependByteToRingBuffer(buffer, byte)
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameters:
    ///   - rawSrc: the source buffer.
    ///   - length: the number of bytes in the source buffer.
    ///
    open func prepend(rawSrc: UnsafeRawPointer, length: Int) {
        if length > 0 {
            PGPrependToRingBuffer(buffer, rawSrc.bindMemory(to: UInt8.self, capacity: length), length)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameters:
    ///   - src: the source buffer.
    ///   - length: the number of bytes in the source buffer.
    ///
    open func prepend<T>(src: UnsafePointer<T>, length: Int) {
        prepend(rawSrc: UnsafeRawPointer(src), length: length)
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter rawBuffSrc: the source buffer.
    ///
    open func prepend(rawBuffSrc: UnsafeRawBufferPointer) {
        if let pointer: UnsafeRawPointer = rawBuffSrc.baseAddress {
            prepend(rawSrc: pointer, length: rawBuffSrc.count)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter buffSrc: the source buffer.
    ///
    open func prepend<T>(buffSrc: UnsafeBufferPointer<T>) {
        prepend(rawBuffSrc: UnsafeRawBufferPointer(buffSrc))
    }

    /*===========================================================================================================================================================================*/
    /// Prepend the given bytes to the buffer. These bytes will be prepended so that they are the next bytes that will be read via `get(buffer:maxLength:)`.
    ///
    /// - Parameter srcData: the source data.
    ///
    open func prepend(srcData: Data) {
        srcData.withUnsafeBytes { (b: UnsafeRawBufferPointer) in prepend(rawBuffSrc: b) }
    }

    /*===========================================================================================================================================================================*/
    /// Get's the data one contiguous range at a time.
    ///
    /// - Parameter body: the closure to call for each block of data.
    /// - Returns: the bytes read.
    /// - Throws: any error thrown by the closure.
    ///
    open func forEachContiguousRange(_ body: (ByteROPointer, Int) throws -> Int) throws -> Int {
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

            if cc == l {
                cc += try forContiguousRange(buff: b, head: 0, size: s, length: t, body)
            }

            return cc
        }

        return 0
    }

    private func forContiguousRange(buff: BytePointer, head: Int, size: Int, length: Int, _ body: (ByteROPointer, Int) throws -> Int) rethrows -> Int {
        let cc: Int = max(0, min(try body((buff + head), length), length))
        buffer.pointee.head = ((head + cc) % size)
        return cc
    }

    /*===========================================================================================================================================================================*/
    /// Append up to maxLength bytes from the input stream to this ring buffer.
    ///
    /// - Parameters:
    ///   - inputStream: the input stream.
    ///   - len: the maximum number of bytes to read.
    /// - Returns: the number of bytes actually read.
    /// - Throws: if an I/O error occurs.
    ///
    @discardableResult open func append(from inputStream: InputStream, maxLength len: Int) throws -> Int {
        let count: Int = ((len < 0) ? Int.max : len)
        guard count > 0 else { return 0 }

        if inputStream.streamStatus == .notOpen {
            inputStream.open()
            while inputStream.streamStatus == .opening {}
        }

        guard inputStream.hasBytesAvailable else { return 0 }
        return try ((count > HalfGB) ? append1(inputStream, maxLength: count) : append2(inputStream, maxLength: count))
    }

    @inlinable final func append1(_ inputStream: InputStream, maxLength count: Int) throws -> Int {
        let bf = EasyByteBuffer(length: OneMB)
        var rs = try inputStream.read(to: bf.bytes, maxLength: bf.length)

        while bf.count < count && rs > 0 {
            append(src: bf.bytes, length: rs)
            bf.count += rs
            rs = try inputStream.read(to: bf.bytes, maxLength: bf.length)
        }

        return bf.count
    }

    @inlinable final func append2(_ inputStream: InputStream, maxLength len: Int) throws -> Int {
        guard PGEnsureCapacity(buffer, len) else { return 0 }
        let t = buffer.pointee.tail
        let h = buffer.pointee.head
        let s = buffer.pointee.size

        if h == t { // If buffer is empty.
            buffer.pointee.head = 0
            buffer.pointee.tail = 0
            return try append3(inputStream, maxLength: min(len, (s - 1)))
        }
        else if t < h { // If the data is wrapped.
            return try append3(inputStream, maxLength: min(len, (h - t - 1)))
        }
        else if h == 0 { // If the data is NOT wrapped but starts at the beginning of the buffer.
            return try append3(inputStream, maxLength: min(len, (s - t - 1)))
        }
        else { // If the data is NOT wrapped and does not start at the beginning of the buffer.
            let i  = (s - t)
            let j  = min(len, i)
            let cc = try append3(inputStream, maxLength: j)
            return try (((cc < len) && (cc == j)) ? (cc + append3(inputStream, maxLength: min((len - cc), (h - 1)))) : cc)
        }
    }

    @inlinable final func append3(_ inputStream: InputStream, maxLength len: Int) throws -> Int {
        let t  = buffer.pointee.tail
        let s  = buffer.pointee.size
        let rs = try inputStream.read(to: (buffer.pointee.buffer + t), maxLength: len)
        buffer.pointee.tail = ((t + rs) % s)
        return rs
    }

    /*===========================================================================================================================================================================*/
    /// Swap every 2 bytes of data.
    ///
    /// - Returns: the number of bytes swapped.
    ///
    open func swapEndian16() -> Int {
        PGSwapRingBufferEndian16(buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Swap every 4 bytes of data.
    ///
    /// - Returns: the number of bytes swapped.
    ///
    open func swapEndian32() -> Int {
        PGSwapRingBufferEndian32(buffer)
    }

    /*===========================================================================================================================================================================*/
    /// Swap every 8 bytes of data.
    ///
    /// - Returns: the number of bytes swapped.
    ///
    open func swapEndian64() -> Int {
        PGSwapRingBufferEndian64(buffer)
    }
}
