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

public let   LINE_FEED_CODEPOINT: UInt32    = 0x0A
public let   CRLF_CHARACTER:      Character = "\r\n"
public let   CR_CHARACTER:        Character = "\r"
public let   LF_CHARACTER:        Character = "\n"

/*===============================================================================================================================================================================*/
/// There is a possibility that the endian of the system is not known. In that case we default to `little` endian because that's the most common these days.
///
internal let ENCODE_TO_NAME:      String    = "UTF-32\((MachineByteOrder == .BigEndian) ? "BE" : "LE")"
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
internal let INPUT_BUFFER_SIZE:   Int       = 256
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
internal let OUTPUT_BUFFER_SIZE:  Int       = ((INPUT_BUFFER_SIZE * MemoryLayout<UInt32>.stride) + MemoryLayout<UInt32>.stride)
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
internal let MAX_READ_AHEAD:      Int       = 65_536

open class SimpleIConvCharInputStream: SimpleCharInputStream {
    //@f:0
    public       var isEOF:             Bool          { (streamStatus == .atEnd)                                                                                   }
    public       var hasCharsAvailable: Bool          { lock.withLock { (isOpen && (hasBChars || (noError && isRunning)))                                        } }
    public       var streamError:       Error?        { lock.withLock { ((isOpen && buffer.isEmpty) ? error : nil)                                               } }
    public       var streamStatus:      Stream.Status { lock.withLock { (isOpen ? (hasBChars ? .open : (nErr ? (isRunning ? .open : .atEnd) : .error)) : status) } }
    public       let encodingName:      String

    private      let autoClose:         Bool
    private      let inputStream:       InputStream
    private lazy var lock:              Conditional   = Conditional()
    private      var status:            Stream.Status = .notOpen
    private      var isRunning:         Bool          = false
    private      var error:             Error?        = nil
    private lazy var buffer:            [Character]   = []
    private lazy var queue:             DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, autoreleaseFrequency: .workItem)

    private      var isOpen:            Bool          { (status == .open)                }
    private      var nErr:              Bool          { (error == nil)                   }
    private      var noError:           Bool          { (nErr || hasBChars)              }
    private      var hasBChars:         Bool          { !buffer.isEmpty                  }
    private      var canWait:           Bool          { (isOpen && nErr && isRunning)    }
    //@f:1

    public init(inputStream: InputStream, encodingName: String, autoClose: Bool = true) {
        self.encodingName = encodingName
        self.autoClose = autoClose
        self.inputStream = inputStream
    }

    public func read() throws -> Character? {
        try lock.withLock {
            while canWait && buffer.isEmpty { lock.broadcastWait() }
            guard isOpen else { return nil }
            guard noError else { throw error! }
            return buffer.popFirst()
        }
    }

    public func append(to chars: inout [Character], maxLength: Int) throws -> Int {
        try lock.withLock {
            guard isOpen else { return 0 }
            let ln = ((maxLength < 0) ? Int.max : maxLength)
            var cc = 0

            while cc < maxLength {
                while canWait && buffer.isEmpty { lock.broadcastWait() }

                guard isOpen else { break }
                guard noError else { throw error! }
                guard hasBChars else { break }

                let i = min(buffer.count, (ln - cc))
                let r = (0 ..< i)

                chars.append(contentsOf: buffer[r])
                buffer.removeSubrange(r)
                cc += i
                if canWait { lock.broadcastWait() }
            }

            return cc
        }
    }

    public func open() {
        lock.withLock {
            guard status == .notOpen else { return }
            status = .open
            isRunning = true
            queue.async { [weak self] in if let s = self { s.readerThread() } }
        }
    }

    public func close() {
        lock.withLock {
            guard status == .open else { return }
            status = .closed
            while isRunning { lock.broadcastWait() }
            buffer.removeAll()
            error = nil
        }
    }

    private func readerThread() {
        lock.withLock {
            do {
                var hangingCR = false
                let input     = EasyByteBuffer(length: INPUT_BUFFER_SIZE)
                let output    = EasyByteBuffer(length: OUTPUT_BUFFER_SIZE)
                let iconv     = IConv(toEncoding: ENCODE_TO_NAME, fromEncoding: encodingName, ignoreErrors: true, enableTransliterate: true)

                defer { isRunning = false }
                defer { iconv.close() }

                if inputStream.streamStatus == .notOpen { inputStream.open() }
                guard inputStream.streamError == nil else { throw inputStream.streamError! }
                defer { if autoClose { inputStream.close() } }

                while isOpen {
                    while isOpen && buffer.count >= MAX_READ_AHEAD { lock.broadcastWait() }
                    guard try readChars(iconv: iconv, input: input, output: output, hangingCR: &hangingCR) else { break }
                }

                if isOpen { try readerThreadEnding(iconv: iconv, input: input, output: output, hangingCR: &hangingCR) }
            }
            catch let e {
                error = e
            }
        }
    }

    private func readChars(iconv: IConv, input: EasyByteBuffer, output: EasyByteBuffer, hangingCR: inout Bool) throws -> Bool {
        guard try isOpen && inputStream.read(to: input) > 0 else { return false }
        let results = iconv.convert(input: input, output: output)
        try handleLastIConvResults(iConvResults: results, output: output, hangingCR: &hangingCR, isFinal: false)
        return true
    }

    private func readerThreadEnding(iconv: IConv, input: EasyByteBuffer, output: EasyByteBuffer, hangingCR: inout Bool) throws {
        if input.count > 0 {
            let r = iconv.convert(input: input, output: output)
            try handleLastIConvResults(iConvResults: r, output: output, hangingCR: &hangingCR, isFinal: true)
        }

        let r = iconv.finalConvert(output: output)
        try handleLastIConvResults(iConvResults: r, output: output, hangingCR: &hangingCR, isFinal: true)
    }

    private func handleLastIConvResults(iConvResults res: IConv.Results, output: EasyByteBuffer, hangingCR: inout Bool, isFinal f: Bool) throws {
        switch res {
            case .UnknownEncoding:    throw CharStreamError.UnknownCharacterEncoding(description: encodingName)
            case .OtherError:         throw StreamError.UnknownError()
            case .IncompleteSequence: storeChars(output, &hangingCR); if f { buffer <+ UnicodeReplacementChar }
            default:                  storeChars(output, &hangingCR)
        }
    }

    private func storeChars(_ output: EasyByteBuffer, _ hangingCR: inout Bool) {
        output.withBufferAs(type: UInt32.self) { (p: UnsafeMutablePointer<UInt32>, length: Int, count: inout Int) -> Void in
            guard count > 0 else { hangingCR = false; return }
            var idx = storeHangingCR(data: p, hangingCR: &hangingCR)
            while idx < count { hangingCR = storeNextChar(data: p, count: count, index: &idx) }
        }
    }

    private func storeNextChar(data p: UnsafeMutablePointer<UInt32>, count: Int, index idx: inout Int) -> Bool {
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

    private func storeHangingCR(data p: UnsafeMutablePointer<UInt32>, hangingCR: inout Bool) -> Int {
        var idx = 0

        if hangingCR {
            hangingCR = false

            if p[idx] == LINE_FEED_CODEPOINT {
                idx++
                buffer.append(CRLF_CHARACTER)
            }
        }

        return idx
    }
}
