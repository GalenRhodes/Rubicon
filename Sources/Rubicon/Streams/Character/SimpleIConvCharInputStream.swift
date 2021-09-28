/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 3/28/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation
import Chadakoin

public let LINE_FEED_CODEPOINT: UInt32    = 0x0A
public let CRLF_CHARACTER:      Character = "\r\n"
public let CR_CHARACTER:        Character = "\r"
public let LF_CHARACTER:        Character = "\n"

/*==============================================================================================================*/
/// There is a possibility that the endian of the system is not known. In that case we default to `little` endian
/// because that's the most common these days.
///
@usableFromInline let ENCODE_TO_NAME:     String = "UTF-32\((MachineByteOrder == .BigEndian) ? "BE" : "LE")"
/*==============================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet
/// and 4GB of RAM. Even an entry level MacMini comes with 8GB of RAM. So this buffer size is probably a bit on
/// the small side.
///
@usableFromInline let INPUT_BUFFER_SIZE:  Int    = 256
/*==============================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet
/// and 4GB of RAM. Even an entry level MacMini comes with 8GB of RAM. So this buffer size is probably a bit on
/// the small side.
///
@usableFromInline let OUTPUT_BUFFER_SIZE: Int    = ((INPUT_BUFFER_SIZE * MemoryLayout<UInt32>.stride) + MemoryLayout<UInt32>.stride)
/*==============================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet
/// and 4GB of RAM. Even an entry level MacMini comes with 8GB of RAM. So this buffer size is probably a bit on
/// the small side.
///
@usableFromInline let MAX_READ_AHEAD:     Int    = 65_536

#if !os(Windows)
    open class SimpleIConvCharInputStream: SimpleCharInputStream {
        //@f:0
        /*======================================================================================================*/
        /// `true` if the stream is at the end-of-file.
        ///
        open              var isEOF:             Bool          { (streamStatus == .atEnd)                                                                                 }
        /*======================================================================================================*/
        /// `true` if the stream has characters ready to be read.
        ///
        open              var hasCharsAvailable: Bool          { withLock { (isOpen && (hasBChars || (noError && thread.isRunning)))                                    } }
        /*======================================================================================================*/
        /// The error.
        ///
        open              var streamError:       Error?        { withLock { ((isOpen && cBuf.isEmpty) ? err : nil)                                                      } }
        /*======================================================================================================*/
        /// The status of the `CharInputStream`.
        ///
        open              var streamStatus:      Stream.Status { withLock { (isOpen ? (hasBChars ? .open : (nErr ? (thread.isRunning ? .open : .atEnd) : .error)) : st) } }
        /*======================================================================================================*/
        /// The human readable name of the encoding.
        ///
        public                 let encodingName:      String

        @usableFromInline      let autoClose:         Bool
        @usableFromInline      let input:             InputStream
        @usableFromInline      var st:                Stream.Status = .notOpen
        @usableFromInline      var err:               Error?        = nil
        @usableFromInline      var cBuf:              [Character]   = []
        @usableFromInline      let cLck:              Conditional   = Conditional()
        @usableFromInline      let iLck:              MutexLock     = MutexLock()
        @usableFromInline lazy var thread:            IC            = IC(encodingName) { [weak self] in while let s = self, s._doRead() {} }
        //@f:1

        /*======================================================================================================*/
        /// Creates a new instance of IConvCharInputStream with the given InputStream, encodingName, and whether
        /// or not the given InputStream should be closed when this stream is discarded or closed.
        ///
        /// - Parameters:
        ///   - inputStream: The underlying byte InputStream.
        ///   - encodingName: The character encoding name.
        ///   - autoClose: If `true` then the underlying byte InputStream will be closed when this
        ///                IConvCharInputStream is closed or discarded.
        ///
        public init(inputStream: InputStream, encodingName: String, autoClose: Bool = true) {
            self.encodingName = encodingName
            self.autoClose = autoClose
            self.input = inputStream
        }

        /*======================================================================================================*/
        /// Creates a new instance of IConvCharInputStream with the given URL and encodingName. If opening a
        /// stream with the URL fails then `nil` is returned.
        ///
        /// - Parameters:
        ///   - url: The URL.
        ///   - encodingName: The character encoding name.
        ///   - options: The options for reading from the URL.
        ///   - authenticate: The callback closure to handle authentication challenges.
        ///
        public convenience init?(url: URL, encodingName: String, options: URLInputStreamOptions = [], authenticate: AuthenticationCallback? = nil) {
            guard let stream = try? InputStream.getInputStream(url: url, options: options, authenticate: authenticate) else { return nil }
            self.init(inputStream: stream, encodingName: encodingName, autoClose: true)
        }

        /*======================================================================================================*/
        /// Creates a new instance of IConvCharInputStream with the given filename and encodingName. If opening a
        /// stream with the filename fails then `nil` is returned.
        ///
        /// - Parameters:
        ///   - fileAtPath: The filename.
        ///   - encodingName: The character encoding name.
        ///
        public convenience init?(fileAtPath: String, encodingName: String) {
            guard let stream = InputStream(fileAtPath: fileAtPath) else { return nil }
            self.init(inputStream: stream, encodingName: encodingName, autoClose: true)
        }

        /*======================================================================================================*/
        /// Creates a new instance of IConvCharInputStream with the given bytes and encodingName.
        ///
        /// - Parameters:
        ///   - data: The bytes to read.
        ///   - encodingName: The character encoding name.
        ///
        public convenience init(data: Data, encodingName: String) {
            self.init(inputStream: InputStream(data: data), encodingName: encodingName, autoClose: true)
        }

        /*======================================================================================================*/
        /// Read one character.
        ///
        /// - Returns: The next character or `nil` if EOF.
        /// - Throws: If an I/O error occurs.
        ///
        open func read() throws -> Character? { try withLock { try _read() } }

        /*======================================================================================================*/
        /// Read and return one character without actually removing it from the input stream.
        ///
        /// - Returns: The next character or `nil` if EOF.
        /// - Throws: If an I/O error occurs.
        ///
        open func peek() throws -> Character? { try withLock { try _peek() } }

        /*======================================================================================================*/
        /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the
        /// stream and append them to the given character array. This method is identical to
        /// `read(chars:,maxLength:)` except that the receiving array is not cleared before the data is read.
        ///
        /// - Parameters:
        ///   - chars: The <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive
        ///            the <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
        ///   - maxLength: The maximum number of
        ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to
        ///                receive. If -1 then all
        ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s
        ///                are read until the end-of-file.
        /// - Returns: The number of
        ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read.
        ///            Will return 0 (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at
        ///            end-of-file.
        /// - Throws: If an I/O error occurs.
        ///
        open func append(to chars: inout [Character], maxLength: Int) throws -> Int { try withLock { try _append(to: &chars, maxLength: maxLength) } }

        /*======================================================================================================*/
        /// Open the stream. Once a stream has been opened it can never be re-opened.
        ///
        open func open() { withLock { _open() } }

        /*======================================================================================================*/
        /// Close the stream.
        ///
        open func close() { withLock { _close() } }

        func _read() throws -> Character? { try _waitForChar { cBuf.popFirst() } }

        func _peek() throws -> Character? { try _waitForChar { cBuf.first } }

        func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
            guard isOpen else { return 0 }
            let ln = ((maxLength < 0) ? Int.max : maxLength)
            var cc = 0
            while cc < ln {
                guard try _waitForChars() && hasBChars else { break }
                let i = min(cBuf.count, (ln - cc))
                let r = (0 ..< i)
                chars.append(contentsOf: cBuf[r])
                cBuf.removeSubrange(r)
                cc += i
            }

            return cc
        }

        func _open() {
            guard st == .notOpen else { return }
            st = .open
            thread.start()
        }

        func _close() {
            guard st == .open else { return }
            st = .closed
            while thread.isRunning { cLck.broadcastWait() }
            cBuf.removeAll()
            err = nil
        }

        @usableFromInline class IC: PGThread {
            @usableFromInline let ic:   IConv
            @usableFromInline let iBuf: EasyByteBuffer = EasyByteBuffer(length: INPUT_BUFFER_SIZE)
            @usableFromInline let oBuf: EasyByteBuffer = EasyByteBuffer(length: OUTPUT_BUFFER_SIZE)
            @usableFromInline var hcr:  Bool           = false

            @usableFromInline init(_ eName: String, _ block: @escaping PGThread.PGThreadBlock) {
                self.ic = IConv(toEncoding: ENCODE_TO_NAME, fromEncoding: eName, ignoreErrors: true, enableTransliterate: true)
                super.init(startNow: false, qualityOfService: .utility, block: block)
            }

            deinit { ic.close() }

            @usableFromInline func processNextBlock(_ input: InputStream, _ lock: Conditional, _ cBuf: inout [Character], _ err: inout Error?, _ isOpen: @autoclosure () -> Bool) -> Bool {
                lock.withLock {
                    do {
                        guard isOpen() else { return false }
                        if input.streamStatus == .notOpen { input.open() }
                        while cBuf.count >= MAX_READ_AHEAD { guard lock.broadcastWait(until: Date(timeIntervalSinceNow: 2.0)) else { return isOpen() } }
                        guard try isOpen() && input.read(to: iBuf) > 0 else { return try doEndGame(output: &cBuf) }
                        return try doConv(output: &cBuf, final: false)
                    }
                    catch let e {
                        err = e
                        return (try? doEndGame(output: &cBuf)) ?? false
                    }
                }
            }
        }
    }

    extension SimpleIConvCharInputStream {
        @inlinable var isOpen:            Bool { (st == .open) }
        @inlinable var nErr:              Bool { (err == nil) }
        @inlinable var noError:           Bool { (nErr || hasBChars) }
        @inlinable var hasBChars:         Bool { !cBuf.isEmpty }
        @inlinable var canWait:           Bool { (isOpen && nErr && thread.isRunning) }
        @inlinable var inputStreamIsOpen: Bool { !Rubicon.value(input.streamStatus, isOneOf: .closed, .notOpen) }

        @inlinable public func withLock<T>(_ body: () throws -> T) rethrows -> T { try cLck.withLock(body) }

        @inlinable func _waitForChars() throws -> Bool {
            while canWait && cBuf.isEmpty { cLck.broadcastWait() }
            guard isOpen else { return false }
            guard noError else { throw err! }
            return true
        }

        @inlinable func _waitForChar(_ body: () throws -> Character?) throws -> Character? { try _waitForChars() ? try body() : nil }

        @inlinable func _closeInput() { if autoClose && inputStreamIsOpen { input.close() } }

        @inlinable func _doRead() -> Bool { thread.processNextBlock(input, cLck, &cBuf, &err, isOpen) }
    }

    extension SimpleIConvCharInputStream.IC {
        @inlinable var isRunning: Bool { isStarted && !isDone }

        @discardableResult @inlinable func doConv(output cBuf: inout [Character], final f: Bool) throws -> Bool {
            let results: IConv.Results = (f ? ic.finalConvert(output: oBuf) : ic.convert(input: iBuf, output: oBuf))
            try handleLastIConvResults(iConvResults: results, output: &cBuf, final: f)
            return true
        }

        @inlinable func doEndGame(output cBuf: inout [Character]) throws -> Bool {
            if iBuf.count > 0 { try doConv(output: &cBuf, final: false) }
            try doConv(output: &cBuf, final: true)
            return false
        }

        @inlinable func handleLastIConvResults(iConvResults res: IConv.Results, output cBuf: inout [Character], final f: Bool) throws {
            switch res {
                case .UnknownEncoding:
                    throw CharStreamError.UnknownCharacterEncoding(description: ic.fromEncoding)
                case .OtherError:
                    throw StreamError.UnknownError()
                case .IncompleteSequence:
                    storeChars(output: &cBuf)
                    if f { cBuf <+ UnicodeReplacementChar }
                default:
                    storeChars(output: &cBuf)
            }
        }

        @inlinable func storeChars(output cBuf: inout [Character]) {
            oBuf.withBufferAs(type: UInt32.self) { (p: UnsafeMutablePointer<UInt32>, length: Int, count: inout Int) -> Void in
                guard count > 0 else { hcr = false; return }
                var idx = storeHangingCR(data: p, output: &cBuf)
                while idx < count { hcr = storeNextChar(data: p, count: count, index: &idx, output: &cBuf) }
            }
        }

        @inlinable func storeHangingCR(data p: UnsafeMutablePointer<UInt32>, output cBuf: inout [Character]) -> Int {
            var idx = 0
            if hcr {
                hcr = false
                if p[idx] == LINE_FEED_CODEPOINT {
                    cBuf.append(CRLF_CHARACTER)
                    idx++
                }
            }
            return idx
        }

        @inlinable func storeNextChar(data p: UnsafeMutablePointer<UInt32>, count: Int, index idx: inout Int, output cBuf: inout [Character]) -> Bool {
            var ch = Character(codePoint: p[idx++])
            if ch == CR_CHARACTER {
                guard idx < count else { return true }
                if p[idx] == LINE_FEED_CODEPOINT {
                    ch = CRLF_CHARACTER
                    idx++
                }
            }
            cBuf <+ ch
            return false
        }
    }
#endif
