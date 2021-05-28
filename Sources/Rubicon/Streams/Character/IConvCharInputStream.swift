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
#if os(Linux)
    import iconv
#endif

open class IConvCharInputStream: CharInputStream {

    #if DEBUG
        private let maxReadAhead:       Int = 1000
        private let readAheadBlockSize: Int = 100
    #else
        private let maxReadAhead:       Int = MAX_READ_AHEAD
        private let readAheadBlockSize: Int = INPUT_BUFFER_SIZE
    #endif

    private typealias MarkTuple = (char: Character, pos: TextPosition)

    private enum ReadState {
        case None
        case Reading
        case Closing
    }

    //@f:0
    /*==========================================================================================================*/
    /// The number of spaces in each tab stop.
    ///
    open         var tabWidth:          Int8          { get { lock.withLock { tab } } set { lock.withLock { tab = newValue }                                    } }
    /*==========================================================================================================*/
    /// The number of marks on the stream.
    ///
    open         var markCount:         Int           { lock.withLock { marks.count                                                                             } }
    /*==========================================================================================================*/
    /// The current line and column numbers.
    ///
    open         var position:          TextPosition  { lock.withLock { pos                                                                                     } }
    /*==========================================================================================================*/
    /// The error.
    ///
    open         var streamError:       Error?        { lock.withLock { (isOpen ? error : nil)                                                                  } }
    /*==========================================================================================================*/
    /// The status of the `CharInputStream`.
    ///
    open         var streamStatus:      Stream.Status { lock.withLock { (isOpen ? (noBChars ? (nErr ? (isRunning ? .open : .atEnd) : .error) : .open) : status) } }
    /*==========================================================================================================*/
    /// `true` if the stream is at the end-of-file.
    ///
    open         var isEOF:             Bool          { (streamStatus == .atEnd)                                                                                  }
    /*==========================================================================================================*/
    /// `true` if the stream has characters ready to be read.
    ///
    open         var hasCharsAvailable: Bool          { lock.withLock { (isOpen && (hasBChars || (nErr && isRunning)))                                          } }
    /*==========================================================================================================*/
    /// The human readable name of the encoding.
    ///
    open         var encodingName:      String        { lock.withLock { inputStream.encodingName                                                                } }

    private      let inputStream:       SimpleCharInputStream
    private      var isRunning:         Bool          = false
    private      var isReading:         AtomicValue<ReadState> = AtomicValue(initialValue: .None)
    private lazy var buffer:            [Character]   = []
    private lazy var marks:             [MarkItem]    = []
    private      var tab:               Int8          = 4
    private lazy var lock:              Conditional   = Conditional()
    private lazy var queue:             DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, autoreleaseFrequency: .inherit)
    private      var pos:               TextPosition  = (0, 0)
    private      var error:             Error?        = nil
    private      var status:            Stream.Status = .notOpen

    private      var nErr:              Bool          { (error == nil)                }
    private      var isOpen:            Bool          { (status == .open)             }
    private      var noError:           Bool          { (nErr || hasBChars)           }
    private      var isGood:            Bool          { (isOpen && noError)           }
    private      var canWait:           Bool          { (isOpen && nErr && isRunning) }
    private      var hasBChars:         Bool          { !buffer.isEmpty               }
    private      var noBChars:          Bool          { buffer.isEmpty                }
    //@f:1

    public init(inputStream: InputStream, encodingName: String, autoClose: Bool = true) {
        self.inputStream = SimpleIConvCharInputStream(inputStream: inputStream, encodingName: encodingName, autoClose: autoClose)
    }

    public convenience init(filename: String, encodingName: String) throws {
        guard let stream = InputStream(fileAtPath: filename) else { throw StreamError.FileNotFound(description: filename) }
        self.init(inputStream: stream, encodingName: encodingName, autoClose: true)
    }

    public convenience init(url: URL, encodingName: String) throws {
        guard let stream = InputStream(url: url) else { throw StreamError.FileNotFound(description: url.absoluteString) }
        self.init(inputStream: stream, encodingName: encodingName, autoClose: true)
    }

    public convenience init(data: Data, encodingName: String) {
        self.init(inputStream: InputStream(data: data), encodingName: encodingName, autoClose: true)
    }

    deinit { if inputStreamIsOpen { inputStream.close() } }

    /*==========================================================================================================*/
    /// Open the stream. Once a stream has been opened it can never be re-opened.
    ///
    open func open() {
        lock.withLock {
            guard status == .notOpen else { return }
            pos = (1, 1)
            status = .open
            isRunning = true
            queue.async { [weak self] in while let s = self { guard s.doBackground() else { break } } }
        }
    }

    /*==========================================================================================================*/
    /// Close the stream.
    ///
    open func close() {
        isReading.waitUntil(valueIn: .None, thenWithVal: .Closing) {
            lock.withLock {
                guard isOpen else { return }
                status = .closed
                while isRunning { lock.broadcastWait() }
                error = nil
                pos = (0, 0)
                buffer.removeAll()
                marks.removeAll()
            }
        }
    }

    /*==========================================================================================================*/
    /// Read one character.
    /// 
    /// - Returns: The next character or `nil` if EOF.
    /// - Throws: If an I/O error occurs.
    ///
    open func read() throws -> Character? {
        nDebug(.In, "Read Character")
        defer { nDebug(.Out, "Read Character") }
        return try isReading.waitUntil(valueIn: .None, thenWithVal: .Reading) {
            try lock.withLock {
                while buffer.isEmpty && canWait { lock.broadcastWait() }

                guard isOpen else { return nil }
                guard noError else { throw error! }
                guard let ch = buffer.popFirst() else { return nil }

                if let mi = marks.last { mi.chars <+ (ch, pos) }
                textPositionUpdate(ch, pos: &pos, tabWidth: tab)
                return ch
            }
        }
    }

    /*==========================================================================================================*/
    /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the stream
    /// and append them to the given character array. This method is identical to `read(chars:,maxLength:)` except
    /// that the receiving array is not cleared before the data is read.
    /// 
    /// - Parameters:
    ///   - chars: The <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive the
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
    ///   - maxLength: The maximum number of
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to
    ///                receive. If -1 then all
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s are
    ///                read until the end-of-file.
    /// - Returns: The number of
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will
    ///            return 0 (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at
    ///            end-of-file.
    /// - Throws: If an I/O error occurs.
    ///
    open func append(to chars: inout [Character], maxLength: Int) throws -> Int {
        nDebug(.In, "Read Multiple Characters")
        defer { nDebug(.Out, "Read Multiple Characters") }
        return try isReading.waitUntil(valueIn: .None, thenWithVal: .Reading) {
            try lock.withLock {
                guard isOpen else { return 0 }
                guard noError else { throw error! }

                var cc = 0
                let ln = fixLength(maxLength)

                while cc < ln {
                    while buffer.isEmpty && canWait { lock.broadcastWait() }

                    guard isOpen else { break }
                    guard noError else {
                        if cc > 0 { break }
                        else { throw error! }
                    }

                    if buffer.isEmpty { break }
                    cc += try readBufferedChars(to: &chars, maxLength: (ln - cc))
                }

                return cc
            }
        }
    }

    /*==========================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark
    /// but all operations happen on the most recently set mark.
    ///
    open func markSet() {
        lock.withLock {
            marks <+ MarkItem(pos: pos)
        }
    }

    /*==========================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    open func markDelete() {
        lock.withLock {
            marks.popLast()
        }
    }

    /*==========================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    open func markReturn() {
        lock.withLock {
            guard let mi = marks.popLast() else { return }
            pos = mi.pos
            buffer.insert(contentsOf: mi.chars.map { $0.char }, at: 0)
        }
    }

    /*==========================================================================================================*/
    /// Updates the most recently set mark to the current position. If there was no previously set mark then a new
    /// one is created. This is functionally equivalent to performing a `markDelete()` followed immediately by a
    /// `markSet()`.
    ///
    open func markUpdate() {
        lock.withLock {
            if let mi = marks.last {
                mi.pos = pos
                mi.chars.removeAll(keepingCapacity: true)
            }
            else {
                marks <+ MarkItem(pos: pos)
            }
        }
    }

    /*==========================================================================================================*/
    /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a new
    /// one is created. This is functionally equivalent to performing a `markReturn()` followed immediately by a
    /// `markSet()`.
    ///
    open func markReset() {
        lock.withLock {
            if let mi = marks.last {
                pos = mi.pos
                buffer.insert(contentsOf: mi.chars.map { $0.char }, at: 0)
                mi.chars.removeAll(keepingCapacity: true)
            }
            else {
                marks <+ MarkItem(pos: pos)
            }
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
        guard count > 0 else { return 0 }
        return lock.withLock {
            guard let mi = marks.last else { return 0 }
            let cc = min(count, mi.chars.count)
            let ix = (mi.chars.endIndex - cc)
            let rn = (ix ..< mi.chars.endIndex)

            pos = mi.chars[ix].pos
            buffer.insert(contentsOf: mi.chars[rn].map { $0.char }, at: 0)
            mi.chars.removeSubrange(rn)
            return cc
        }
    }

    private func readBufferedChars(to chars: inout [Character], maxLength ln: Int) throws -> Int {
        let x = min(ln, buffer.count)
        guard x > 0 else { return 0 }
        let r = (0 ..< x)
        let m = marks.last

        buffer[r].forEach { ch in
            if let mi = m { mi.chars <+ (ch, pos) }
            textPositionUpdate(ch, pos: &pos, tabWidth: tab)
            chars <+ ch
        }

        buffer.removeSubrange(r)
        return x
    }

    private class MarkItem {
        var pos:   TextPosition
        var chars: [MarkTuple] = []

        init(pos: TextPosition) { self.pos = pos }
    }

    private var inputStreamIsOpen: Bool { !Rubicon.value(inputStream.streamStatus, isOneOf: .closed, .notOpen) }

    private func doBackground() -> Bool {
        lock.withLock {
            isRunning = doBackgroundRead()
            if !isRunning && inputStreamIsOpen { inputStream.close() }
            return isRunning
        }
    }

    private func doBackgroundRead() -> Bool {
        do {
            guard isOpen else { return false }
            if inputStream.streamStatus == .notOpen {
                inputStream.open()
                if let e = inputStream.streamError { throw e }
            }
            while buffer.count > maxReadAhead { guard lock.broadcastWait(until: Date(timeIntervalSinceNow: 1.0)) && isOpen else { return isOpen } }
            let cc = try inputStream.append(to: &buffer, maxLength: readAheadBlockSize)
            return (cc > 0)
        }
        catch let e {
            error = e
            return false
        }
    }
}
