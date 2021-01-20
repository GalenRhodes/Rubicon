/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: IConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/1/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
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
import iconv

/*===============================================================================================================================================================================*/
/// There is a possibility that the endian of the system is not known. In that case we default to `little` endian because that's the most common these days.
///
@usableFromInline let EncodeToName: String = "UTF-32\((CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue) ? "BE" : "LE")"
@usableFromInline let MaxReadAhead: Int    = 8192

open class IConvCharInputStream: CharInputStream {
    //@f:0
    public let encodingName:      String
    public var streamStatus:      Stream.Status { lock.withLock { ((streamStatusGood(status) && eof) ? (hasError ? .error : .atEnd) : status) } }
    public var streamError:       Error?        { lock.withLock { ((status == .error) ? error : nil)                                          } }
    public var hasCharsAvailable: Bool          { lock.withLock { !eof                                                                        } }
    public var isEOF:             Bool          { value(streamStatus, isOneOf: .closed, .atEnd, .error)                                         }
    //@f:1

    @usableFromInline var charBuffer:    [Character]   = []
    @usableFromInline var markStack:     [MarkItem]    = []
    @usableFromInline var status:        Stream.Status = .notOpen
    @usableFromInline var error:         Error?        = nil
    @usableFromInline var readerWaiting: Bool          = false
    @usableFromInline var iConvRunning:  Bool          = false
    @usableFromInline var threadRunning: Bool          = false
    @usableFromInline let lock:          Conditional   = Conditional()
    @usableFromInline let queue:         DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .background, autoreleaseFrequency: .workItem)
    @usableFromInline let inputStream:   InputStream
    @usableFromInline let autoClose:     Bool

    @inlinable final var isOpen:   Bool { !value(status, isOneOf: .notOpen, .closed) }
    @inlinable final var eof:      Bool { charBuffer.isEmpty && !iConvRunning }
    @inlinable final var notDone:  Bool { !value(status, isOneOf: .closed, .error) }
    @inlinable final var hasError: Bool { error != nil }

    public init(inputStream: InputStream, autoClose: Bool = true, encodingName: String) {
        self.inputStream = inputStream
        self.encodingName = encodingName.trimmed.uppercased()
        self.autoClose = autoClose
    }

    public convenience init?(fileAtPath: String, encodingName: String) {
        guard let inputStream = InputStream(fileAtPath: fileAtPath) else { return nil }
        self.init(inputStream: inputStream, encodingName: encodingName)
    }

    public convenience init?(url: URL, encodingName: String) {
        guard let inputStream = InputStream(url: url) else { return nil }
        self.init(inputStream: inputStream, encodingName: encodingName)
    }

    public convenience init(data: Data, encodingName: String) {
        self.init(inputStream: InputStream(data: data), encodingName: encodingName)
    }

    deinit {
        close()
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current position in the stream so that it can be returned to later.
    ///
    open func markSet() {
        lock.withLock {
            if streamStatusGood(status) && iConvRunning {
                markStack.append(MarkItem())
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Returns to a previously marked position in the stream.
    ///
    /// - Parameter discard: If `true` the marked file-pointer position will be discarded instead of reset.
    ///
    open func markRelease(discard: Bool = false) {
        lock.withLock {
            if let ms = markStack.popLast() {
                if !discard { charBuffer.insert(contentsOf: ms.chars, at: 0) }
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Opens the character stream for reading.  If the stream has already been opened then calling this method does nothing.
    ///
    open func open() {
        lock.withLock {
            if status == .notOpen {
                status = .open
                iConvRunning = true
                threadRunning = true
                queue.async { self.runner() }
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Closes the character stream after which no further characters can be read. If the stream had never been opened it will still go directly into a closed state. If the
    /// character stream has already been closed then calling this method does nothing. Once a character stream has been closed it can never be reopened.
    ///
    open func close() {
        lock.withLock {
            if status != .closed {
                status = .closed
                charBuffer.removeAll()
                markStack.removeAll()
            }
        }
        lock.withLockBroadcastWait { !threadRunning }
    }

    /*===========================================================================================================================================================================*/
    /// Read one character from the input stream.
    ///
    /// - Returns: the character read or `nil` if the stream is closed (or not opened in the first place) or the end of input has been reached.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    open func read() throws -> Character? {
        try waitForChars {
            guard isOpen else { return nil }
            guard let ch = charBuffer.popFirst() else { return try onError(nil) }
            if let mark = markStack.last { mark.chars.append(ch) }
            return ch
        }
    }

    /*===========================================================================================================================================================================*/
    /// Read characters from the stream.
    ///
    /// - Parameters:
    ///   - chars: the array to receive the characters.
    ///   - maxLength: the maximum number of characters to receive. If -1 then all characters are read until the end of input.
    /// - Returns: the number of characters actually read. If the stream is closed (or not opened) or the end of input has been reached then
    ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> `0` is returned.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    open func read(chars: inout [Character], maxLength: Int) throws -> Int {
        let maxLength = ((maxLength < 0) ? Int.max : maxLength)
        guard maxLength > 0 else { return 0 }
        return try waitForChars {
            let range = (0 ..< min(maxLength, charBuffer.count))

            guard isOpen else { return 0 }
            guard range.count > 0 else { return try onError(0) }

            let subset = charBuffer[range]
            chars.append(contentsOf: subset)
            if let mark = markStack.last { mark.chars.append(contentsOf: subset) }
            charBuffer.removeSubrange(range)
            return range.count
        }
    }

    /*===========================================================================================================================================================================*/
    /// The background thread function that reads from the backing byte input stream.
    ///
    final func runner() {
        lock.withLock {
            if inputStream.streamStatus != .closed {
                do {
                    if inputStream.streamStatus == .notOpen { inputStream.open() }
                    defer { if autoClose { inputStream.close() } }
                    if let iconv = IConv(toEncoding: EncodeToName, fromEncoding: encodingName, ignoreErrors: true, enableTransliterate: true) { try iConvert(iconv) }
                    else { error = StreamError.UnknownError(description: "Invalid encoding name") }
                }
                catch let e { error = e }
            }
            iConvRunning = false
            threadRunning = false
        }
    }

    /*===========================================================================================================================================================================*/
    /// Converts the data from the input stream to UTF-32 characters and stores them in the `charBuffer`. The thread this method runs on will `wait` until there are less than 8K
    /// of characters in the `charBuffer` before storing any more characters into it. It will also wait if another thread is trying to read characters from the `charBuffer`.
    ///
    /// - Parameter iconv: the instance of `IConv`.
    /// - Throws: if a conversion error occurs.
    ///
    @inlinable final func iConvert(_ iconv: IConv) throws {
        try iconv.with(inputStream: inputStream) { bytes, len in
            if len > 0 {
                while notDone && charBuffer.count >= MaxReadAhead { lock.broadcastWait() }
                if notDone { storeCharacters(buffer: bytes, count: len) }
            }

            while notDone && readerWaiting && !charBuffer.isEmpty { lock.broadcastWait() }
            return !notDone
        }
    }

    /*===========================================================================================================================================================================*/
    /// Take `count` UTF-32 characters from the buffer and store them in the `charBuffer`.
    ///
    /// - Parameters:
    ///   - buffer: the buffer.
    ///   - count: the number of UTF-32 characters.
    ///
    @inlinable final func storeCharacters(buffer: UnsafeRawPointer, count: Int) {
        //
        // Because we've told iconv to encode to UTF-32 the value in count should always be a multiple of 4.
        //
        let cc = (count / 4)
        //
        // Cast the buffer as UInt32 words.
        //
        let bf = buffer.bindMemory(to: UInt32.self, capacity: cc)
        //
        // Convert the UInt32 words to characters and store in the buffer.
        //
        for x in (0 ..< cc) { charBuffer.append(Character(scalar: UnicodeScalar(bf[x]))) }
    }

    /*===========================================================================================================================================================================*/
    /// Waits until one of the following and then executes the closure.
    ///
    ///  - 1) characters are available in the buffer
    ///  - 2) the stream is closed
    ///  - 3) the underlying stream is depleted
    ///
    /// - Parameter body: the closure to execute.
    /// - Returns: the value returned from the closure.
    /// - Throws: any exception thrown by the closure or in an I/O error occurs.
    ///
    @inlinable final func waitForChars<T>(_ body: () throws -> T) rethrows -> T {
        try lock.withLock {
            if !value(status, isOneOf: .notOpen, .closed) {
                readerWaiting = true
                while charBuffer.isEmpty && iConvRunning { lock.broadcastWait() }
                readerWaiting = false
            }

            return try body()
        }
    }

    /*===========================================================================================================================================================================*/
    /// If there is an error waiting then throw it, otherwise return the given `value`.
    ///
    /// - Parameter value: the value to return if there is no error waiting.
    /// - Returns: the value.
    /// - Throws: any waiting error.
    ///
    @inlinable final func onError<T>(_ value: T) throws -> T {
        if let e = error {
            status = .error
            throw e
        }
        return value
    }

    /*===========================================================================================================================================================================*/
    /// Holds the characters saved during a mark.
    ///
    @usableFromInline class MarkItem {
        var chars: [Character] = []

        init() {}
    }
}

open class UTF8CharInputStream: IConvCharInputStream {
    public init(inputStream: InputStream) {
        super.init(inputStream: inputStream, encodingName: "UTF-8")
    }

    public init?(fileAtPath: String) {
        guard let inputStream = InputStream(fileAtPath: fileAtPath) else { return nil }
        super.init(inputStream: inputStream, encodingName: "UTF-8")
    }

    public init?(url: URL) {
        guard let inputStream = InputStream(url: url) else { return nil }
        super.init(inputStream: inputStream, encodingName: "UTF-8")
    }

    public init(data: Data) {
        super.init(inputStream: InputStream(data: data), encodingName: "UTF-8")
    }
}
