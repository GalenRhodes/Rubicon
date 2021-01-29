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

/*===============================================================================================================================================================================*/
/// There is a possibility that the endian of the system is not known. In that case we default to `little` endian because that's the most common these days.
///
@usableFromInline let EncodeToName:     String = "UTF-32\((CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue) ? "BE" : "LE")"
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
@usableFromInline let MaxReadAhead:     Int    = 1_048_576
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
@usableFromInline let InputBufferSize:  Int    = 131_072
/*===============================================================================================================================================================================*/
/// The size of this buffer might seem excessive at first but even small SBCs are now coming with Gigabit ethernet and 4GB of RAM. Even an entry level MacMini comes with 8GB of
/// RAM. So this buffer size is probably a bit on the small side.
///
@usableFromInline let OutputBufferSize: Int    = ((InputBufferSize * MemoryLayout<UInt32>.stride) + MemoryLayout<UInt32>.stride)

open class IConvCharInputStream: CharInputStream {
    //@f:0
    public let            encodingName:      String

    @inlinable public var streamError:       Error?        { ((streamStatus == .error) ? _error : nil)                                            }
    @inlinable public var hasCharsAvailable: Bool          { status(in: .open, .reading, .writing)                                                }
    @inlinable public var isEOF:             Bool          { !((streamStatus == .notOpen) || hasCharsAvailable)                                   }
    @inlinable public var streamStatus:      Stream.Status { _lock.withLock { testSts(_status) }                                                  }
    @inlinable public var lineNumber:        Int           { _lock.withLock { _position.line   }                                                  }
    @inlinable public var columnNumber:      Int           { _lock.withLock { _position.column }                                                  }
    @inlinable public var tabWidth:          Int           { get { _lock.withLock { _tabWidth } } set { _lock.withLock { _tabWidth = newValue } } }

    @inlinable final  var _atEnd:            Bool          { (_charBuffer.isEmpty && !_running)                                                   }
    @inlinable final  var _runnerGood:       Bool          { ((_status == .open) && _inputStream.status(in: .open, .reading, .writing))           }

    @usableFromInline var _position:         Position      = Position(line: 1, column: 1, prevChar: nil)
    @usableFromInline var _tabWidth:         Int           = 8
    @usableFromInline var _charBuffer:       [Character]   = []
    @usableFromInline var _markStack:        [MarkItem]    = []
    @usableFromInline var _error:            Error?        = nil
    @usableFromInline var _status:           Stream.Status = .notOpen // We're only going to use three (3) status here: .notOpen, .open, .closed
    @usableFromInline var _running:          Bool          = false
    @usableFromInline let _lock:             Conditional   = Conditional()
    @usableFromInline let _queue:            DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .background, autoreleaseFrequency: .workItem)
    @usableFromInline let _inputStream:      InputStream
    @usableFromInline let _autoClose:        Bool
    //@f:1

    public init(inputStream: InputStream, autoClose: Bool = true, encodingName: String) {
        self._inputStream = inputStream
        self.encodingName = encodingName.trimmed.uppercased()
        self._autoClose = autoClose
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

    open func status(in statuses: Stream.Status...) -> Bool {
        for st in statuses { if streamStatus == st { return true } }
        return false
    }

    /*===========================================================================================================================================================================*/
    /// Opens the character stream for reading.  If the stream has already been opened then calling this method does nothing.
    ///
    open func open() {
        _lock.withLock {
            if _status == .notOpen {
                _status = .open
                _running = true
                _queue.async { self.iConvRunner() }
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Closes the character stream after which no further characters can be read. If the stream had never been opened it will still go directly into a closed state. If the
    /// character stream has already been closed then calling this method does nothing. Once a character stream has been closed it can never be reopened.
    ///
    open func close() {
        _lock.withLock {
            if _status != .closed {
                _status = .closed
                while _running { _lock.broadcastWait() }
                _charBuffer.removeAll()
                _markStack.removeAll()
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Read one character from the input stream.
    ///
    /// - Returns: the character read or `nil` if the stream is closed (or not opened in the first place) or the end of input has been reached.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    open func read() throws -> Character? {
        try _lock.withLockBroadcastWait {
            !(_charBuffer.isEmpty && _running)
        } do: {
            guard _charBuffer.isEmpty else { return stash(char: _charBuffer.popFirst()) }
            guard let e = _error else { return nil }
            throw e
        }
    }

    /*===========================================================================================================================================================================*/
    /// Read characters from the stream. Any existing values in the array will be cleared first.
    ///
    /// - Parameters:
    ///   - chars: the array to receive the characters.
    ///   - maxLength: the maximum number of characters to receive. If -1 then all characters are read until the end of input.
    /// - Returns: the number of characters actually read. If the stream is closed (or not opened) or the end of input has been reached then
    ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> `0` is returned.
    /// - Throws: if an I/O or conversion error occurs.
    ///
    open func read(chars: inout [Character], maxLength: Int) throws -> Int {
        chars.removeAll(keepingCapacity: true)

        let maxLength = ((maxLength < 0) ? Int.max : maxLength)

        guard maxLength > 0 else { return 0 }

        return try _lock.withLock {
            var cc = 0

            while cc < maxLength {
                let rc = try _read(chars: &chars, maxLength: (maxLength - cc))
                if rc == 0 { break }
                cc += rc
            }

            return cc
        }
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark but all operations happen on the most recently set mark.
    ///
    open func markSet() { _lock.withLock { if _status == .open { _markStack.append(MarkItem()) } } }

    /*===========================================================================================================================================================================*/
    /// Removes the most recently set mark WITHOUT returning to it.
    ///
    open func markDelete() { markDeleteOrUpdate(delete: true) }

    /*===========================================================================================================================================================================*/
    /// Updates the most recently set mark to the current position. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markDelete()` followed immediately by a `markSet()`.
    ///
    open func markUpdate() { markDeleteOrUpdate(delete: false) }

    /*===========================================================================================================================================================================*/
    /// Returns to the most recently set mark WITHOUT removing it. If there was no previously set mark then a new one is created. This is functionally equivalent to performing a
    /// `markReturn()` followed immediately by a `markSet()`.
    ///
    open func markReset() { markReturnOrReset(reset: true) }

    /*===========================================================================================================================================================================*/
    /// Removes and returns to the most recently set mark.
    ///
    open func markReturn() { markReturnOrReset(reset: false) }

    open func markBackup(count: Int) -> Int {
        _lock.withLock {
            if let m = _markStack.last {
                let mcount = m.chars.count
                let cc     = min(count, mcount)
                if cc > 0 {
                    let rng = ((mcount - cc) ..< mcount)
                    let seq = m.chars[rng]
                    #if DEBUG
                        print("   Range: [\(rng.lowerBound) ..< \(rng.upperBound)]")
                        print("Sequence: startIndex = \(seq.startIndex); endIndex = \(seq.endIndex);")
                    #endif
                    return restoreMarkChars(markChars: seq)
                }
            }

            return 0
        }
    }

    /*===========================================================================================================================================================================*/
    /// The background thread function that reads from the backing byte input stream.
    ///
    final func iConvRunner() {
        _lock.withLock {
            if let iconv = IConv(toEncoding: EncodeToName, fromEncoding: encodingName, ignoreErrors: true, enableTransliterate: true) {
                let inBuff:  EasyByteBuffer = EasyByteBuffer(length: InputBufferSize)
                let outBuff: EasyByteBuffer = EasyByteBuffer(length: OutputBufferSize)

                if _inputStream.streamStatus == .notOpen { _inputStream.open() }

                while _runnerGood { guard iConvLoop(iconv, inBuff: inBuff, outBuff: outBuff) else { break } }
                //-------------------------------------------------
                // One final time just in case there's a few bytes
                // left over.
                //-------------------------------------------------
                finalIConv(iconv: iconv, inBuff: inBuff, outBuff: outBuff)
                if _autoClose { _inputStream.close() }
            }
            else {
                _error = getEncodingError(encodingName: encodingName)
            }
            _running = false
        }
    }

    /*===========================================================================================================================================================================*/
    /// The loop that reads bytes from the underlying input stream and converts them using IConv into characters.
    ///
    /// - Parameters:
    ///   - iconv: the instance of IConv
    ///   - i: the input buffer.
    ///   - o: the output buffer.
    /// - Returns: `true` if the loop should continue and `false` if it should stop.
    ///
    final func iConvLoop(_ iconv: IConv, inBuff i: EasyByteBuffer, outBuff o: EasyByteBuffer) -> Bool {
        while (_charBuffer.count >= MaxReadAhead) && _runnerGood { _lock.broadcastWait() }
        guard _runnerGood else { return false }
        //-------------------------------------------------
        // Read bytes from the input stream.
        //-------------------------------------------------
        guard _inputStream.read(buffer: i) > 0 else {
            if _inputStream.streamStatus == .error { _error = (_inputStream.streamError ?? StreamError.UnknownError()) }
            return false
        }
        //-------------------------------------------------
        // Decode them and store them in the `charBuffer`.
        //-------------------------------------------------
        guard value(iConv(iconv, input: i, output: o), isOneOf: .OK, .IncompleteSequence) else {
            _error = StreamError.UnknownError(description: "IConv encoding error.")
            return false
        }
        //-------------------------------------------------
        // Give the readers a chance to read.
        //-------------------------------------------------
        _lock.broadcastWait()
        return true
    }

    /*===========================================================================================================================================================================*/
    /// Converts the data from the input stream to UTF-32 characters and stores them in the `charBuffer` for a final time.
    ///
    /// - Parameters
    ///   - input: the input buffer.
    ///   - output: the output buffer.
    ///
    @inlinable final func finalIConv(iconv: IConv, inBuff i: EasyByteBuffer, outBuff o: EasyByteBuffer) {
        if (i.count > 0) && (iConv(iconv, input: i, output: o) == .IncompleteSequence) {
            //----------------------------------------------------------------------------
            // This would indicate that a final multi-byte character got cut-off so we'll
            // just stick a Unicode `bad character` marker in there to indicate so.
            //----------------------------------------------------------------------------
            _charBuffer.append(UnicodeReplacementChar)
            i.count = 0
        }
        storeCharacters(o)
    }

    /*===========================================================================================================================================================================*/
    /// Converts the data from the input stream to UTF-32 characters and stores them in the `charBuffer`.
    ///
    /// - Parameters
    ///   - iconv: the instance of `IConv`.
    ///   - input: the input buffer.
    ///   - output: the output buffer.
    ///
    @inlinable final func iConv(_ iconv: IConv, input inBuff: EasyByteBuffer, output outBuff: EasyByteBuffer) -> IConv.Results {
        var resp: IConv.Results = .OK
        //--------------------------------------------------------------------------
        // We've sized everything so that the input being too big shouldn't happen,
        // but just in case we'll take it into account.
        //--------------------------------------------------------------------------
        repeat {
            resp = iconv.convert(input: inBuff, output: outBuff)
            storeCharacters(outBuff)
        }
        while resp == .InputTooBig
        return resp
    }

    /*===========================================================================================================================================================================*/
    /// Take `count` UTF-32 characters from the buffer and store them in the `charBuffer`.
    ///
    /// - Parameters:
    ///   - buffer: the buffer.
    ///   - count: the number of UTF-32 characters.
    ///
    @inlinable final func storeCharacters(_ outBuff: EasyByteBuffer) {
        outBuff.withBufferAs(type: UInt32.self) { (p: UnsafeMutablePointer<UInt32>, length: Int, count: inout Int) in
            for x in (0 ..< count) {
                _charBuffer <+ Character(scalar: UnicodeScalar(p[x]))
            }
            count = 0
        }
    }

    /*===========================================================================================================================================================================*/
    /// Read multiple characters from the `charBuffer`.
    ///
    /// - Parameters:
    ///   - chars: the receiving array of <code>[Character](https://developer.apple.com/documentation/swift/character/)</code>`s
    ///   - maxLength: the maximum number of characters to read.
    /// - Returns: the number of characters actually read.
    /// - Throws: in the event of an I/O error or an IConv encoding error.
    ///
    @inlinable final func _read(chars: inout [Character], maxLength: Int) throws -> Int {
        while _charBuffer.isEmpty && _running { _lock.broadcastWait() }

        let cbcc = _charBuffer.count

        if cbcc == 0 {
            guard let e = _error else { return 0 }
            throw e
        }

        if cbcc <= maxLength {
            chars.append(contentsOf: stash(chars: _charBuffer))
            _charBuffer.removeAll()
            return cbcc
        }

        chars.append(contentsOf: stash(chars: _charBuffer[0 ..< maxLength]))
        _charBuffer.removeFirst(maxLength)
        return maxLength
    }

    /*===========================================================================================================================================================================*/
    /// Get a `CErrors.INVAL(description:)` error with an unsupported character encoding message.
    ///
    /// - Parameter encodingName: the name of the character encoding.
    /// - Returns: the error.
    ///
    @inlinable final func getEncodingError(encodingName: String) -> CErrors { CErrors.INVAL(description: "Unsupported character encoding: \"\(encodingName)\"") }

    /*===========================================================================================================================================================================*/
    /// Stash the character onto the most recently set `MarkItem`. If there is no set `MarkItem` then nothing happens.
    ///
    /// - Parameter char: the character.
    /// - Returns: the same character.
    ///
    @inlinable final func stash(char: Character?) -> Character? {
        if let ch = char {
            if let ms = _markStack.last { ms.append(ch, _position) }
            return _position.update(character: ch, tabWidth: _tabWidth)
        }
        return nil
    }

    /*===========================================================================================================================================================================*/
    /// Stash the sequence of characters onto the most recently set `MarkItem`. If there is no set `MarkItem` then nothing happens.
    ///
    /// - Parameter chars: the sequence of characters.
    /// - Returns: the same sequence of characters.
    ///
    @inlinable final func stash<C>(chars: C) -> C where C: Collection, C.Element == Character {
        if chars.isEmpty {
            if let ms = _markStack.last {
                for ch in chars {
                    ms.append(ch, _position)
                    _ = _position.update(character: ch, tabWidth: _tabWidth)
                }
            }
            else {
                for ch in chars { _ = _position.update(character: ch, tabWidth: _tabWidth) }
            }
        }
        return chars
    }

    /*===========================================================================================================================================================================*/
    /// Take the most recently set `MarkItem` and execute the closure with the array of characters contained in it. If the return value of the closure is `true` then that
    /// `MarkItem` is also removed from the stack, otherwise it is kept. If there is no previous set `MarkItem` then the body of the closure is executed with an empty array and if
    /// the closure returns `false` then a new `MarkItem` is placed on the stack, otherwise nothing else happens.
    ///
    /// - Parameter body: the closure.
    ///
    @inlinable func withTopMarkDo(_ body: ([MarkChar]) -> Bool) {
        _lock.withLock {
            if _status == .open {
                if let ms = _markStack.last {
                    if body(ms.chars) { _markStack.removeLast() }
                    else { ms.removeAll() }
                }
                else if !body([]) {
                    _markStack.append(MarkItem())
                }
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Perform either a `markReturn()` or a `markReset()` (which is just a `markReturn()` followed by a `markSet()`).
    ///
    /// - Parameter reset: if `true` then we're performing a `markReset()`, otherwise we're performing a `markRestore()`.
    ///
    @inlinable final func markReturnOrReset(reset: Bool) {
        withTopMarkDo { (chs: [MarkChar]) -> Bool in
            restoreMarkChars(markChars: chs)
            return !reset
        }
    }

    @discardableResult @inlinable final func restoreMarkChars<C>(markChars: C) -> Int where C: RandomAccessCollection, C.Element == MarkChar, C.Index == Int {
        guard !markChars.isEmpty else { return 0 }
        let first = markChars[markChars.startIndex]
        _charBuffer.insert(contentsOf: getChars(markChars: markChars), at: _charBuffer.startIndex)
        _position = first.position
        return markChars.count
    }

    @inlinable final func getChars<C>(markChars: C) -> [Character] where C: Collection, C.Element == MarkChar {
        var c: [Character] = []
        if !markChars.isEmpty {
            c.reserveCapacity(markChars.count)
            for mc in markChars { c <+ mc.char }
        }
        return c
    }

    /*===========================================================================================================================================================================*/
    /// Perform either a `markDelete()` or a `markUpdate()` (which is just a `markDelete()` followed by a `markSet()`).
    ///
    /// - Parameter delete: `true` if we're performing a `markDelete()`, otherwise we're performing a `markUpdate()`.
    ///
    @inlinable final func markDeleteOrUpdate(delete: Bool) { withTopMarkDo { _ in delete } }

    @inlinable final func stsOrErr(_ s: Stream.Status) -> Stream.Status { ((_error == nil) ? s : .error) }

    @inlinable final func testSts(_ s: Stream.Status) -> Stream.Status { ((s == .notOpen) ? s : ((s == .open) ? (_atEnd ? stsOrErr(.atEnd) : .open) : stsOrErr(.closed))) }

    deinit { close() }

    /*===========================================================================================================================================================================*/
    /// Holds a saved character's position.
    ///
    @usableFromInline final class Position { //@f:0
        public var line: Int
        public var column: Int
        public var prevChar: Character?
        public init(line l: Int, column c: Int, prevChar p: Character?) { line = l; column = c; prevChar = p }
        @inlinable public final func copy() -> Position { Position(line: line, column: column, prevChar: prevChar) }
        //@f:1
        @inlinable public final func update(character ch: Character, tabWidth tab: Int) -> Character {
            switch ch {
                case "\t":     column = (((column + tab) / tab) * tab)
                case "\n":     if prevChar != "\r" { newLine(count: 1) }
                case "\r":     newLine(count: 1)
                case "\u{0b}": newLine(count: ((((line + tab) / tab) * tab) - line))
                case "\u{0c}": newLine(count: 24)
                default:       column++
            }
            prevChar = ch
            return ch
        }

        @inlinable final func newLine(count: Int) {
            line += count
            column = 1
        }
    }

    /*===========================================================================================================================================================================*/
    /// Holds a saved character and it's position.
    ///
    @usableFromInline @frozen struct MarkChar { //@f:0
        @usableFromInline let char:     Character
        @usableFromInline let position: Position
        @usableFromInline init(char ch: Character, position pos: Position) { char = ch; position = pos.copy() }
    } //@f:1

    /*===========================================================================================================================================================================*/
    /// Holds the characters saved during a mark.
    ///
    @usableFromInline class MarkItem { //@f:0
        @usableFromInline var chars: [MarkChar] = []
        @usableFromInline init() {}
        @inlinable final func append(_ char: Character, _ pos: Position) { chars.append(MarkChar(char: char, position: pos)) }
        @inlinable final func removeAll() { chars.removeAll(keepingCapacity: true) }
    } //@f:1
}

open class UTF8CharInputStream: IConvCharInputStream {
    static let InputEnc = "UTF-8"

    public init(inputStream: InputStream) { super.init(inputStream: inputStream, encodingName: UTF8CharInputStream.InputEnc) }

    public init(data: Data) { super.init(inputStream: InputStream(data: data), encodingName: UTF8CharInputStream.InputEnc) }

    public init?(fileAtPath: String) {
        guard let inputStream = InputStream(fileAtPath: fileAtPath) else { return nil }
        super.init(inputStream: inputStream, encodingName: UTF8CharInputStream.InputEnc)
    }

    public init?(url: URL) {
        guard let inputStream = InputStream(url: url) else { return nil }
        super.init(inputStream: inputStream, encodingName: UTF8CharInputStream.InputEnc)
    }
}
