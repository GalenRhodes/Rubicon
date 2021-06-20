/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: MarkReleaseInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/7/20
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
import CoreFoundation

let InputBufferSize:    Int = 1_024                          //  1KB
let MaxInputBufferSize: Int = 65_536                         // 64KB
let ReadBufferSize:     Int = 4_096                          //  4KB

/*==============================================================================================================*/
/// An <code>[input stream](https://developer.apple.com/documentation/foundation/inputstream)</code> that you can
/// mark places in with a call to `markSet()` and to return to with a call to `markRelease()`.
///
open class MarkInputStream: InputStream {
    //@f:0
    /*==========================================================================================================*/
    /// A Boolean value that indicates whether the receiver has bytes available to read. `true` if the receiver
    /// has bytes available to read, otherwise `false`. May also return `true` if a read must be attempted in
    /// order to determine the availability of bytes.
    ///
    open override var hasBytesAvailable: Bool                         { lock.withLock { (effStatus == .open)                  } }
    /*==========================================================================================================*/
    /// Returns the receiver’s status.
    ///
    open override var streamStatus:      Stream.Status                { lock.withLock { effStatus                             } }
    /*==========================================================================================================*/
    /// Returns an NSError object representing the stream error.
    ///
    open override var streamError:       Error?                       { lock.withLock { ((effStatus == .error) ? error : nil) } }
    /*==========================================================================================================*/
    /// The number of marked positions for this stream.
    ///
    open          var markCount:         Int                          { lock.withLock { mstk.count                            } }

    private       var buffer:            RingByteBuffer               = RingByteBuffer(initialCapacity: InputBufferSize)
    private       var lock:              Conditional                  = Conditional()
    private       var mstk:              [RingByteBuffer]             = []
    private       var thread:            Thread?                      = nil
    private       var error:             Error?                       = nil
    private       var readBuffer:        UnsafeMutablePointer<UInt8>? = nil
    private       var status:            Stream.Status                = .notOpen
    private       var isRunning:         Bool                         = false
    private       let autoClose:         Bool
    private       let inputStream:       InputStream

    private       var isOpen:            Bool                         { (status == .open)                                                                                        }
    private       var effStatus:         Stream.Status                { (isOpen ? (buffer.isEmpty ? ((error == nil) ? (isRunning ? .open : .atEnd) : .error) : .open) : status)  }
    private       var inputStreamIsOpen: Bool                         { ((inputStream.streamStatus != .notOpen) && (inputStream.streamStatus != .closed))                        }
    //@f:1

    /*==========================================================================================================*/
    /// Main initializer. Initializes this stream with the backing stream.
    ///
    /// - Parameters:
    ///   - inputStream: The backing input stream.
    ///   - maxMarkLength: The maximum distance the read pointer will be allowed to get from the mark pointer.
    ///                    Once the read pointer moves this many bytes past the mark pointer then the mark pointer
    ///                    will be moved to keep up.
    ///   - autoClose: If `false` the backing stream will NOT be closed when this stream is closed or destroyed.
    ///                The default is `true`.
    ///
    public init(inputStream: InputStream, autoClose: Bool = true) {
        self.inputStream = inputStream
        self.autoClose = autoClose
        super.init(data: Data())
    }

    /*==========================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object for reading from a given
    /// <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> object. The stream must be
    /// opened before it can be used.
    ///
    /// - Parameter data: The data object from which to read. The contents of data are copied.
    ///
    public override convenience init(data: Data) {
        self.init(inputStream: InputStream(data: data), autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object for reading from a given
    /// <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> object. The stream must be
    /// opened before it can be used.
    ///
    /// - Parameters:
    ///   - data: The data object from which to read. The contents of data are copied.
    ///   - maxMarkLength: The maximum distance the read pointer will be allowed to get from the mark pointer.
    ///                    Once the read pointer moves this many bytes past the mark pointer then the mark pointer
    ///                    will be moved to keep up.
    ///
    public convenience init(data: Data, maxMarkLength: Int = Int.max) {
        self.init(inputStream: InputStream(data: data), autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given URL.
    ///
    /// - Parameter url: The URL to the file.
    ///
    public override convenience init?(url: URL) {
        guard let stream = InputStream(url: url) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to the file.
    ///   - maxMarkLength: The maximum distance the read pointer will be allowed to get from the mark pointer.
    ///                    Once the read pointer moves this many bytes past the mark pointer then the mark pointer
    ///                    will be moved to keep up.
    ///
    public convenience init?(url: URL, maxMarkLength: Int = Int.max) {
        guard let stream = InputStream(url: url) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given path.
    ///
    /// - Parameter path: The path to the file.
    ///
    public convenience init?(fileAtPath path: String) {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given path.
    ///
    /// - Parameters:
    ///   - path: The path to the file.
    ///   - maxMarkLength: The maximum distance the read pointer will be allowed to get from the mark pointer.
    ///                    Once the read pointer moves this many bytes past the mark pointer then the mark pointer
    ///                    will be moved to keep up.
    ///
    public convenience init?(fileAtPath path: String, maxMarkLength: Int = Int.max) {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    /*==========================================================================================================*/
    /// Reads up to a given number of bytes into a given buffer.
    ///
    /// - Parameters:
    ///   - inputBuffer: A data buffer. The buffer must be large enough to contain the number of bytes specified
    ///                  by len.
    ///   - maxLength: The maximum number of bytes to read.
    /// - Returns: A number indicating the outcome of the operation: <ul><li>A positive number indicates the
    ///                                                              number of bytes read.</li><li>0 indicates
    ///                                                              that the end of the buffer was
    ///                                                              reached.</li><li>-1 means that the operation
    ///                                                              failed; more information about the error can
    ///                                                              be obtained with streamError.</li></ul>
    ///
    open override func read(_ inputBuffer: UnsafeMutablePointer<UInt8>, maxLength: Int) -> Int {
        lock.withLock {
            read(to: inputBuffer, maxLength: maxLength)
        }
    }

    /*==========================================================================================================*/
    /// Returns by reference a pointer to a read buffer and, by reference, the number of bytes available, and
    /// returns a Boolean value that indicates whether the buffer is available.
    ///
    /// - Parameters:
    ///   - bufferPtr: Upon return, contains a pointer to a read buffer. The buffer is only valid until the next
    ///                stream operation is performed.
    ///   - lengthPtr: Upon return, contains the number of bytes available.
    /// - Returns: `true` if the buffer is available, otherwise `false`.
    ///
    open override func getBuffer(_ bufferPtr: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length lengthPtr: UnsafeMutablePointer<Int>) -> Bool {
        lock.withLock {
            resetReadBuffer(bufferPtr, lengthPtr)

            let inputBuffer   = UnsafeMutablePointer<UInt8>.allocate(capacity: ReadBufferSize)
            let countReceived = read(to: inputBuffer, maxLength: ReadBufferSize)

            guard countReceived > 0 else {
                inputBuffer.deallocate()
                return false
            }

            setReadBuffer(inputBuffer, countReceived, bufferPtr, lengthPtr)
            return true
        }
    }

    /*==========================================================================================================*/
    /// Opens the receiving stream. A stream must be created before it can be opened. Once opened, a stream cannot
    /// be closed and reopened.
    ///
    open override func open() {
        lock.withLock {
            // Only open if the stream has NEVER been opened before.
            if status == .notOpen {
                status = .open
                isRunning = true
                thread = Thread { [weak self] in
                    let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: InputBufferSize)
                    defer { bytes.deallocate() }
                    while let s = self { guard s.doBackground(buffer: bytes, size: InputBufferSize) else { break } }
                }
                thread?.qualityOfService = .utility
                thread?.start()
            }
        }
    }

    /*==========================================================================================================*/
    /// Closes the receiver. Closing the stream terminates the flow of bytes and releases system resources that
    /// were reserved for the stream when it was opened. If the stream has been scheduled on a run loop, closing
    /// the stream implicitly removes the stream from the run loop. A stream that is closed can still be queried
    /// for its properties.
    ///
    open override func close() {
        lock.withLock {
            // Only close it if it was previously opened.
            if isOpen {
                status = .closed
                // Wait for the thread to end...
                while isRunning { lock.broadcastWait() }
                mstk.forEach { $0.clear(keepingCapacity: false) }
                mstk.removeAll(keepingCapacity: false)
                buffer.clear(keepingCapacity: false)
                resetReadBuffer()
                error = nil
            }
        }
    }

    /*==========================================================================================================*/
    /// Marks the current position in the stream.
    ///
    open func markSet() { lock.withLock { if isOpen { _markSet() } } }

    /*==========================================================================================================*/
    /// Returns to the last marked position in the stream.
    ///
    open func markReturn() { lock.withLock { if isOpen { _markReturn() } } }

    /*==========================================================================================================*/
    /// Deletes the last marked position in the stream.
    ///
    open func markDelete() { lock.withLock { if isOpen { _markDelete() } } }

    /*==========================================================================================================*/
    /// Effectively the same as performing a `markReturn()` followed by a `markSet()`.
    ///
    open func markReset() { lock.withLock { if isOpen { if !_markReset() { _markSet() } } } }

    /*==========================================================================================================*/
    /// Effectively the same as performing a `markDelete()` followed by a `markSet()`.
    ///
    open func markUpdate() { lock.withLock { if isOpen { if !_markUpdate() { _markSet() } } } }

    open func markBackup(count: Int = 1) -> Int {
        lock.withLock {
            if isOpen, let m = mstk.last {
                let cc = min(max(count, 0), m.count)

                if cc > 0 {
                    var bytes: [UInt8] = Array<UInt8>(repeating: 0, count: cc)
                }

                return cc
            }
            return 0
        }
    }

    /*==========================================================================================================*/
    /// Set a mark at the current read pointer.
    ///
    private func _markSet() { mstk <+ RingByteBuffer(initialCapacity: InputBufferSize) }

    private func _markDelete() { if let m1 = mstk.popLast(), let m2 = mstk.last { m2.append(src: m1) } }

    private func _markReturn() { if let m = mstk.popLast() { buffer.prepend(src: m) } }

    private func _markReset() -> Bool {
        if let m = mstk.last {
            buffer.prepend(src: m)
            m.clear(keepingCapacity: true)
            return true
        }
        return false
    }

    private func _markUpdate() -> Bool {
        if mstk.count >= 1 {
            let i  = (mstk.endIndex - 1)
            let rb = mstk[i]
            if mstk.count >= 2 { mstk[i - 1].append(src: rb) }
            rb.clear(keepingCapacity: true)
            return true
        }
        return false
    }

    /*==========================================================================================================*/
    /// Perform a read.
    ///
    /// - Parameters:
    ///   - buf: The receiving byte buffer.
    ///   - len: The maximum number of bytes to read.
    /// - Returns: The number of bytes actually read.
    ///
    private func read(to buf: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        var cc = 0

        if (effStatus == .open) {
            resetReadBuffer()

            while cc < len {
                // We're not looking for an error because if there was an error then isRunning would be false.
                while isOpen && buffer.isEmpty && isRunning { lock.broadcastWait() }

                guard buffer.hasBytesAvailable else {
                    guard (error == nil) else { return -1 }
                    guard isOpen && isRunning else { break }
                    continue
                }

                cc += buffer.get(dest: (buf + cc), maxLength: (len - cc))
            }

            if let mi = mstk.last { mi.append(src: buf, length: cc) }
        }

        return cc
    }

    /*==========================================================================================================*/
    /// Remove the current read buffer, created by a call to `getBuffer(_:length:)`, if there is one.
    ///
    private func resetReadBuffer() {
        if let b = readBuffer {
            b.deallocate()
            readBuffer = nil
        }
    }

    /*==========================================================================================================*/
    /// Remove the current read buffer, created by a call to `getBuffer(_:length:)`, if there is one.
    ///
    /// - Parameters:
    ///   - bufferPtr: The pointer to a buffer to be nullified.
    ///   - lengthPtr: The pointer to a length to be zeroed.
    ///
    private func resetReadBuffer(_ bufferPtr: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, _ lengthPtr: UnsafeMutablePointer<Int>) {
        resetReadBuffer()
        bufferPtr.pointee = nil
        lengthPtr.pointee = 0
    }

    /*==========================================================================================================*/
    /// Set the read buffer.
    ///
    /// - Parameters:
    ///   - inputBuffer: The new buffer.
    ///   - count The number of bytes in the buffer.
    ///   - bufferPtr: The pointer to a buffer.
    ///   - lengthPtr: The pointer to a length.
    ///
    private func setReadBuffer(_ inputBuffer: UnsafeMutablePointer<UInt8>, _ count: Int, _ bufferPtr: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, _ lengthPtr: UnsafeMutablePointer<Int>) {
        lengthPtr.pointee = count
        bufferPtr.pointee = inputBuffer
        readBuffer = inputBuffer
    }

    /*==========================================================================================================*/
    /// Start a background read.
    ///
    /// - Parameters:
    ///   - bytes: The buffer to use for the input.
    ///   - size: The size of the buffer.
    /// - Returns: `true` if this method can be called again.
    ///
    private func doBackground(buffer bytes: UnsafeMutablePointer<UInt8>, size: Int) -> Bool {
        lock.withLock {
            isRunning = doBackgroundRead(buffer: bytes, size: size)
            if !isRunning && autoClose && inputStreamIsOpen { inputStream.close() }
            return isRunning
        }
    }

    /*==========================================================================================================*/
    /// Read a chunk of data from the input stream.
    ///
    /// - Parameters:
    ///   - bytes: The buffer to use for the input.
    ///   - size: The size of the buffer.
    /// - Returns: `true` if this method can be called again.
    ///
    private func doBackgroundRead(buffer bytes: UnsafeMutablePointer<UInt8>, size: Int) -> Bool {
        do {
            guard isOpen else { return false }
            if inputStream.streamStatus == .notOpen {
                inputStream.open()
                // TODO: When they fix it remove this conditional
                #if !os(Linux)
                    if let e = inputStream.streamError { throw e }
                #endif
            }
            while isOpen && (buffer.count > MaxInputBufferSize) { guard lock.broadcastWait(until: Date(timeIntervalSinceNow: 1.0)) else { return isOpen } }
            guard isOpen else { return false }
            let cc = inputStream.read(bytes, maxLength: size)
            guard cc >= 0 else {
                // TODO: When they fix it remove this conditional
                #if !os(Linux)
                    if let e = inputStream.streamError { throw e }
                #endif
                throw StreamError.UnknownError(description: "An unknown error has occured.")
            }
            guard cc > 0 else { return false }
            buffer.append(src: bytes, length: cc)
            return true
        }
        catch let e {
            error = e
            return false
        }
    }

    deinit {
        resetReadBuffer()
        if autoClose && inputStreamIsOpen { inputStream.close() }
    }
}
