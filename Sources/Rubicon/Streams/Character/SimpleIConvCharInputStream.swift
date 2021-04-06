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

public let      LINE_FEED_CODEPOINT: UInt32    = 0x0A
public let      LFCR_CHARACTER:      Character = "\r\n"
public let      CR_CHARACTER:        Character = "\r"
public let      LF_CHARACTER:        Character = "\n"

/*===============================================================================================================================================================================*/
/// There is a possibility that the endian of the system is not known. In that case we default to `little` endian because that's the most common these days.
///
fileprivate let ENCODE_TO_NAME:      String    = "UTF-32\((CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue) ? "BE" : "LE")"
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
fileprivate let INPUT_BUFFER_SIZE:   Int       = 65_536
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
fileprivate let OUTPUT_BUFFER_SIZE:  Int       = ((INPUT_BUFFER_SIZE * MemoryLayout<UInt32>.stride) + MemoryLayout<UInt32>.stride)
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
fileprivate let MAX_READ_AHEAD:      Int       = 262_144

open class SimpleIConvCharInputStream: SimpleCharInputStream {
    //@f:0
    /*===========================================================================================================================================================================*/
    /// `true` if the stream has characters ready to be read.
    ///
    open                     var hasCharsAvailable: Bool          { lock.withLock { hasChars               } }
    /*===========================================================================================================================================================================*/
    /// `true` if the stream is at the end-of-file.
    ///
    open                     var isEOF:             Bool          { !hasCharsAvailable                       }
    /*===========================================================================================================================================================================*/
    /// The error.
    ///
    open                     var streamError:       Error?        { lock.withLock { (isOpen ? error : nil) } }
    /*===========================================================================================================================================================================*/
    /// The status of the `CharInputStream`.
    ///
    open                     var streamStatus:      Stream.Status { lock.withLock { effectiveStatus        } }
    /*===========================================================================================================================================================================*/
    /// The human readable name of the encoding.
    ///
    public                   let encodingName:      String

    @usableFromInline        let inputStream:       InputStream
    @usableFromInline        let autoClose:         Bool
    @usableFromInline        var running:           Bool          = false
    @usableFromInline        var error:             Error?        = nil
    @usableFromInline        var buffer:            [Character]   = []
    @usableFromInline        var status:            Stream.Status = .notOpen
    @usableFromInline   lazy var queue:             DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, autoreleaseFrequency: .workItem)
    @usableFromInline   lazy var lock:              Conditional   = Conditional()

    @inlinable         final var isOpen:            Bool          { (status == .open)                                                     }
    @inlinable         final var hasError:          Bool          { (error != nil)                                                        }
    @inlinable         final var isGood:            Bool          { (isOpen && !hasError)                                                 }
    @inlinable         final var isRunning:         Bool          { (isGood && running)                                                   }
    @inlinable         final var waitForMore:       Bool          { (buffer.isEmpty && isRunning)                                         }
    @inlinable         final var fooChars:          Bool          { (running || !buffer.isEmpty)                                          }
    @inlinable         final var hasChars:          Bool          { (isGood && fooChars)                                                  }
    @inlinable         final var effectiveStatus:   Stream.Status { (isOpen ? (hasError ? .error : (fooChars ? .open : .atEnd)) : status) }
    //@f:1

    /*===========================================================================================================================================================================*/
    /// Create a new instance of this character input stream from an existing byte input stream.
    /// 
    /// - Parameters:
    ///   - inputStream: the underlying byte input stream.
    ///   - encodingName: the name of the incoming character encoding.
    ///   - autoClose: if `true` then the underlying input stream will be closed when this stream is closed or destroyed.
    ///
    public init(inputStream: InputStream, encodingName: String, autoClose: Bool = true) {
        self.inputStream = inputStream
        self.encodingName = encodingName
        self.autoClose = autoClose
    }

    /*===========================================================================================================================================================================*/
    /// Create a new instance of this character input stream to read bytes from a file.
    /// 
    /// - Parameters:
    ///   - filename: the filename to read.
    ///   - encodingName:
    /// - Throws: if the file is not found.
    ///
    public convenience init(filename: String, encodingName: String) throws {
        guard let inStrm = InputStream(fileAtPath: filename) else { throw StreamError.FileNotFound(description: "File not found: \"\(filename)\"") }
        self.init(inputStream: inStrm, encodingName: encodingName)
    }

    /*===========================================================================================================================================================================*/
    /// Create a new instance of this character input stream to read bytes from a URL.
    /// 
    /// - Parameters:
    ///   - url: the URL to read from.
    ///   - encodingName:
    /// - Throws: if the URL is malformed.
    ///
    public convenience init(url: URL, encodingName: String) throws {
        guard let inStrm = InputStream(url: url) else { throw StreamError.FileNotFound(description: "Unable to open URL for reading: \"\(url.absoluteString)") }
        self.init(inputStream: inStrm, encodingName: encodingName)
    }

    /*===========================================================================================================================================================================*/
    /// Create a new instance of this character input stream to read bytes from a data object.
    /// 
    /// - Parameters:
    ///   - data: the data to read.
    ///   - encodingName:
    ///
    public convenience init(data: Data, encodingName: String) {
        self.init(inputStream: InputStream(data: data), encodingName: encodingName)
    }

    /*===========================================================================================================================================================================*/
    /// Create a new instance of this character input stream to read characters from the given string.
    /// 
    /// - Parameter string: the string to read characters from.
    ///
    public convenience init(string: String) {
        var string: String = string
        let data = string.withUTF8 { (bp: UnsafeBufferPointer<UInt8>) -> Data in Data(buffer: bp) }
        self.init(inputStream: InputStream(data: data), encodingName: "UTF-8")
    }

    deinit { _close() }

    /*===========================================================================================================================================================================*/
    /// Check to see if the `streamStatus` is any of the given values.
    /// 
    /// - Parameter values: the values to check for.
    /// - Returns: `true` if the `streamStatus` is any of the given values.
    ///
    open func isStatus(oneOf values: Stream.Status...) -> Bool { isStatus(oneOf: values) }

    /*===========================================================================================================================================================================*/
    /// Check to see if the `streamStatus` is any of the given values.
    /// 
    /// - Parameter values: the values to check for.
    /// - Returns: `true` if the `streamStatus` is any of the given values.
    ///
    open func isStatus(oneOf values: [Stream.Status]) -> Bool { lock.withLock { values.isAny { ($0 == effectiveStatus) } } }

    /*===========================================================================================================================================================================*/
    /// Read one character from the input stream.
    /// 
    /// - Returns: the character read or `nil` if the stream is closed (or not opened in the first place) or the end of input has been reached.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    open func read() throws -> Character? { try lock.withLock { try _read() } }

    func _read() throws -> Character? {
        while waitForMore { lock.broadcastWait() }
        guard isOpen else { return nil }
        if let e = error { throw e }
        return buffer.popFirst()
    }

    /*===========================================================================================================================================================================*/
    /// Read characters from the stream. Any existing values in the array will be cleared first.
    /// 
    /// - Parameters:
    ///   - chars: the array to receive the characters.
    ///   - len: the maximum number of characters to receive. If -1 then all characters are read until the end of input.
    /// - Returns: the number of characters actually read. If the stream is closed (or not opened) or the end of input has been reached then
    ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> `0` is returned.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    open func read(chars: inout [Character], maxLength: Int) throws -> Int { try lock.withLock { try _read(chars: &chars, maxLength: maxLength) } }

    func _read(chars: inout [Character], maxLength: Int) throws -> Int {
        if !chars.isEmpty { chars.removeAll(keepingCapacity: true) }
        return try _append(to: &chars, maxLength: maxLength)
    }

    /*===========================================================================================================================================================================*/
    /// Read <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s from the stream and append them to the given character array. This method is
    /// identical to `read(chars:,maxLength:)` except that the receiving array is not cleared before the data is read.
    /// 
    /// - Parameters:
    ///   - chars: the <code>[Array](https://developer.apple.com/documentation/swift/Array)</code> to receive the
    ///            <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s.
    ///   - maxLength: the maximum number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s to receive. If -1 then all
    ///                <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s are read until the end-of-file.
    /// - Returns: the number of <code>[Character](https://developer.apple.com/documentation/swift/Character)</code>s read. Will return 0
    ///            (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) if the stream is at end-of-file.
    /// - Throws: if an I/O error occurs.
    ///
    open func append(to chars: inout [Character], maxLength: Int) throws -> Int { try lock.withLock { try _append(to: &chars, maxLength: maxLength) } }

    func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
        var cc: Int = 0
        let ln: Int = ((maxLength < 0) ? Int.max : maxLength)

        while (cc < ln) && hasChars {
            while waitForMore { lock.broadcastWait() }

            guard isOpen else { break }
            if let e = error { throw e }

            if buffer.isEmpty {
                guard isRunning else { break }
            }
            else {
                let l = min(buffer.count, (ln - cc))
                let r = (0 ..< l)

                chars.append(contentsOf: buffer[r])
                buffer.removeSubrange(r)
                cc += l
            }
        }

        return cc
    }

    /*===========================================================================================================================================================================*/
    /// Opens the character stream for reading.  If the stream has already been opened then calling this method does nothing.
    ///
    open func open() { lock.withLock { _open() } }

    func _open() {
        if status == .notOpen {
            error = nil
            running = true
            status = .open
            queue.async { [weak self] in self?.background() }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Closes the character stream after which no further characters can be read. If the stream had never been opened it will still go directly into a closed state. If the
    /// character stream has already been closed then calling this method does nothing. Once a character stream has been closed it can never be reopened.
    ///
    open func close() { lock.withLock { _close() } }

    func _close() {
        if isOpen {
            status = .closed
            while running { lock.broadcastWait() }
            buffer.removeAll(keepingCapacity: false)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Read bytes from the input stream and convert them to characters. The characters are then stored in the character buffer.
    ///
    private func background() {
        lock.withLock {
            do {
                if inputStream.streamStatus == .notOpen { inputStream.open() }
                defer { running = false; if autoClose { inputStream.close() } }
                try backgroundIconv(IConv(toEncoding: ENCODE_TO_NAME, fromEncoding: encodingName, ignoreErrors: true, enableTransliterate: true),
                                    input: EasyByteBuffer(length: INPUT_BUFFER_SIZE),
                                    output: EasyByteBuffer(length: OUTPUT_BUFFER_SIZE))
            }
            catch let e {
                error = e
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Do the character encoding conversion in the background.
    /// 
    /// - Parameters:
    ///   - iconv: the instance of `IConv`
    ///   - inputBuffer: the input buffer.
    ///   - outputBuffer: the output buffer.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    private func backgroundIconv(_ iconv: IConv, input inputBuffer: EasyByteBuffer, output outputBuffer: EasyByteBuffer) throws {
        convertFinal(iconv, inputBuffer: inputBuffer, outputBuffer: outputBuffer, hangingCR: try iconvLoop(iconv, inputBuffer: inputBuffer, outputBuffer: outputBuffer))
    }

    /*===========================================================================================================================================================================*/
    /// The main loop of the background reading/converting thread.
    /// 
    /// - Parameters:
    ///   - iconv: the handle to the IConv
    ///   - inputBuffer: The input buffer.
    ///   - outputBuffer: The output buffer.
    /// - Returns: `true` if there was a hanging carriage-return.
    /// - Throws: if there was an I/O or conversion error.
    ///
    private func iconvLoop(_ iconv: IConv, inputBuffer: EasyByteBuffer, outputBuffer: EasyByteBuffer) throws -> Bool {
        var cr: Bool = false

        while isRunning {
            while (buffer.count >= MAX_READ_AHEAD) && isRunning { lock.broadcastWait() }
            guard try read(inputBuffer) else { break }
            cr = try convert(iconv, inputBuffer: inputBuffer, outputBuffer: outputBuffer, hangingCR: cr)
        }

        return cr
    }

    /*===========================================================================================================================================================================*/
    /// Perform one last conversion on anything left in the input buffer.
    /// 
    /// - Parameters:
    ///   - iconv: the handle to the IConv
    ///   - inputBuffer: The input buffer.
    ///   - outputBuffer: The output buffer.
    ///   - cr: If there was a hanging carriage-return in the previous call to this method.
    ///
    private func convertFinal(_ iconv: IConv, inputBuffer: EasyByteBuffer, outputBuffer: EasyByteBuffer, hangingCR cr: Bool) {
        if inputBuffer.count > 0 {
            _ = iconv.convert(input: inputBuffer, output: outputBuffer)
            if storeConvertedChars(outputBuffer, hangingCR: cr) { buffer <+ "\r" }
        }
        if inputBuffer.count > 0 {
            buffer <+ UnicodeReplacementChar
            inputBuffer.count = 0
        }
    }

    /*===========================================================================================================================================================================*/
    /// Convert the bytes in the input buffer to UTF-32 code-points and store them in the output buffer.
    /// 
    /// - Parameters:
    ///   - iconv: the handle to the IConv
    ///   - inputBuffer: The input buffer.
    ///   - outputBuffer: The output buffer.
    ///   - hangingCR: If there was a hanging carriage-return in the previous call to this method.
    /// - Returns: `true` if there was a hanging carriage-return in this call.
    /// - Throws: if there was an I/O error or an error during conversion.
    ///
    private func convert(_ iconv: IConv, inputBuffer: EasyByteBuffer, outputBuffer: EasyByteBuffer, hangingCR: Bool) throws -> Bool {
        var resp: IConv.Results = .InputTooBig
        var cr:   Bool          = hangingCR

        while resp == .InputTooBig {
            resp = iconv.convert(input: inputBuffer, output: outputBuffer)
            cr = storeConvertedChars(outputBuffer, hangingCR: cr)
        }

        guard value(resp, isOneOf: .OK, .IncompleteSequence) else { throw StreamError.UnknownError(description: "IConv encoding error.") }
        return cr
    }

    /*===========================================================================================================================================================================*/
    /// Read a set of bytes from the underlying input stream so they can be converted to characters.
    /// 
    /// - Parameter ib: the input buffer.
    /// - Returns: `true` if at least one byte was read.
    /// - Throws: if an I/O error occurred.
    ///
    private func read(_ ib: EasyByteBuffer) throws -> Bool {
        guard isRunning else { return false }
        let rc = inputStream.read(buffer: ib)
        guard rc >= 0 else { throw inputStream.streamError ?? StreamError.UnknownError() }
        return (rc > 0)
    }

    /*===========================================================================================================================================================================*/
    /// Store the converted characters to the character buffer. CR/LF code-point pairs are automatically converted to single "\r\n" grapheme clusters. If the last code-point is a
    /// carriage-return ("\r") then this method returns `true` so that the next time it's called it can see if the first code-point in that set is a line-feed code-point ("\n") so
    /// that the two can be converted into a single grapheme cluster.
    /// 
    /// - Parameters:
    ///   - ob: the output buffer containing the UTF-32 code-points.
    ///   - cr: if there was a hanging carriage-return after the last time this method was called.
    /// - Returns: `true` if there was a hanging carriage-return this time.
    ///
    private func storeConvertedChars(_ ob: EasyByteBuffer, hangingCR cr: Bool) -> Bool {
        ob.withBufferAs(type: UInt32.self) { (b: UnsafeMutableBufferPointer<UInt32>, c: inout Int) in
            var i = b.startIndex
            let j = b.endIndex

            if i < j {
                defer { c = 0 }

                if cr && i < j {
                    if b[i] == LINE_FEED_CODEPOINT { buffer <+ LFCR_CHARACTER; i += 1 }
                    else { buffer <+ CR_CHARACTER }
                }

                while i < j {
                    var ch = toChar(codePoint: b[i++])

                    if ch == CR_CHARACTER {
                        if i < j { if b[i] == LINE_FEED_CODEPOINT { ch = LFCR_CHARACTER; i += 1 } }
                        else { return true }
                    }

                    buffer <+ ch
                }

                return false
            }

            return cr
        }
    }
}
