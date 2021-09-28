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
import Chadakoin

private let InputBufferSize:    Int    = 8_192  //  8KB
private let MaxInputBufferSize: Int    = 65_536 // 64KB
private let BackgroundWaitTime: Double = 2.0    // 2 seconds

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
    open override     var hasBytesAvailable: Bool             { withLock { (isOpen) && (rBuf.isNotEmpty || run) } }
    /*==========================================================================================================*/
    /// Returns the receiver’s status.
    ///
    open override     var streamStatus:      Stream.Status    { withLock { ((isOpen) ? (rBuf.isEmpty ? ((error == nil) ? (run ? st : .atEnd) : .error) : st) : st) as Stream.Status } }
    /*==========================================================================================================*/
    /// Returns an NSError object representing the stream error.
    ///
    open override     var streamError:       Error?           { withLock { error } }
    /*==========================================================================================================*/
    /// The number of marked positions for this stream.
    ///
    open              var markCount:         Int              { withLock { mstk.count } }

    @usableFromInline let autoClose:         Bool
    @usableFromInline let input:             InputStream
    @usableFromInline let rBuf:              RingByteBuffer   = RingByteBuffer(initialCapacity: InputBufferSize)
    @usableFromInline var tBuf:              EasyByteBuffer?  = nil
    @usableFromInline let cond:              Conditional      = Conditional()
    @usableFromInline let lock:              MutexLock        = MutexLock()
    @usableFromInline var mstk:              [RingByteBuffer] = []
    @usableFromInline var error:             Error?           = nil
    @usableFromInline var st:                Stream.Status    = .notOpen
    @usableFromInline var run:               Bool             = false
    private      lazy var thread:            Thread           = Thread { [weak self] in let bBuf = EasyByteBuffer(length: InputBufferSize); while let s = self, s._doBackground(buffer: bBuf) {} }
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
    public init(inputStream: InputStream, autoClose: Bool = true, maxMarkLength: Int = Int.max) {
        self.input = inputStream
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
        self.init(data: data, maxMarkLength: Int.max)
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
    public convenience init(data: Data, maxMarkLength: Int) {
        self.init(inputStream: InputStream(data: data), autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given URL.
    ///
    /// - Parameter url: The URL to the file.
    ///
    public override convenience init?(url: URL) { self.init(url: url, options: [], authenticate: nil, maxMarkLength: Int.max) }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to the file.
    ///   - options: The options for opening the URL.
    ///   - authenticate: The closure to handle authentication challenges.
    ///   - maxMarkLength: The maximum distance the read pointer will be allowed to get from the mark pointer.
    ///                    Once the read pointer moves this many bytes past the mark pointer then the mark pointer
    ///                    will be moved to keep up.
    ///
    public convenience init?(url: URL, options: URLInputStreamOptions = [], authenticate: AuthenticationCallback? = nil, maxMarkLength: Int = Int.max) {
        guard let stream = try? InputStream.getInputStream(url: url, options: options, authenticate: authenticate) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given path.
    ///
    /// - Parameter path: The path to the file.
    ///
    public convenience init?(fileAtPath path: String) {
        self.init(fileAtPath: path, maxMarkLength: Int.max)
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
    public convenience init?(fileAtPath path: String, maxMarkLength: Int) {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    open override func property(forKey key: PropertyKey) -> Any? { withLock { input.property(forKey: key) } }

    open override func setProperty(_ property: Any?, forKey key: PropertyKey) -> Bool { withLock { input.setProperty(property, forKey: key) } }

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
        withLock {
            func _subRead(_ buf: UnsafeMutablePointer<UInt8>, _ len: Int) -> Int {
                while rBuf.isEmpty && run { cond.broadcastWait() }
                return rBuf.isEmpty ? (error == nil ? 0 : -1) : rBuf.get(dest: buf, maxLength: len)
            }

            var cc = 0
            if tBuf != nil { tBuf = nil }
            while isOpen && cc < maxLength {
                let i = _subRead((inputBuffer + cc), (maxLength - cc))
                guard i > 0 else { return ((i == 0) || (cc > 0)) ? cc : -1 }
                cc += i
            }
            return cc
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
        withLock {
            if tBuf != nil { tBuf = nil }
            while isOpen && rBuf.count < MaxInputBufferSize && run { cond.broadcastWait() }
            guard isOpen && rBuf.count > 0 else { return false }
            tBuf = EasyByteBuffer(length: rBuf.count)
            rBuf.get(dest: tBuf!)
            bufferPtr.pointee = tBuf!.bytes
            lengthPtr.pointee = tBuf!.count
            return true
        }
    }

    /*==========================================================================================================*/
    /// Opens the receiving stream. A stream must be created before it can be opened. Once opened, a stream cannot
    /// be closed and reopened.
    ///
    open override func open() {
        withLock {
            // Only open if the stream has NEVER been opened before.
            guard st == .notOpen else { return }
            if input.streamStatus == .notOpen { input.open() }
            st = .open
            run = true
            thread.qualityOfService = .utility
            thread.start()
        }
    }

    /*==========================================================================================================*/
    /// Closes the receiver. Closing the stream terminates the flow of bytes and releases system resources that
    /// were reserved for the stream when it was opened. If the stream has been scheduled on a run loop, closing
    /// the stream implicitly removes the stream from the run loop. A stream that is closed can still be queried
    /// for its properties.
    ///
    open override func close() {
        withLock {
            // Only close it if it was previously opened.
            if (isOpen) {
                st = .closed
                // Wait for the thread to end...
                while run { cond.broadcastWait() }
                mstk.forEach { $0.clear() }
                mstk.removeAll()
                rBuf.clear()
                tBuf = nil
            }
        }
    }

    /*==========================================================================================================*/
    /// Marks the current position in the stream.
    ///
    open func markSet() { withLock { if isOpen { _markSet() } } }

    /*==========================================================================================================*/
    /// Returns to the last marked position in the stream.
    ///
    open func markReturn() {
        withLock {
            if isOpen, let rb = mstk.popLast() {
                if tBuf != nil { tBuf = nil }
                rBuf.prepend(src: rb)
            }
        }
    }

    /*==========================================================================================================*/
    /// Deletes the last marked position in the stream.
    ///
    open func markDelete() {
        withLock {
            if isOpen, let rb1 = mstk.popLast(), let rb2 = mstk.last {
                if tBuf != nil { tBuf = nil }
                rb2.append(src: rb1)
            }
        }
    }

    /*==========================================================================================================*/
    /// Effectively the same as performing a `markReturn()` followed by a `markSet()`.
    ///
    open func markReset() {
        withLock {
            if tBuf != nil { tBuf = nil }
            guard isOpen else { return }
            guard let rb = mstk.last else { return _markSet() }
            rBuf.prepend(src: rb)
            rb.clear(keepingCapacity: true)
        }
    }

    /*==========================================================================================================*/
    /// Effectively the same as performing a `markDelete()` followed by a `markSet()`.
    ///
    open func markClear() {
        withLock {
            if tBuf != nil { tBuf = nil }
            guard isOpen else { return }
            guard let rb = mstk.popLast() else { return _markSet() }
            if let rb2 = mstk.last { rb2.append(src: rb) }
            mstk.append(rb)
            rb.clear(keepingCapacity: true)
        }
    }

    /*==========================================================================================================*/
    /// Backs out the last `count` characters from the most recently set mark without actually removing the entire
    /// mark. You have to have previously called `markSet()` otherwise this method does nothing.
    ///
    /// - Parameter count: the number of characters to back out.
    /// - Returns: The number of characters actually backed out in case there weren't `count` characters available.
    ///
    @discardableResult open func markBackup(count: Int = 1) -> Int {
        withLock {
            if tBuf != nil { tBuf = nil }
            guard isOpen && count > 0 else { return 0 }
            guard let rb = mstk.last, rb.count > 0 else { return 0 }

            let cc    = min(count, rb.count)
            let bytes = UnsafeMutableRawPointer.allocate(byteCount: cc, alignment: MemoryLayout<UInt8>.alignment)
            defer { bytes.deallocate() }

            let rc = rb.getFromEnd(dest: bytes, maxLength: cc)
            rBuf.prepend(src: bytes, length: rc)
            return rc
        }
    }

    /*==========================================================================================================*/
    /// Marks the current position in the stream.
    ///
    private func _markSet() { mstk <+ RingByteBuffer(initialCapacity: InputBufferSize) }

    /*==========================================================================================================*/
    /// Start a background read.
    ///
    /// - Parameters:
    ///   - bytes: The buffer to use for the input.
    ///   - size: The size of the buffer.
    /// - Returns: `true` if this method can be called again.
    ///
    private func _doBackground(buffer bBuf: EasyByteBuffer) -> Bool {
        cond.withLock {
            func foo(_ cc: Int) throws -> Bool {
                guard cc == 0 else { throw input.streamError ?? StreamError.UnknownError() }
                return false
            }

            run = bBuf.withBytes { (b, l, _) in
                do {
                    while isOpen && rBuf.count >= MaxInputBufferSize { guard cond.broadcastWait(until: Date(timeIntervalSinceNow: BackgroundWaitTime)) else { return (isOpen) } }
                    guard isOpen else { return false }
                    let cc = input.read(b, maxLength: l)
                    guard cc > 0 else { return try foo(cc) }
                    rBuf.append(src: UnsafeRawPointer(b), length: cc)
                    return true
                }
                catch let e {
                    error = e
                    return false
                }
            }
            if !run { _closeInput() }
            return run
        }
    }

    private func _closeInput() { if autoClose && input.streamStatus != .notOpen { input.close() } }

    deinit { _closeInput() }
}

extension MarkInputStream {
    @inlinable var isOpen: Bool { st == .open }

    @inlinable func withLock<T>(_ body: () throws -> T) rethrows -> T { try lock.withLock { try cond.withLock { try body() } } }
}
