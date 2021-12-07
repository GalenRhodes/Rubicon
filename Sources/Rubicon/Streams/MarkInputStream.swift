/*=================================================================================================================================================================================*
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
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation
import Chadakoin

@usableFromInline let InputBufferSize:    Int    = 8_192  //  8KB
@usableFromInline let MaxInputBufferSize: Int    = 65_536 // 64KB
@usableFromInline let BackgroundWaitTime: Double = 2.0    // 2 seconds

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
    open override     var hasBytesAvailable: Bool             { _withLock { (st == .open) && (rBuf.isNotEmpty || thread.isRunning) } }
    /*==========================================================================================================*/
    /// Returns the receiver’s status.
    ///
    open override     var streamStatus:      Stream.Status    { _withLock { ((st == .open) ? (rBuf.isEmpty ? ((error == nil) ? (thread.isRunning ? st : .atEnd) : .error) : st) : st) as Stream.Status } }
    /*==========================================================================================================*/
    /// Returns an NSError object representing the stream error.
    ///
    open override     var streamError:       Error?           { _withLock { error } }
    /*==========================================================================================================*/
    /// The number of marked positions for this stream.
    ///
    open              var markCount:         Int              { _withLock { mstk.count } }

    @usableFromInline let autoClose:         Bool
    @usableFromInline let input:             InputStream
    @usableFromInline let rBuf:              RingByteBuffer   = RingByteBuffer(initialCapacity: InputBufferSize)
    @usableFromInline var tBuf:              EasyByteBuffer?  = nil
    @usableFromInline let cond:              Conditional      = Conditional()
    @usableFromInline let lock:              MutexLock        = MutexLock()
    @usableFromInline var mstk:              [RingByteBuffer] = []
    @usableFromInline var error:             Error?           = nil
    @usableFromInline var st:                Stream.Status    = .notOpen
    //@f:1

    /*==========================================================================================================*/
    /// Main initializer. Initializes this stream with the backing stream.
    /// 
    /// - Parameters:
    ///   - inputStream: The backing input stream.
    ///   - autoClose: If `false` the backing stream will NOT be closed when this stream is closed or destroyed.
    ///                The default is `true`.
    ///
    public init(inputStream: InputStream, autoClose: Bool = true) {
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
        self.init(inputStream: InputStream(data: data), autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given URL.
    /// 
    /// - Parameter url: The URL to the file.
    ///
    public override convenience init?(url: URL) {
        self.init(url: url, options: [], authenticate: nil)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object that reads data from the file at a given path.
    /// 
    /// - Parameter path: The path to the file.
    ///
    public convenience init?(fileAtPath path: String) {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    open override func property(forKey key: PropertyKey) -> Any? {
        _withLock { input.property(forKey: key) }
    }

    open override func setProperty(_ property: Any?, forKey key: PropertyKey) -> Bool {
        _withLock { input.setProperty(property, forKey: key) }
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
    open override func read(_ inputBuffer: BytePointer, maxLength: Int) -> Int {
        _withLock {
            var cc = 0
            _clearTempBuffer()
            while st == .open && cc < maxLength {
                while st == .open && rBuf.isEmpty && thread.isRunning { cond.broadcastWait() }
                guard st == .open else { return cc }
                guard rBuf.isNotEmpty else { return ((cc > 0) ? cc : ((error == nil) ? 0 : -1)) }
                let i = rBuf.get(dest: (inputBuffer + cc) as BytePointer, maxLength: (maxLength - cc))
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
    open override func getBuffer(_ bufferPtr: UnsafeMutablePointer<BytePointer?>, length lengthPtr: UnsafeMutablePointer<Int>) -> Bool {
        _withLock {
            _clearTempBuffer()
            while st == .open && rBuf.count < MaxInputBufferSize && thread.isRunning { cond.broadcastWait() }
            guard st == .open && rBuf.isNotEmpty else { return false }
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
        _withLock {
            do {
                // Only open if the stream has NEVER been opened before.
                guard st == .notOpen else { return }
                if input.streamStatus == .notOpen { input.open() }
                st = .open
                try thread.start()
            }
            catch let e {
                error = e
                if autoClose { input.close() }
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
        _withLock {
            // Only close it if it was previously opened.
            guard (st == .open) else { return }
            st = .closed
            // Wait for the thread to end...
            while thread.isRunning { cond.broadcastWait() }
            mstk.forEach { $0.clear() }
            mstk.removeAll()
            rBuf.clear()
            tBuf = nil
        }
    }

    /*==========================================================================================================*/
    /// Marks the current position in the stream.
    ///
    open func markSet() { _withLock { if st == .open { _markSet() } } }

    /*==========================================================================================================*/
    /// Returns to the last marked position in the stream.
    ///
    open func markReturn() {
        _withLock {
            guard st == .open, let rb = mstk.popLast() else { return }
            _clearTempBuffer()
            rBuf.prepend(src: rb)
        }
    }

    /*==========================================================================================================*/
    /// Deletes the last marked position in the stream.
    ///
    open func markDelete() {
        _withLock {
            guard st == .open, let rb1 = mstk.popLast(), let rb2 = mstk.last else { return }
            _clearTempBuffer()
            rb2.append(src: rb1)
        }
    }

    /*==========================================================================================================*/
    /// Effectively the same as performing a `markReturn()` followed by a `markSet()`.
    ///
    open func markReset() {
        _withLock {
            _clearTempBuffer()
            guard st == .open else { return }
            guard let rb = mstk.last else { return _markSet() }
            rBuf.prepend(src: rb)
            rb.clear(keepingCapacity: true)
        }
    }

    /*==========================================================================================================*/
    /// Effectively the same as performing a `markDelete()` followed by a `markSet()`.
    ///
    open func markClear() {
        _withLock {
            _clearTempBuffer()
            guard st == .open else { return }
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
        _withLock {
            _clearTempBuffer()
            guard let rb = mstk.last, rb.count > 0 && st == .open && count > 0 else { return 0 }

            let cc = min(count, rb.count)
            let bf = UnsafeMutableRawPointer.allocate(byteCount: cc, alignment: MemoryLayout<UInt8>.alignment)
            defer { bf.deallocate() }

            let rc = rb.getFromEnd(dest: bf, maxLength: cc)
            rBuf.prepend(src: bf, length: rc)
            return rc
        }
    }

    deinit { _closeInput() }

    /*==========================================================================================================*/
    /// A background thread that reads from the backing input stream. The background thread continuously calls
    /// `_runLoop(buffer:maxLength:)` until it returns `false`.
    ///
    @usableFromInline lazy var thread: Runner<Bool, Void> = Runner<Bool, Void>(startNow: false, qualityOfService: .utility) { [weak self] (_) in
        let bBuf = BytePointer.allocate(capacity: InputBufferSize)
        defer { bBuf.deallocate() }
        while let s = self { guard s._runLoop(buffer: bBuf, maxLength: InputBufferSize) else { s._closeInput(); break } }
    }
}

extension MarkInputStream {
    /*==========================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object that reads data from the file at a given URL.
    /// 
    /// - Parameters:
    ///   - url: The URL to the file.
    ///   - options: The options for opening the URL.
    ///   - authenticate: The closure to handle authentication challenges.
    ///
    @inlinable public convenience init?(url: URL, options: URLInputStreamOptions, authenticate: AuthenticationCallback?) {
        guard let stream = try? InputStream.getInputStream(url: url, options: options, authenticate: authenticate) else { return nil }
        self.init(inputStream: stream, autoClose: true)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object that reads data from the file at a given URL.
    /// 
    /// - Parameters:
    ///   - url: The URL to the file.
    ///   - options: The options for opening the URL.
    ///
    @inlinable public convenience init?(url: URL, options: URLInputStreamOptions) {
        self.init(url: url, options: options, authenticate: nil)
    }

    /*==========================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object that reads data from the file at a given URL.
    /// 
    /// - Parameters:
    ///   - url: The URL to the file.
    ///   - authenticate: The closure to handle authentication challenges.
    ///
    @inlinable public convenience init?(url: URL, authenticate: AuthenticationCallback?) {
        self.init(url: url, options: [], authenticate: authenticate)
    }

    /*==========================================================================================================*/
    /// Marks the current position in the stream.
    ///
    @inlinable func _markSet() {
        mstk <+ RingByteBuffer(initialCapacity: InputBufferSize)
    }

    /*==========================================================================================================*/
    /// If `autoClose` is `true` then this method closes the backing input stream. If `autoClose` is `false` then
    /// this method does nothing.
    ///
    @inlinable func _closeInput() {
        if autoClose && input.streamStatus != .notOpen { input.close() }
    }

    /*==========================================================================================================*/
    /// Locks/Unlocks both internal and external locks.
    /// 
    /// - Parameter body: The closure to execute with both locks locked.
    /// - Returns: The value turned from the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    @inlinable func _withLock<T>(_ body: () throws -> T) rethrows -> T { try lock.withLock { try cond.withLock { try body() } } }

    /*==========================================================================================================*/
    /// Clears the temporary buffer that may have been created by a call to `getBuffer(_:length:)`.
    ///
    @inlinable func _clearTempBuffer() { if tBuf != nil { tBuf = nil } }

    /*==========================================================================================================*/
    /// This method is called by the background thread to read a block of data from the backing input stream.
    /// 
    /// - Parameters:
    ///   - bBuf: A byte buffer.
    ///   - l: The size of the byte buffer.
    /// - Returns: `true` if there is more to read of `false` if the backing input stream is at EOF or there was
    ///            an error in the underlying input stream.
    ///
    @usableFromInline func _runLoop(buffer bBuf: BytePointer, maxLength l: Int) -> Bool {
        cond.withLock {
            do {
                return try _innerRunLoop(buffer: bBuf, maxLength: l)
            }
            catch let e {
                error = e
                return false
            }
        }
    }

    /*==========================================================================================================*/
    /// Called by `_runLoop(buffer:maxLength:)`.
    /// 
    /// - Parameters:
    ///   - bBuf: A byte buffer.
    ///   - l: The size of the byte buffer.
    /// - Returns: `true` if there is more to read of `false` if the backing input stream is at EOF or there was
    ///            an error in the underlying input stream.
    /// - Throws: If an I/O error occurs.
    ///
    @inlinable func _innerRunLoop(buffer bBuf: BytePointer, maxLength l: Int) throws -> Bool {
        while st == .open && rBuf.count >= MaxInputBufferSize { guard cond.broadcastWait(until: Date(timeIntervalSinceNow: BackgroundWaitTime)) else { return st == .open } }
        guard st == .open else { return false }
        let cc = input.read(bBuf, maxLength: l)
        guard cc > 0 else { return try _innerRunLoopEnd(cc) }
        rBuf.append(src: UnsafeRawPointer(bBuf), length: cc)
        return true
    }

    /*==========================================================================================================*/
    /// Called by `_innerRunLoop(buffer:maxLength:)`.
    /// 
    /// - Parameter cc: The return code from the input stream.
    /// - Returns: <code>[Zero](https://en.wikipedia.org/wiki/0)</code> if End-of-Input.
    /// - Throws: If the return code was -1.
    ///
    @inlinable func _innerRunLoopEnd(_ cc: Int) throws -> Bool {
        guard cc == 0 else { throw input.streamError ?? StreamError.UnknownError() }
        return false
    }
}
