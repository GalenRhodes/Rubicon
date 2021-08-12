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

public let   LINE_FEED_CODEPOINT: UInt32    = 0x0A
public let   CRLF_CHARACTER:      Character = "\r\n"
public let   CR_CHARACTER:        Character = "\r"
public let   LF_CHARACTER:        Character = "\n"

/*==============================================================================================================*/
/// There is a possibility that the endian of the system is not known. In that case we default to `little` endian
/// because that's the most common these days.
///
internal let ENCODE_TO_NAME:      String    = "UTF-32\((MachineByteOrder == .BigEndian) ? "BE" : "LE")"
/*==============================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet
/// and 4GB of RAM. Even an entry level MacMini comes with 8GB of RAM. So this buffer size is probably a bit on
/// the small side.
///
internal let INPUT_BUFFER_SIZE:   Int       = 256
/*==============================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet
/// and 4GB of RAM. Even an entry level MacMini comes with 8GB of RAM. So this buffer size is probably a bit on
/// the small side.
///
internal let OUTPUT_BUFFER_SIZE:  Int       = ((INPUT_BUFFER_SIZE * MemoryLayout<UInt32>.stride) + MemoryLayout<UInt32>.stride)
/*==============================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet
/// and 4GB of RAM. Even an entry level MacMini comes with 8GB of RAM. So this buffer size is probably a bit on
/// the small side.
///
internal let MAX_READ_AHEAD:      Int       = 65_536

#if !os(Windows)
    open class SimpleIConvCharInputStream: SimpleCharInputStream {
        //@f:0
        /*======================================================================================================*/
        /// `true` if the stream is at the end-of-file.
        ///
        open          var isEOF:             Bool          { (streamStatus == .atEnd)                                                                              }
        /*======================================================================================================*/
        /// `true` if the stream has characters ready to be read.
        ///
        open          var hasCharsAvailable: Bool          { withLock { (isOpen && (hasBChars || (noError && isRunning)))                                        } }
        /*======================================================================================================*/
        /// The error.
        ///
        open          var streamError:       Error?        { withLock { ((isOpen && buffer.isEmpty) ? error : nil)                                               } }
        /*======================================================================================================*/
        /// The status of the `CharInputStream`.
        ///
        open          var streamStatus:      Stream.Status { withLock { (isOpen ? (hasBChars ? .open : (nErr ? (isRunning ? .open : .atEnd) : .error)) : status) } }
        /*======================================================================================================*/
        /// The human readable name of the encoding.
        ///
        public        let encodingName:      String

        internal      let autoClose:         Bool
        internal      let inputStream:       InputStream
        private       let cLock:             Conditional   = Conditional()
        private       var locked:            Bool          = false
        internal      var status:            Stream.Status = .notOpen
        internal      var isRunning:         Bool          = false
        internal      var error:             Error?        = nil
        internal lazy var buffer:            [Character]   = []
        internal      var thread:            Thread?       = nil

        internal      var isOpen:            Bool          { (status == .open)                                                   }
        internal      var nErr:              Bool          { (error == nil)                                                      }
        internal      var noError:           Bool          { (nErr || hasBChars)                                                 }
        internal      var hasBChars:         Bool          { !buffer.isEmpty                                                     }
        internal      var canWait:           Bool          { (isOpen && nErr && isRunning)                                       }
        internal      var inputStreamIsOpen: Bool          { Rubicon.value(inputStream.streamStatus, isOneOf: .closed, .notOpen) }
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
            self.inputStream = inputStream
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

        open func lock() {
            cLock.lock()
        }

        open func unlock() {
            cLock.unlock()
        }

        open func withLock<T>(_ body: () throws -> T) rethrows -> T { try cLock.withLock(body) }

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
        open func append(to chars: inout [Character], maxLength: Int) throws -> Int {
            return try withLock {
                try _append(to: &chars, maxLength: maxLength)
            }
        }

        /*======================================================================================================*/
        /// Open the stream. Once a stream has been opened it can never be re-opened.
        ///
        open func open() { withLock { _open() } }

        /*======================================================================================================*/
        /// Close the stream.
        ///
        open func close() { withLock { _close() } }

        func _read() throws -> Character? {
            while canWait && buffer.isEmpty { cLock.broadcastWait() }
            guard isOpen else { return nil }
            guard noError else { throw error! }
            return buffer.popFirst()
        }

        func _peek() throws -> Character? {
            while canWait && buffer.isEmpty { cLock.broadcastWait() }
            guard isOpen else { return nil }
            guard noError else { throw error! }
            return buffer.first
        }

        func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
            guard isOpen else { return 0 }
            let ln = ((maxLength < 0) ? Int.max : maxLength)
            var cc = 0
            while cc < ln {
                while canWait && buffer.isEmpty {
                    cLock.broadcastWait()
                }

                guard isOpen else { break }
                guard noError else { throw error! }
                guard hasBChars else { break }

                let i = min(buffer.count, (ln - cc))
                let r = (0 ..< i)

                chars.append(contentsOf: buffer[r])
                buffer.removeSubrange(r)
                cc += i
                //if canWait { cLock.broadcastWait() }
            }

            return cc
        }

        func _open() {
            guard status == .notOpen else { return }
            status = .open
            isRunning = true
            thread = Thread { [weak self] in
                var hangingCR = false
                let input     = EasyByteBuffer(length: INPUT_BUFFER_SIZE)
                let output    = EasyByteBuffer(length: OUTPUT_BUFFER_SIZE)
                let iconv     = IConv(toEncoding: ENCODE_TO_NAME, fromEncoding: (self?.encodingName ?? "UTF-8"), ignoreErrors: true, enableTransliterate: true)
                defer { iconv.close() }
                while let s = self { guard s.doBackground(iconv, input, output, &hangingCR) else { break } }
            }
            thread?.qualityOfService = .utility
            thread?.start()
        }

        func _close() {
            guard status == .open else { return }
            status = .closed
            while isRunning { cLock.broadcastWait() }
            buffer.removeAll()
            error = nil
        }

        func doBackground(_ iconv: IConv, _ input: EasyByteBuffer, _ output: EasyByteBuffer, _ hangingCR: inout Bool) -> Bool {
            withLock {
                isRunning = doBackgroundRead(iconv, input, output, &hangingCR)
                if !isRunning { doEndGame(iconv, input, output, hangingCR) }
                return isRunning
            }
        }

        func doBackgroundRead(_ iconv: IConv, _ input: EasyByteBuffer, _ output: EasyByteBuffer, _ hangingCR: inout Bool) -> Bool {
            do {
                guard isOpen else { return false }
                if inputStream.streamStatus == .notOpen {
                    inputStream.open()
                }
                while buffer.count >= MAX_READ_AHEAD { guard cLock.broadcastWait(until: Date(timeIntervalSinceNow: 0.25)) && isOpen else { return isOpen } }
                return try readChars(iconv: iconv, input: input, output: output, hangingCR: &hangingCR)
            }
            catch let e {
                error = e
                return false
            }
        }

        func readChars(iconv: IConv, input: EasyByteBuffer, output: EasyByteBuffer, hangingCR: inout Bool) throws -> Bool {
            guard try isOpen && inputStream.read(to: input) > 0 else { return false }
            let results = iconv.convert(input: input, output: output)
            try handleLastIConvResults(iConvResults: results, output: output, hangingCR: &hangingCR, isFinal: false)
            return true
        }

        func handleLastIConvResults(iConvResults res: IConv.Results, output: EasyByteBuffer, hangingCR: inout Bool, isFinal f: Bool) throws {
            switch res {
                case .UnknownEncoding:    throw CharStreamError.UnknownCharacterEncoding(description: encodingName)
                case .OtherError:         throw StreamError.UnknownError()
                case .IncompleteSequence: storeChars(output, &hangingCR); if f { buffer <+ UnicodeReplacementChar }
                default:                  storeChars(output, &hangingCR)
            }
        }

        func storeChars(_ output: EasyByteBuffer, _ hangingCR: inout Bool) {
            output.withBufferAs(type: UInt32.self) { (p: UnsafeMutablePointer<UInt32>, length: Int, count: inout Int) -> Void in
                guard count > 0 else { hangingCR = false; return }
                var idx = storeHangingCR(data: p, hangingCR: &hangingCR)
                while idx < count { hangingCR = storeNextChar(data: p, count: count, index: &idx) }
            }
        }

        func storeNextChar(data p: UnsafeMutablePointer<UInt32>, count: Int, index idx: inout Int) -> Bool {
            var ch = Character(codePoint: p[idx++])
            if ch == CR_CHARACTER {
                guard idx < count else { return true }
                if p[idx] == LINE_FEED_CODEPOINT {
                    ch = CRLF_CHARACTER
                    idx++
                }
            }
            buffer <+ ch
            return false
        }

        func storeHangingCR(data p: UnsafeMutablePointer<UInt32>, hangingCR: inout Bool) -> Int {
            var idx = 0
            if hangingCR {
                hangingCR = false
                if p[idx] == LINE_FEED_CODEPOINT {
                    buffer.append(CRLF_CHARACTER)
                    idx++
                }
            }
            return idx
        }

        func doEndGame(_ iconv: IConv, _ input: EasyByteBuffer, _ output: EasyByteBuffer, _ hangingCR: Bool) {
            var hangingCR = hangingCR
            do {
                if autoClose && inputStreamIsOpen { inputStream.close() }
                if input.count > 0 {
                    let r = iconv.convert(input: input, output: output)
                    try handleLastIConvResults(iConvResults: r, output: output, hangingCR: &hangingCR, isFinal: false)
                }
                let r = iconv.finalConvert(output: output)
                try handleLastIConvResults(iConvResults: r, output: output, hangingCR: &hangingCR, isFinal: true)
            }
            catch let e {
                error = e
            }
        }
    }
#endif
