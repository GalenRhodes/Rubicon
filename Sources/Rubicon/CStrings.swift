/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: CStrings.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/18/20
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

/*==============================================================================================================*/
/// This is a class to help with the conversion between C strings and the Swift
/// <code>[String](https://developer.apple.com/documentation/swift/string/)</code> class. One note about the use
/// of signed and unsigned chars. Some C functions make a distinction between a signed char (usually the default -
/// when only the lower 7-bits are significant) and an unsigned char (usually in conjunction with the UTF-8
/// character encoding scheme). This class has methods to handle both.
///
open class CString {

    /*==========================================================================================================*/
    /// internal buffer.
    ///
    let cString: CCharBuffer

    /*==========================================================================================================*/
    /// The character encoding of the string.
    ///
    public let encoding: String.Encoding

    /*==========================================================================================================*/
    /// The C string converted to a Swift
    /// <code>[String](https://developer.apple.com/documentation/swift/string/)</code>. If the string cannot be
    /// decoded using the provided encoding then this field will be `nil`.
    ///
    public var string: String? {
        cString.withMemoryRebound(to: UInt8.self) { (p: UnsafeMutableBufferPointer<UInt8>) in
            String(bytes: p, encoding: encoding)
        }
    }

    /*==========================================================================================================*/
    /// Initialize this object with the given Swift
    /// <code>[String](https://developer.apple.com/documentation/swift/string/)</code>. The characters of the
    /// <code>[String](https://developer.apple.com/documentation/swift/string/)</code> will be encoded as a series
    /// of UTF-8 bytes.
    /// 
    /// - Parameter string: the string.
    ///
    public init(string: String) {
        cString = cString001(string)
        encoding = String.Encoding.utf8
    }

    /*==========================================================================================================*/
    /// Initialize this object as an empty string with the UTF-8 encoding.
    ///
    public convenience init() {
        self.init(string: "")
    }

    /*==========================================================================================================*/
    /// Initialize this object with the contents of the byte (unsigned char) buffer. The bytes will be interpreted
    /// as a series of characters encoded with the given character encoding.
    /// 
    /// - Parameters:
    ///   - byteBuffer: the byte buffer.
    ///   - hasNullTerminator: `true` if the buffer includes a `nil` terminating character. Defaults to `false`.
    ///   - encoding: the character encoding used. Defaults to UTF-8.
    ///
    public init(byteBuffer: UnsafeBufferPointer<UInt8>, hasNullTerminator: Bool = false, encoding: String.Encoding = String.Encoding.utf8) {
        cString = cString002(byteBuffer, hasNullTerminator)
        self.encoding = encoding
    }

    /*==========================================================================================================*/
    /// Initialize this object with the contents of the character (signed char) buffer. The characters will be
    /// interpreted as a series of characters encoded with the given character encoding.
    /// 
    /// - Parameters:
    ///   - charBuffer: the character buffer.
    ///   - hasNullTerminator: `true` if the buffer includes a `nil` terminating character. Defaults to `false`.
    ///   - encoding: the character encoding used. Defaults to UTF-8.
    ///
    public init(charBuffer: UnsafeBufferPointer<CChar>, hasNullTerminator: Bool = false, encoding: String.Encoding = String.Encoding.utf8) {
        cString = cString003(charBuffer, hasNullTerminator)
        self.encoding = encoding
    }

    /*==========================================================================================================*/
    /// Initializes this object with the contents of the immutable character (signed char) from the given pointer.
    /// If length is not given or is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the
    /// string MUST be `nil` terminated. If the length is less than
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> and the string is NOT `nil` terminated then the
    /// behavior of this initializer is undefined.
    /// 
    /// - Parameters:
    ///   - cString: the pointer to the characters.
    ///   - length: the length of the string. If less than <code>[zero](https://en.wikipedia.org/wiki/0)</code>
    ///             then the string MUST be `nil` terminated.
    ///   - encoding: the character encoding used. Defaults to UTF-8.
    ///
    public init(cString: UnsafePointer<CChar>, length: Int = -1, encoding: String.Encoding = String.Encoding.utf8) {
        let length:   Int            = (cStrLen(cStringPtr: cString, length: fixLength(length)) + 1)
        let mcString: CCharROPointer = cString

        self.cString = CCharBuffer(start: UnsafeMutablePointer(mutating: mcString), count: length)
        self.cString[length] = 0
        self.encoding = encoding
    }

    /*==========================================================================================================*/
    /// Initializes this object with the contents of the mutable character (signed char) from the given pointer.
    /// If length is not given or is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the
    /// string MUST be `nil` terminated. If the length is less than
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> and the string is NOT `nil` terminated then the
    /// behavior of this initializer is undefined.
    /// 
    /// - Parameters:
    ///   - cString: the pointer to the characters.
    ///   - length: the length of the string. If less than <code>[zero](https://en.wikipedia.org/wiki/0)</code>
    ///             then the string MUST be `nil` terminated.
    ///   - encoding: the character encoding used. Defaults to UTF-8.
    ///
    public init(cString: UnsafeMutablePointer<CChar>, length: Int = -1, encoding: String.Encoding = String.Encoding.utf8) {
        let length: Int = (cStrLen(cStringPtr: cString, length: fixLength(length)) + 1)
        self.cString = CCharBuffer(start: cString, count: length)
        self.cString[length] = 0
        self.encoding = encoding
    }

    /*==========================================================================================================*/
    /// Initializes this object with the contents of the immutable bytes (unsigned char) from the given pointer.
    /// If length is not given or is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the
    /// string MUST be `nil` terminated. If the length is less than
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> and the string is NOT `nil` terminated then the
    /// behavior of this initializer is undefined.
    /// 
    /// - Parameters:
    ///   - cString: the pointer to the bytes.
    ///   - length: the length of the string. If less than <code>[zero](https://en.wikipedia.org/wiki/0)</code>
    ///             then the string MUST be `nil` terminated.
    ///   - encoding: the character encoding used. Defaults to UTF-8.
    ///
    public init(utf8String: ByteROPointer, length: Int = -1, encoding: String.Encoding = String.Encoding.utf8) {
        let length: Int = (cStrLen(cStringPtr: utf8String) + 1)
        let s: CCharBuffer = utf8String.withMemoryRebound(to: CChar.self, capacity: length) { (p: CCharROPointer) -> CCharBuffer in
            let p2: CCharROPointer = p
            return CCharBuffer(start: UnsafeMutablePointer(mutating: p2), count: length)
        }
        self.cString = s
        self.cString[length] = 0
        self.encoding = encoding
    }

    /*==========================================================================================================*/
    /// Initializes this object with the contents of the mutable bytes (unsigned char) from the given pointer. If
    /// length is not given or is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then the string
    /// MUST be `nil` terminated. If the length is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code>
    /// and the string is NOT `nil` terminated then the behavior of this initializer is undefined.
    /// 
    /// - Parameters:
    ///   - cString: the pointer to the bytes.
    ///   - length: the length of the string. If less than <code>[zero](https://en.wikipedia.org/wiki/0)</code>
    ///             then the string MUST be `nil` terminated.
    ///   - encoding: the character encoding used. Defaults to UTF-8.
    ///
    public init(utf8String: BytePointer, length: Int = -1, encoding: String.Encoding = String.Encoding.utf8) {
        let length: Int = (cStrLen(cStringPtr: utf8String) + 1)
        let s: CCharBuffer = utf8String.withMemoryRebound(to: CChar.self, capacity: length) { (p: CCharPointer) -> CCharBuffer in
            CCharBuffer(start: p, count: length)
        }
        self.cString = s
        self.cString[length] = 0
        self.encoding = encoding
    }

    /*==========================================================================================================*/
    /// Used internally.
    /// 
    /// - Parameters:
    ///   - cString: the characters.
    ///   - length: the number of characters.
    ///   - encoding: the encoding.
    ///
    init(_ cString: CCharPointer, length: Int, encoding: String.Encoding) {
        self.cString = CCharBuffer(start: cString, count: length + 1)
        self.encoding = encoding
    }

    deinit {
        cString.deallocate()
    }

    /*==========================================================================================================*/
    /// Execute the block with an
    /// <code>[UnsafeBufferPointer](https://developer.apple.com/documentation/swift/unsafebufferpointer/)</code>
    /// of <code>[Int8](https://developer.apple.com/documentation/swift/int8/)</code> characters.
    /// 
    /// - Parameter block: the block to execute.
    /// - Returns: the value returned by the block.
    /// - Throws: any error thrown by the block.
    ///
    public func withCString<T>(_ block: (UnsafeBufferPointer<CChar>) throws -> T) rethrows -> T {
        try block(UnsafeBufferPointer(cString))
    }

    /*==========================================================================================================*/
    /// Execute the block with an
    /// <code>[UnsafeBufferPointer](https://developer.apple.com/documentation/swift/unsafebufferpointer/)</code>
    /// of UTF-8 encoded characters.
    /// 
    /// - Parameter block: the block to execute.
    /// - Returns: the value returned by the block.
    /// - Throws: any error thrown by the block.
    ///
    public func withUTF8String<T>(_ block: (UnsafeBufferPointer<UInt8>) throws -> T) rethrows -> T {
        try cString.withMemoryRebound(to: UInt8.self) { (p: UnsafeMutableBufferPointer<UInt8>) in
            try block(UnsafeBufferPointer(p))
        }
    }

    /*==========================================================================================================*/
    /// Execute the block with an UnsafePointer of
    /// <code>[Int8](https://developer.apple.com/documentation/swift/int8/)</code> characters.
    /// 
    /// - Parameter block: the block to execute.
    /// - Returns: the value returned by the block.
    /// - Throws: any error thrown by the block.
    ///
    public func withNullTerminatedCString<T>(_ block: (UnsafePointer<CChar>, Int) throws -> T) rethrows -> T {
        if let p1: CCharPointer = cString.baseAddress {
            return try block(p1, cString.count - 1)
        }
        var nullChar: CChar = 0
        return try block(&nullChar, 0)
    }

    /*==========================================================================================================*/
    /// Execute the block with an UnsafePointer of UTF-8 characters.
    /// 
    /// - Parameter block: the block to execute.
    /// - Returns: the value returned by the block.
    /// - Throws: any error thrown by the block.
    ///
    public func withNullTerminatedUTF8String<T>(_ block: (ByteROPointer, Int) throws -> T) rethrows -> T {
        try cString.withMemoryRebound(to: UInt8.self) { (p1: ByteBuffer) in
            if let p2: BytePointer = p1.baseAddress {
                return try block(p2, cString.count - 1)
            }
            var nullByte: UInt8 = 0
            return try block(&nullByte, 0)
        }
    }

    /*==========================================================================================================*/
    /// Create a new CString and do something with it right away. So, for example, instead of having to do this:
    /// 
    /// <pre>
    ///    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
    ///    defer { buffer.deallocate() }
    ///    guard strerror_r(code, buffer, 255) == 0 else { return "Unknown Error: \(code)" }
    ///    let str = String(utf8String: buffer) ?? "Unknown Error: \(code)"
    /// </pre>
    /// 
    /// You can, instead, do this:
    /// 
    /// <pre>
    ///     let str = (CString.newUtf8BufferOf(length: 255) { ((strerror_r(code, $0, $1) == 0) ? strlen($0) : -1) })?.string ?? "Unknown Error: \(code)"
    /// </pre>
    /// 
    /// - Parameters:
    ///   - length: The length of the buffer to create NOT INCLUDING the `nil` terminator.
    ///   - block: the closure that will get executed. The buffer and it's length, NOT INCLUDING the `nil`
    ///            terminator, will be passed to the closure. Upon success the closure should return the actual
    ///            length of the C string in the buffer, NOT INCLUDING, the `nil` terminator. If there was an
    ///            error then the closure should return -1 to indicate that the buffer does not contain a valid C
    ///            string.
    /// - Returns: an instance of CString or `nil` if -1 was returned from the closure.
    ///
    public static func newUtf8BufferOf(length: Int, _ block: (BytePointer, Int) throws -> Int) -> CString? {
        newCCharBufferOf(length: length) { (p: UnsafeMutablePointer<CChar>, pLength: Int) in
            try p.withMemoryRebound(to: UInt8.self, capacity: pLength + 1) { (p2: BytePointer) in
                try block(p2, pLength)
            }
        }
    }

    /*==========================================================================================================*/
    /// Create a new CString and do something with it right away. So, for example, instead of having to do this:
    /// 
    /// <pre>
    ///    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
    ///    defer { buffer.deallocate() }
    ///    guard strerror_r(code, buffer, 255) == 0 else { return "Unknown Error: \(code)" }
    ///    let str = String(cString: buffer, encoding: String.Encoding.windowsCP1250) ?? "Unknown Error: \(code)"
    /// </pre>
    /// 
    /// You can, instead, do this:
    /// 
    /// <pre>
    ///     let str = (CString.newCCharBufferOf(length: 255, encoding: String.Encoding.windowsCP1250) { ((strerror_r(code, $0, $1) == 0) ? strlen($0) : -1) })?.string ?? "Unknown Error: \(code)"
    /// </pre>
    /// 
    /// - Parameters:
    ///   - length: The length of the buffer to create NOT INCLUDING the `nil` terminator.
    ///   - encoding: the encoding that the characters are expected to be in. Defaults to UTF-8.
    ///   - block: the closure that will get executed. The buffer and it's length, NOT INCLUDING the `nil`
    ///            terminator, will be passed to the closure. Upon success the closure should return the actual
    ///            length of the C string in the buffer, NOT INCLUDING, the `nil` terminator. If there was an
    ///            error then the closure should return -1 to indicate that the buffer does not contain a valid C
    ///            string.
    /// - Returns: an instance of CString or `nil` if -1 was returned from the closure.
    ///
    public static func newCCharBufferOf(length: Int, encoding: String.Encoding = String.Encoding.utf8, _ block: (UnsafeMutablePointer<CChar>, Int) throws -> Int) -> CString? {
        let length: Int         = ((length < 0) ? 0 : length)
        let buffer: CCharBuffer = CCharBuffer.allocate(capacity: length + 1)

        buffer.initialize(repeating: 0)
        defer {
            buffer.deallocate()
        }

        if let p: CCharPointer = buffer.baseAddress {
            do {
                let rLength: Int = try block(p, length)

                if rLength > 0 {
                    let cLength: Int = cStrLen(cStringPtr: p, length: min(rLength, length))
                    p[cLength] = 0
                    return CString(p, length: cLength, encoding: encoding)
                }
                else if rLength == 0 {
                    return CString(string: "")
                }
            }
            catch {
                /* Do Nothing */
            }
        }

        return nil
    }
}

func cString004() -> CCharBuffer {
    let cb: CCharBuffer = CCharBuffer.allocate(capacity: 1)
    cb.initialize(repeating: 0)
    return cb
}

func cString003(_ charBuffer: CCharROBuffer, _ hasNullTerminator: Bool) -> CCharBuffer {
    let p2c:  Int         = charBuffer.count
    let cstr: CCharBuffer = CCharBuffer.allocate(capacity: hasNullTerminator ? p2c : (p2c + 1))
    let _                 = cstr.initialize(from: charBuffer)
    if !hasNullTerminator {
        cstr[p2c] = 0
    }
    return cstr
}

func cString002(_ byteBuffer: ByteROBuffer, _ hasNullTerminator: Bool) -> CCharBuffer {
    byteBuffer.withMemoryRebound(to: CChar.self) { (p2: CCharROBuffer) in
        cString003(p2, hasNullTerminator)
    }
}

func cString001(_ string: String) -> CCharBuffer {
    string.utf8.withContiguousStorageIfAvailable({ (p1: ByteROBuffer) -> CCharBuffer in
        cString002(p1, false)
    }) ?? cString004()
}
