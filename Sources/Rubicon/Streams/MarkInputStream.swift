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
let ReloadTriggerSize:  Int = ((MaxInputBufferSize / 4) * 3) // 48KB

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
    open override var hasBytesAvailable: Bool             { lock.withLock { (isGood && hasBytes)                                                  } }
    /*===========================================================================================================================================================================*/
    /// Returns the receiver’s status.
    ///
    open override var streamStatus:      Stream.Status    { lock.withLock { (isOpen ? (hasError ? .error : (hasBytes ? .open : .atEnd)) : status) } }
    /*===========================================================================================================================================================================*/
    /// Returns an NSError object representing the stream error.
    ///
    open override var streamError:       Error?           { lock.withLock { ((isOpen && hasError) ? error : nil)                                  } }
    /*===========================================================================================================================================================================*/
    /// The number of marked positions for this stream.
    ///
    open          var markCount:         Int              { lock.withLock { mstk.count                                                            } }

    private  lazy var buffer:            RingByteBuffer   = RingByteBuffer(initialCapacity: InputBufferSize)
    private  lazy var queue:             DispatchQueue    = DispatchQueue(label: UUID().uuidString, qos: .utility)
    private  lazy var lock:              Conditional      = Conditional()
    private       var mstk:              [RingByteBuffer] = []
    private       var error:             Error?           = nil
    private       var ezBuffer:          EasyByteBuffer?  = nil
    private       var status:            Stream.Status    = .notOpen
    private       var isRunning:         Bool             = false

    private       var isOpen:            Bool             { (status == .open)                       }
    private       var hasError:          Bool             { (buffer.isEmpty && (error != nil))      }
    private       var isGood:            Bool             { (isOpen && !hasError)                   }
    private       var hasBytes:          Bool             { (buffer.hasBytesAvailable || isRunning) }

    private       let autoClose:         Bool
    private       let inputStream:       InputStream
    //@f:1

    /*===========================================================================================================================================================================*/
    /// Main initializer. Initializes this stream with the backing stream.
    /// 
    /// - Parameters
    ///   - inputStream: The backing input stream.
    ///   - autoClose: If `false` the backing stream will NOT be closed when this stream is closed or destroyed. The default is `true`.
    ///
    public init(inputStream: InputStream, autoClose: Bool = true) {
        self.inputStream = inputStream
        self.autoClose = autoClose
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

    deinit { _close() }

    /*===========================================================================================================================================================================*/
    /// Reads up to a given number of bytes into a given buffer.
    /// 
    /// - Parameters:
    ///   - buf: A data buffer. The buffer must be large enough to contain the number of bytes specified by len.
    ///   - len: The maximum number of bytes to read.
    /// - Returns: A number indicating the outcome of the operation: <ul><li>A positive number indicates the number of bytes read.</li><li>0 indicates that the end of the buffer
    ///                                                              was reached.</li><li>-1 means that the operation failed; more information about the error can be obtained with
    ///                                                              streamError.</li></ul>
    ///
    open override func read(_ buf: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        _waitForData { (open: Bool, err: Bool, cc: Int) -> Int in
            ezBuffer = nil
            guard open && !err && cc > 0 else { return ((open && err) ? -1 : 0) }
            let i = buffer.get(dest: buf, maxLength: len)
            if let mi = mstk.last { mi.append(src: buf, length: i) }
            return i
        }
    }

    /*===========================================================================================================================================================================*/
    /// Returns by reference a pointer to a read buffer and, by reference, the number of bytes available, and returns a Boolean value that indicates whether the buffer is
    /// available.
    /// 
    /// - Parameters:
    ///   - buf: Upon return, contains a pointer to a read buffer. The buffer is only valid until the next stream operation is performed.
    ///   - len: Upon return, contains the number of bytes available.
    /// - Returns: `true` if the buffer is available, otherwise `false`.
    ///
    open override func getBuffer(_ buf: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        _waitForData { (open: Bool, err: Bool, cc: Int) -> Bool in
            if open && !err && cc > 0 {
                let ezb = EasyByteBuffer(length: cc)
                ezBuffer = ezb
                len.pointee = buffer.get(dest: ezb)
                buf.pointee = ezb.bytes
                if let mi = mstk.last { mi.append(src: ezb) }
                return true
            }

            ezBuffer = nil
            len.pointee = 0
            buf.pointee = nil
            return false
        }
    }

    /*===========================================================================================================================================================================*/
    /// Opens the receiving stream. A stream must be created before it can be opened. Once opened, a stream cannot be closed and reopened.
    ///
    open override func open() {
        lock.withLock {
            _open()
        }
    }

    /*===========================================================================================================================================================================*/
    /// Closes the receiver. Closing the stream terminates the flow of bytes and releases system resources that were reserved for the stream when it was opened. If the stream has
    /// been scheduled on a run loop, closing the stream implicitly removes the stream from the run loop. A stream that is closed can still be queried for its properties.
    ///
    open override func close() {
        lock.withLock {
            _close()
            while isRunning { lock.broadcastWait() }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current position in the stream.
    ///
    open func markSet() {
        lock.withLock {
            mstk <+ RingByteBuffer(initialCapacity: InputBufferSize)
        }
    }

    open func markReturn() {
        lock.withLock {
            if let rb = mstk.popLast() {
                buffer.prepend(src: rb)
                rb.clear(keepingCapacity: false)
            }
        }
    }

    open func markDelete() {
        lock.withLock {
            if let rb = mstk.popLast() {
                rb.clear(keepingCapacity: false)
            }
        }
    }

    open func markUpdate() {
        lock.withLock {
            if let rb = mstk.last {
                rb.clear(keepingCapacity: true)
            }
            else {
                mstk <+ RingByteBuffer(initialCapacity: InputBufferSize)
            }
        }
    }

    open func markReset() {
        lock.withLock {
            if let rb = mstk.last {
                buffer.prepend(src: rb)
                rb.clear(keepingCapacity: true)
            }
            else {
                mstk <+ RingByteBuffer(initialCapacity: InputBufferSize)
            }
        }
    }

    private func _open() {
        if status == .notOpen {
            status = .open
            isRunning = true
            _resetFields()
            queue.async { [weak self] in self?._readerThread() }
        }
    }

    private func _close() {
        if status == .open {
            status = .closed
            isRunning = false
            _resetFields()
        }
    }

    private func _resetFields() {
        error = nil
        ezBuffer = nil
        buffer.clear(keepingCapacity: false)
        for b in mstk { b.clear(keepingCapacity: false) }
        mstk.removeAll(keepingCapacity: false)
    }

    private func _waitForData<T>(_ body: (Bool, Bool, Int) throws -> T) rethrows -> T {
        try lock.withLock {
            while buffer.isEmpty && isOpen && isRunning && !hasError { lock.broadcastWait() }
            return try body(isOpen, hasError, buffer.available)
        }
    }

    private func _readerThread() {
        lock.withLock {
            var go: Bool { isRunning && isOpen && (error == nil) }

            do {
                defer { isRunning = false }
                let rbuf = EasyByteBuffer(length: InputBufferSize)
                if inputStream.streamStatus == .notOpen { inputStream.open() }
                if let e = inputStream.streamError { throw e }
                defer { if autoClose { inputStream.close() } }

                while go {
                    while go && (buffer.available >= MaxInputBufferSize) { lock.broadcastWait() }

                    if go {
                        if try inputStream.read(to: rbuf) == 0 { break }
                        buffer.append(src: rbuf)
                    }
                }
            }
            catch let e {
                error = e
            }
        }
    }
}
