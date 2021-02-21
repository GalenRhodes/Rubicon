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

@usableFromInline let MaxInputBufferSize: Int = (InputBufferSize * 64)         // 64KB
@usableFromInline let ReloadTriggerSize:  Int = ((MaxInputBufferSize / 4) * 3) // 48KB

/*===============================================================================================================================================================================*/
/// An <code>[input stream](https://developer.apple.com/documentation/foundation/inputstream)</code> that you can mark places in with a call to `markSet()` and to return to with a
/// call to `markRelease()`.
///
open class MarkInputStream: InputStream {
    //@f:0
    /*===========================================================================================================================================================================*/
    /// A Boolean value that indicates whether the receiver has bytes available to read. `true` if the receiver has bytes available to read, otherwise `false`. May also return
    /// `true` if a read must be attempted in order to determine the availability of bytes.
    ///
    open override var hasBytesAvailable: Bool   { _lock.withLock { (_ring.hasBytesAvailable || _stream.hasBytesAvailable) } }
    /*===========================================================================================================================================================================*/
    /// Returns the receiver’s status.
    ///
    open override var streamStatus:      Status { _lock.withLock { ((_stream.status(in: .atEnd, .error) && _ring.hasBytesAvailable) ? .open : _stream.streamStatus) } }
    /*===========================================================================================================================================================================*/
    /// Returns an NSError object representing the stream error.
    ///
    open override var streamError:       Error? { _lock.withLock { (_ring.hasBytesAvailable ? nil : _stream.streamError) } }
    /*===========================================================================================================================================================================*/
    /// The number of marked positions for this stream.
    ///
    open          var markCount:         Int    { _lock.withLock { _markStack.count } }

    @usableFromInline var _markStack: [RingByteBuffer] = []
    @usableFromInline var _ring:      RingByteBuffer   = RingByteBuffer(initialCapacity: InputBufferSize)

    private      var _running:   Bool             = false
    private lazy var _thread:    DispatchQueue    = DispatchQueue(label: UUID().uuidString, qos: .utility)
    private      var _lastBuff:  EasyByteBuffer!  = nil
    private      let _lock:      Conditional      = Conditional()
    private      let _autoClose: Bool
    private      let _stream:    InputStream
    //@f:1

    /*===========================================================================================================================================================================*/
    /// Main initializer. Initializes this stream with the backing stream.
    /// 
    /// - Parameters
    ///   - inputStream: The backing input stream.
    ///   - autoClose: If `false` the backing stream will NOT be closed when this stream is closed or destroyed. The default is `true`.
    ///
    public init(inputStream: InputStream, autoClose: Bool = true) {
        _stream = inputStream
        _autoClose = autoClose
        super.init(data: Data())
    }

    /*===========================================================================================================================================================================*/
    /// Initializes and returns an `MarkInputStream` object for reading from a given <code>[Data](https://developer.apple.com/documentation/foundation/data/)</code> object. The
    /// stream must be opened before it can be used.
    /// 
    /// - Parameter data: The data object from which to read. The contents of data are copied.
    ///
    public override convenience init(data: Data) {
        self.init(inputStream: InputStream(data: data))
    }

    /*===========================================================================================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given URL.
    /// 
    /// - Parameter url: The URL to the file.
    ///
    public override convenience init?(url: URL) {
        guard let stream = InputStream(url: url) else { return nil }
        self.init(inputStream: stream)
    }

    /*===========================================================================================================================================================================*/
    /// Initializes and returns an NSInputStream object that reads data from the file at a given path.
    /// 
    /// - Parameter path: The path to the file.
    ///
    public convenience init?(fileAtPath path: String) {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        self.init(inputStream: stream)
    }

    deinit { close() }

    /*===========================================================================================================================================================================*/
    /// Reads up to a given number of bytes into a given buffer.
    /// 
    /// - Parameters:
    ///   - buffer: A data buffer. The buffer must be large enough to contain the number of bytes specified by len.
    ///   - len: The maximum number of bytes to read.
    /// - Returns: A number indicating the outcome of the operation: <ul><li>A positive number indicates the number of bytes read.</li><li>0 indicates that the end of the buffer
    ///                                                              was reached.</li><li>-1 means that the operation failed; more information about the error can be obtained with
    ///                                                              streamError.</li></ul>
    ///
    open override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard len > 0 else { return 0 }
        return waitForData { (avail: Int) -> Int in
            guard avail > 0 else { return ((_stream.streamStatus == .atEnd) ? 0 : -1) }
            let cc = _ring.get(dest: buffer, maxLength: len)
            if let m = _markStack.last { m.append(src: buffer, length: cc) }
            return cc
        }
    }

    /*===========================================================================================================================================================================*/
    /// Returns by reference a pointer to a read buffer and, by reference, the number of bytes available, and returns a Boolean value that indicates whether the buffer is
    /// available.
    /// 
    /// - Parameters:
    ///   - buffer: Upon return, contains a pointer to a read buffer. The buffer is only valid until the next stream operation is performed.
    ///   - len: Upon return, contains the number of bytes available.
    /// - Returns: `true` if the buffer is available, otherwise `false`.
    ///
    open override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        waitForData { (avail: Int) -> Bool in
            guard avail > 0 else {
                _lastBuff = EasyByteBuffer(length: 1)
                buffer.pointee = _lastBuff.bytes
                len.pointee = 0
                return true
            }

            _lastBuff = EasyByteBuffer(length: avail)
            len.pointee = _ring.get(dest: _lastBuff.bytes, maxLength: avail)
            if let m = _markStack.last { m.append(src: _lastBuff.bytes, length: len.pointee) }
            buffer.pointee = _lastBuff.bytes
            return true
        }
    }

    /*===========================================================================================================================================================================*/
    /// Opens the receiving stream. A stream must be created before it can be opened. Once opened, a stream cannot be closed and reopened.
    ///
    open override func open() {
        _lock.withLock {
            guard _stream.streamStatus == .notOpen else { return }
            _stream.open()
            _running = true
            _thread.async { self.readerThread() }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Closes the receiver. Closing the stream terminates the flow of bytes and releases system resources that were reserved for the stream when it was opened. If the stream has
    /// been scheduled on a run loop, closing the stream implicitly removes the stream from the run loop. A stream that is closed can still be queried for its properties.
    ///
    open override func close() {
        _lock.withLock {
            if _autoClose { _stream.close() }
            _running = false
        }
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current position in the stream.
    ///
    open func markSet() { _lock.withLock { _markSet() } }

    open func markReturn() { _lock.withLock { _markReturn() } }

    open func markDelete() { _lock.withLock { _markDelete() } }


    open func markUpdate() {
        _lock.withLock {
            _markDelete()
            _markSet()
        }
    }

    open func markReset() {
        _lock.withLock {
            _markReturn()
            _markSet()
        }
    }

    @inlinable final func _markSet() { _markStack.append(RingByteBuffer(initialCapacity: InputBufferSize)) }

    @inlinable final func _markReturn() { if let mark = _markStack.popLast() { _ring.prepend(ringBuffer: mark) } }

    @inlinable final func _markDelete() { if let six = _markStack.popLast() { if let siy = _markStack.last { siy.append(ringBuffer: six) } } }

    private func waitForData<T>(_ body: (Int) throws -> T) rethrows -> T {
        try _lock.withLockBroadcastWait { _ring.hasBytesAvailable || !_running } do: { try body(_stream.streamStatus == .closed ? 0 : _ring.available) }
    }

    private final func readerThread() {
        while _running && _stream.status(in: .notOpen, .opening) { NanoSleep2(nanos: 5000000) }
        if preLoad() { while _running && _stream.hasBytesAvailable { guard inLoad() else { break } } }
        _lock.withLock { _running = false }
    }

    private final func inLoad() -> Bool { _lock.withLockBroadcastWait { ((_ring.available < ReloadTriggerSize) || !_running) } do: { doBufferRead() } }

    private final func preLoad() -> Bool { _lock.withLock { doBufferRead() } }

    private final func doBufferRead() -> Bool {
        do {
            if _running && _stream.hasBytesAvailable {
                let y = (MaxInputBufferSize - _ring.available)
                return try (_ring.append(from: _stream, maxLength: y) == y)
            }
        }
        catch {}
        return false
    }
}
