/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Stream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/3/20
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

public enum StreamError: Error {
    case UnexpectedEndOfInput(description: String = "Unexpected EOF.")
    case UnknownError(description: String = "Unknown I/O Error")
    case NoMark(description: String = "No previous mark to release.")
    case Closed(description: String = "The stream has been closed.")
    case NotOpen(description: String = "The stream is not open.")
}

@inlinable public func streamStatusGood(_ st: Stream.Status) -> Bool { value(st, isOneOf: .open, .opening, .reading, .writing) }

extension Stream {

    @inlinable public var isEof:        Bool { status(in: .atEnd, .closed, .error) }
    @inlinable public var isError:      Bool { (streamStatus == .error) }
    @inlinable public var isOpen:       Bool { !status(in: .notOpen, .closed) }

    /*===========================================================================================================================================================================*/
    /// Returns `true` if the stream is open and not in an error state.
    ///
    @inlinable public var inGoodStatus: Bool { isOpen && !isEof }

    /*===========================================================================================================================================================================*/
    /// Checks to see if the `streamStatus` is any of the given statuses.
    ///
    /// - Parameter statuses: the list of statuses.
    /// - Returns: `true` if the current `streamStatus` is any of the given statuses.
    ///
    @inlinable public func status(in statuses: Stream.Status...) -> Bool {
        let curr = streamStatus
        return statuses.contains { st in (st == curr) }
    }

    /*===========================================================================================================================================================================*/
    /// If the stream has not yet been opened, open it and wait for it to be fully open - `streamStatus` !=
    /// <code>[Stream](https://developer.apple.com/documentation/foundation/stream/)</code>.Status.opening`.
    ///
    @inlinable public func fullyOpen() {
        if streamStatus == .notOpen { open() }
        while streamStatus == .opening {}
    }
}

extension InputStream {

    /*===========================================================================================================================================================================*/
    /// A better read function for <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD IS NOT THREAD SAFE!!!! This method
    /// reads from the stream in chunks so do not use this method while any other thread might be potentially reading from this stream at the same time or you will be missing
    /// data.
    ///
    /// - Parameters:
    ///   - buffer: the buffer that will receive the bytes.
    ///   - maxLength: the maximum number of bytes to read.
    ///   - fully: `true` to keep reading until either maxLength or end-of-file is reached.
    /// - Returns: the total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `maxLength` is <code>[zero](https://en.wikipedia.org/wiki/0)</code>,
    ///            the end-of-file has been reached, the stream is closed, or the stream was never opened.
    /// - Throws: any error reported by the input stream.
    ///
    public func read(to buffer: BytePointer, maxLength: Int) throws -> Int {
        try read(to: UnsafeMutableRawPointer(buffer), maxLength: maxLength)
    }

    /*===========================================================================================================================================================================*/
    /// A better read function for <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD IS NOT THREAD SAFE!!!! This method
    /// reads from the stream in chunks so do not use this method while any other thread might be potentially reading from this stream at the same time or you will be missing
    /// data.
    ///
    /// - Parameters:
    ///   - buffer: the buffer that will receive the bytes.
    ///   - maxLength: the maximum number of bytes to read.
    ///   - fully: `true` to keep reading until either maxLength or end-of-file is reached.
    /// - Returns: the total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `maxLength` is <code>[zero](https://en.wikipedia.org/wiki/0)</code>,
    ///            the end-of-file has been reached, the stream is closed, or the stream was never opened.
    /// - Throws: any error reported by the input stream.
    ///
    public func read(to buffer: CCharPointer, maxLength: Int) throws -> Int {
        try read(to: UnsafeMutableRawPointer(buffer), maxLength: maxLength)
    }

    /*===========================================================================================================================================================================*/
    /// A better read function for <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD IS NOT THREAD SAFE!!!! This method
    /// reads from the stream in chunks so do not use this method while any other thread might be potentially reading from this stream at the same time or you will be missing
    /// data.
    ///
    /// - Parameters:
    ///   - rawBuffer: the buffer that will receive the bytes.
    ///   - maxLength: the maximum number of bytes to read.
    ///   - fully: `true` to keep reading until either maxLength or end-of-file is reached.
    /// - Returns: the total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `maxLength` is <code>[zero](https://en.wikipedia.org/wiki/0)</code>,
    ///            the end-of-file has been reached, the stream is closed, or the stream was never opened.
    /// - Throws: any error reported by the input stream.
    ///
    public func read(to rawBuffer: UnsafeMutableRawPointer, maxLength: Int) throws -> Int {
        guard maxLength > 0 else { return 0 }
        return try readStream(inputStream: self, maxLength: maxLength) { (buf: UnsafeRawPointer, cc: Int, count: Int) in
            rawBuffer.advanced(by: cc).copyMemory(from: buf, byteCount: count)
        }
    }

    /*===========================================================================================================================================================================*/
    /// A better read function for <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD IS NOT THREAD SAFE!!!! This method
    /// reads from the stream in chunks so do not use this method while any other thread might be potentially reading from this stream at the same time or you will be missing
    /// data.
    ///
    /// - Parameters:
    ///   - data: the <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> to read the bytes into.
    ///   - maxLength: the maximum number of bytes to read or -1 to read all to the end-of-file.
    ///   - fully: `true` to keep reading until either maxLength or end-of-file is reached.
    ///   - truncate: `true` to clear the data buffer before reading or `false` to append read data to the existing data.
    /// - Returns: the total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `maxLength` is <code>[zero](https://en.wikipedia.org/wiki/0)</code>,
    ///            the end-of-file has been reached, the stream is closed, or the stream was never opened.
    /// - Throws: any error reported by the input stream.
    ///
    public func read(to data: inout Data, maxLength: Int, truncate: Bool = true) throws -> Int {
        if truncate { data.removeAll(keepingCapacity: true) }
        return try readStream(inputStream: self, maxLength: maxLength) { (p, _, count) in
            data.append(p.assumingMemoryBound(to: UInt8.self), count: count)
        }
    }
}

func readStream(inputStream: InputStream, maxLength: Int, body: (UnsafeRawPointer, Int, Int) throws -> Void) throws -> Int {
    guard maxLength != 0 else { return 0 }
    var bytesRead: Int         = 0
    let maxLength: Int         = fixLength(maxLength)
    let bSize:     Int         = min(maxLength, BasicBufferSize)
    let buffer:    BytePointer = BytePointer.allocate(capacity: bSize)

    defer { buffer.deallocate() }

    repeat {
        let result: Int = inputStream.read(buffer, maxLength: min((maxLength - bytesRead), bSize))
        if result < 0 { throw inputStream.streamError ?? StreamError.UnknownError() }
        if result == 0 { return bytesRead }
        try body(buffer, bytesRead, result)
        bytesRead += result
    }
    while (bytesRead < maxLength)

    return bytesRead
}

extension Stream.Status: CustomStringConvertible {
    public var description: String {
        switch self {
            case .notOpen: return "Not Open"
            case .opening: return "Opening"
            case .open:    return "Open"
            case .reading: return "Reading"
            case .writing: return "Writing"
            case .atEnd:   return "EOF"
            case .closed:  return "Closed"
            case .error:   return "Error"
            @unknown default:
                return "Unknown"
        }
    }
}

extension Stream.Event: CustomStringConvertible {
    public var description: String {
        switch self {
            case .openCompleted:     return "Open Completed"
            case .endEncountered:    return "End Encountered"
            case .errorOccurred:     return "Error Occurred"
            case .hasBytesAvailable: return "Has Bytes Available"
            case .hasSpaceAvailable: return "Has Space Available"
            default:                 return "Unknown Event"
        }
    }
}
