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
    case FileNotFound(description: String = "File not found.")
}

extension Stream {

    public var isEOF:          Bool { (streamStatus == .atEnd) }
    public var isInGoodStatus: Bool { Rubicon.value(streamStatus, isOneOf: .open, .opening, .reading, .writing) }

    /*==========================================================================================================*/
    /// Checks to see if the `streamStatus` is any of the given statuses.
    /// 
    /// - Parameter statuses: the list of statuses.
    /// - Returns: `true` if the current `streamStatus` is any of the given statuses.
    ///
    public func status(in statuses: Stream.Status...) -> Bool {
        let curr = streamStatus
        return statuses.contains { st in (st == curr) }
    }

    /*==========================================================================================================*/
    /// If the stream has not yet been opened, open it and wait for it to be fully open - `streamStatus` !=
    /// <code>[Stream](https://developer.apple.com/documentation/foundation/stream/)</code>.Status.opening`.
    ///
    public func fullyOpen() {
        if streamStatus == .notOpen { open() }
        while streamStatus == .opening {}
    }
}

extension InputStream {

    /*==========================================================================================================*/
    /// A better read function for
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD
    /// IS NOT THREAD SAFE!!!! This method reads from the stream in chunks so do not use this method while any
    /// other thread might be potentially reading from this stream at the same time or you will be missing data.
    /// 
    /// - Parameters:
    ///   - buffer: The buffer that will receive the bytes.
    ///   - maxLength: The maximum number of bytes to read.
    ///   - fully: `true` to keep reading until either maxLength or end-of-file is reached.
    /// - Returns: The total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if
    ///            `maxLength` is <code>[zero](https://en.wikipedia.org/wiki/0)</code>, the end-of-file has been
    ///            reached, the stream is closed, or the stream was never opened.
    /// - Throws: Any error reported by the input stream.
    ///
    public func read(to buffer: CCharPointer, maxLength: Int) throws -> Int {
        try read(to: UnsafeMutableRawPointer(buffer), maxLength: maxLength)
    }

    /*==========================================================================================================*/
    /// A better read function for
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD
    /// IS NOT THREAD SAFE!!!! This method reads from the stream in chunks so do not use this method while any
    /// other thread might be potentially reading from this stream at the same time or you will be missing data.
    /// 
    /// - Parameters:
    ///   - rawBuffer: The buffer that will receive the bytes.
    ///   - maxLength: The maximum number of bytes to read.
    ///   - fully: `true` to keep reading until either maxLength or end-of-file is reached.
    /// - Returns: The total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if
    ///            `maxLength` is <code>[zero](https://en.wikipedia.org/wiki/0)</code>, the end-of-file has been
    ///            reached, the stream is closed, or the stream was never opened.
    /// - Throws: Any error reported by the input stream.
    ///
    public func read(to rp: UnsafeMutableRawPointer, maxLength: Int) throws -> Int {
        guard maxLength > 0 else { return 0 }
        let p  = rp.bindMemory(to: UInt8.self, capacity: maxLength)
        var cc = 0

        while cc < maxLength {
            let rc = read((p + cc), maxLength: (maxLength - cc))
            guard rc > 0 else {
                guard rc == 0 else { throw streamError ?? StreamError.UnknownError() }
                break
            }
            cc += rc
        }

        return cc
    }

    /*==========================================================================================================*/
    /// A better read function for
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD
    /// IS NOT THREAD SAFE!!!! This method reads from the stream in chunks so do not use this method while any
    /// other thread might be potentially reading from this stream at the same time or you will be missing data.
    /// 
    /// - Parameters:
    ///   - data: The <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> to read the
    ///           bytes into.
    ///   - len: The maximum number of bytes to read or -1 to read all to the end-of-file.
    ///   - clr: `true` to clear the data buffer before reading or `false` to append read data to the existing
    ///          data.
    /// - Returns: The total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `len`
    ///            is <code>[zero](https://en.wikipedia.org/wiki/0)</code>, the end-of-file has been reached, the
    ///            stream is closed, or the stream was never opened.
    /// - Throws: Any error reported by the input stream.
    ///
    public func read(to data: inout Data, maxLength len: Int, truncate clr: Bool = true) throws -> Int {
        if clr { data.removeAll(keepingCapacity: true) }
        guard len != 0 else { return 0 }

        var cc = 0
        let mx = ((len < 0) ? (1024 * 1024) : len)
        let ln = ((len < 0) ? (Int.max) : len)
        let p  = UnsafeMutablePointer<UInt8>.allocate(capacity: min(mx, ln))

        defer { p.deallocate() }

        while cc < ln {
            let rc = read(p, maxLength: min(mx, (ln - cc)))
            guard rc > 0 else {
                guard rc == 0 else { throw streamError ?? StreamError.UnknownError() }
                break
            }
            cc += rc
            data.append(p, count: rc)
        }

        return cc
    }

    /*==========================================================================================================*/
    /// Read bytes into an instance of `EasyByteBuffer`. This method assumes that the `EasyByteBuffer.count` field
    /// is being used to store the number of bytes in the buffer. The newly read bytes will be appended to the end
    /// of the existing bytes, as denoted by the value in the `EasyByteBuffer.count` field. If
    /// `EasyByteBuffer.count` is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) or greater
    /// than `EasyByteBuffer.length` then a fatalError is thrown. If `EasyByteBuffer.count` is equal to
    /// `EasyByteBuffer.length` then this method returns immediately with the value
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
    /// 
    /// - Parameter b: the `EasyByteBuffer` that will be used to store the bytes read.
    /// - Returns: The number of bytes read into the buffer or
    ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) if the buffer is full or the stream it
    ///            at EOF or -1 if there was an I/O error.
    ///
    public func read(to b: MutableManagedByteBuffer) throws -> Int {
        guard b.count >= 0 && b.count <= b.length else { throw StreamError.UnknownError(description: "Invalid count in buffer.") }
        let cc = b.count

        while b.count < b.length {
            let f = try b.withBytes { bytes, length, count -> Bool in
                let rc = read(bytes + count, maxLength: (length - count))
                if rc < 0 { throw streamError ?? StreamError.UnknownError() }
                if rc == 0 { return false }
                count += rc
                return true
            }
            guard f else { break }
        }

        return (b.count - cc)
    }

    /*==========================================================================================================*/
    /// A better read function for
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD
    /// IS NOT THREAD SAFE!!!! This method reads from the stream in chunks so do not use this method while any
    /// other thread might be potentially reading from this stream at the same time or you will be missing data.
    /// 
    /// - Parameters:
    ///   - array: The <code>[Array](https://developer.apple.com/documentation/foundation/array/)</code> to read
    ///            the bytes into.
    ///   - len: The maximum number of bytes to read or -1 to read all to the end-of-file.
    ///   - clr: `true` to clear the data buffer before reading or `false` to append read data to the existing
    ///          data.
    /// - Returns: The total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `len`
    ///            is <code>[zero](https://en.wikipedia.org/wiki/0)</code>, the end-of-file has been reached, the
    ///            stream is closed, or the stream was never opened.
    /// - Throws: Any error reported by the input stream.
    ///
    public func read(to array: inout [UInt8], maxLength len: Int, truncate clr: Bool = true) throws -> Int {
        if clr { array.removeAll(keepingCapacity: true) }
        var data = Data()
        let cc   = try read(to: &data, maxLength: len, truncate: false)
        array.append(contentsOf: data)
        return cc
    }

    /*==========================================================================================================*/
    /// A better read function for
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream/)</code>. THIS METHOD
    /// IS NOT THREAD SAFE!!!! This method reads from the stream in chunks so do not use this method while any
    /// other thread might be potentially reading from this stream at the same time or you will be missing data.
    /// 
    /// - Parameter rbp: the
    ///                  <code>[UnsafeMutableRawBufferPointer](https://developer.apple.com/documentation/foundation/unsafemutablerawbufferpointer/)</code>
    ///                  to read the bytes into.
    /// - Returns: The total number of bytes read or <code>[zero](https://en.wikipedia.org/wiki/0)</code> if `len`
    ///            is <code>[zero](https://en.wikipedia.org/wiki/0)</code>, the end-of-file has been reached, the
    ///            stream is closed, or the stream was never opened.
    /// - Throws: Any error reported by the input stream.
    ///
    public func read(to rbp: UnsafeMutableRawBufferPointer) throws -> Int {
        guard let bp: UnsafeMutableRawPointer = rbp.baseAddress else { return 0 }
        return try read(to: bp, maxLength: rbp.count)
    }
}

extension OutputStream {
    public func write(from rbp: UnsafeRawBufferPointer, length: Int = -1) throws -> Int {
        guard let rp = rbp.baseAddress else { return 0 }
        return try write(from: rp, length: ((length < 0) ? rbp.count : min(rbp.count, length)))
    }

    public func write(from p: UnsafeRawPointer, length: Int) throws -> Int {
        guard length > 0 else { return 0 }
        let wc = write(p.bindMemory(to: UInt8.self, capacity: length), maxLength: length)
        guard wc >= 0 else { throw streamError ?? StreamError.UnknownError() }
        return wc
    }
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
            @unknown default: return "Unknown"
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

extension InputStream {
    public func read() throws -> UInt8? {
        var byte: UInt8 = 0
        let res:  Int   = read(&byte, maxLength: 1)
        guard res >= 0 else { throw streamError ?? StreamError.UnknownError() }
        guard res > 0 else { return nil }
        return byte
    }
}
