/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Buffers.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 8/24/20
 *
 * Copyright © 2020 ProjectGalen. All rights reserved.
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

//@f:0
public typealias CCharPointer   = UnsafeMutablePointer<CChar>
public typealias CCharBuffer    = UnsafeMutableBufferPointer<CChar>
public typealias CCharROPointer = UnsafePointer<CChar>
public typealias CCharROBuffer  = UnsafeBufferPointer<CChar>

public typealias BytePointer    = UnsafeMutablePointer<UInt8>
public typealias ByteBuffer     = UnsafeMutableBufferPointer<UInt8>
public typealias ByteROPointer  = UnsafePointer<UInt8>
public typealias ByteROBuffer   = UnsafeBufferPointer<UInt8>

public typealias WordPointer    = UnsafeMutablePointer<UInt16>
public typealias WordROPointer  = UnsafePointer<UInt16>
public typealias WordBuffer     = UnsafeMutableBufferPointer<UInt16>
public typealias WordROBuffer   = UnsafeBufferPointer<UInt16>

public typealias DWordPointer   = UnsafeMutablePointer<UInt32>
public typealias DWordROPointer = UnsafePointer<UInt32>
public typealias DWordBuffer    = UnsafeMutableBufferPointer<UInt32>
public typealias DWordROBuffer  = UnsafeBufferPointer<UInt32>

public typealias QWordPointer   = UnsafeMutablePointer<UInt64>
public typealias QWordROPointer = UnsafePointer<UInt64>
public typealias QWordBuffer    = UnsafeMutableBufferPointer<UInt64>
public typealias QWordROBuffer  = UnsafeBufferPointer<UInt64>
//@f:1

/*==============================================================================================================*/
/// Deinitialzies and deallocates an
/// <code>[UnsaveMutablePointer](https://developer.apple.com/documentation/swift/UnsaveMutablePointer)</code> in
/// one call.
/// 
/// - Parameters:
///   - buffer: the buffer to discard.
///   - count: the number of elements in the buffer to deinitialize.
///
public func discardMutablePointer<T>(_ buffer: UnsafeMutablePointer<T>, _ count: Int = 1) {
    buffer.deinitialize(count: count)
    buffer.deallocate()
}

public func discardMutableRawPointer<T>(_ buffer: UnsafeMutableRawPointer, _ type: T.Type, _ count: Int) {
    buffer.bindMemory(to: type, capacity: count).deinitialize(count: count)
    buffer.deallocate()
}

public func createMutablePointer<T>(capacity: Int, initialValue: T) -> UnsafeMutablePointer<T> {
    let buffer: UnsafeMutablePointer<T> = UnsafeMutablePointer<T>.allocate(capacity: BasicBufferSize)
    buffer.initialize(repeating: initialValue, count: BasicBufferSize)
    return buffer
}

public func createMutablePointer<T: BinaryInteger>(capacity: Int) -> UnsafeMutablePointer<T> {
    let buffer: UnsafeMutablePointer<T> = UnsafeMutablePointer<T>.allocate(capacity: capacity)
    buffer.initialize(repeating: 0, count: capacity)
    return buffer
}

public func createMutableRawPointer<T>(capacity: Int, type: T.Type, initialValue: T) -> UnsafeMutableRawPointer {
    let buffer: UnsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: capacity * MemoryLayout<T>.stride, alignment: MemoryLayout<T>.alignment)
    buffer.initializeMemory(as: type, repeating: initialValue, count: capacity)
    return buffer
}

public func createMutableRawPointer<T: BinaryInteger>(capacity: Int, type: T.Type) -> UnsafeMutableRawPointer {
    createMutableRawPointer(capacity: capacity, type: type, initialValue: 0)
}
