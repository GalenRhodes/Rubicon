/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Extensions.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 7/27/20
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

public extension Data {

    /*==========================================================================================================*/
    /// Allows creating of a <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code>
    /// struct from an <code>[input
    /// stream](https://developer.apple.com/documentation/foundation/inputstream)</code>.
    ///
    /// - Parameter inputStream: the <code>[input
    ///                          stream](https://developer.apple.com/documentation/foundation/inputstream)</code>.
    ///
    init?(inputStream: InputStream) {
        do {
            defer { inputStream.close() }
            var data: Data = Data()
            if inputStream.streamStatus == .notOpen { inputStream.open() }
            let _ = try inputStream.read(to: &data, maxLength: -1)
            self.init(data)
        }
        catch {
            return nil
        }
    }

    /*==========================================================================================================*/
    /// For some reason `withUnsafeMutableBytes<T>(block:)` was deprecated on the grounds that the
    /// [Data](https://developer.apple.com/documentation/foundation/data/) object could have a
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> length.
    ///
    /// - Parameter block: the closure.
    /// - Returns: The results of executing the closure.
    /// - Throws: Any exception thrown by the closure.
    ///
    @discardableResult mutating func withUnsafeMutableBytes2<T>(_ block: (BytePointer) throws -> T) rethrows -> T {
        try withUnsafeMutableBytes { (ptr1: UnsafeMutableRawBufferPointer) in
            if let ptr3: BytePointer = ptr1.bindMemory(to: UInt8.self).baseAddress {
                return try block(ptr3)
            }
            var i: UInt8 = 0
            return try block(&i)
        }
    }

    /*==========================================================================================================*/
    /// For some reason `withUnsafeBytes<T>(block:)` was deprecated on the grounds that the
    /// [Data](https://developer.apple.com/documentation/foundation/data/) object could have a
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> length.
    ///
    /// - Parameter block: the closure.
    /// - Returns: The results of executing the closure.
    /// - Throws: Any exception thrown by the closure.
    ///
    @discardableResult func withUnsafeBytes2<T>(_ block: (ByteROPointer) throws -> T) rethrows -> T {
        try withUnsafeBytes { (ptr1: UnsafeRawBufferPointer) in
            if let ptr2: ByteROPointer = ptr1.bindMemory(to: UInt8.self).baseAddress {
                return try block(ptr2)
            }
            var i: UInt8 = 0
            return try block(&i)
        }
    }
}
