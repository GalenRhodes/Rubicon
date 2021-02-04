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
    public typealias Status = Stream.Status

    //@f:0
    public let            encodingName:      String

    @inlinable public var streamError:       Error? { ((streamStatus == .error) ? _err : nil)                                                                                               }
    @inlinable public var hasCharsAvailable: Bool   { status(in: .open, .reading, .writing)                                                                                                 }
    @inlinable public var isEOF:             Bool   { !((streamStatus == .notOpen) || hasCharsAvailable)                                                                                    }
    @inlinable public var streamStatus:      Status { _lock.withLock { ((_st == .notOpen) ? _st : ((_st == .open) ? ((_charBuffer.isEmpty && !_run) ? stE(.atEnd) : .open) : stE(.closed))) }                                                  }
    @inlinable public var lineNumber:        Int    { _lock.withLock { _position.line   }                                                                                                   }
    @inlinable public var columnNumber:      Int    { _lock.withLock { _position.column }                                                                                                   }
    @inlinable public var tabWidth:          Int    { get { _lock.withLock { _tabWidth } } set { _lock.withLock { _tabWidth = newValue } }                                                  }

    @usableFromInline lazy var _queue:       DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .background, autoreleaseFrequency: .workItem)
    @usableFromInline      var _position:    Position      = Position(line: 1, column: 1, prevChar: nil)
    @usableFromInline      var _tabWidth:    Int           = 8
    @usableFromInline      var _charBuffer:  [Character]   = []
    @usableFromInline      var _markStack:   [MarkItem]    = []
    @usableFromInline      var _run:         Bool          = false
    @usableFromInline      var _err:         Error?        = nil
    @usableFromInline      var _st:          Status        = .notOpen // We're only going to use three (3) status here: .notOpen, .open, .closed
    @usableFromInline      let _lock:        Conditional   = Conditional()
    @usableFromInline      let _inputStream: InputStream
    @usableFromInline      let _autoClose:   Bool
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

    open func status(in statuses: Status...) -> Bool { statuses.isAny { $0 == streamStatus } }

    /*===========================================================================================================================================================================*/
    /// Opens the character stream for reading.  If the stream has already been opened then calling this method does nothing.
    ///
    open func open() {
        _lock.withLock {
            if _st == .notOpen {
                _st = .open
                _run = true
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
            if _st != .closed {
                _st = .closed
                while _run { _lock.broadcastWait() }
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
        try _lock.withLockBroadcastWait { !(_charBuffer.isEmpty && _run) } do: { (_charBuffer.isEmpty ? try handleError(nil) : stash(char: _charBuffer.popFirst())) }
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
    open func read(chars: inout [Character], maxLength len: Int) throws -> Int {
        chars.removeAll(keepingCapacity: true)
        let maxLength: Int = fixLength(len)
        guard maxLength > 0 else { return 0 }

        return try _lock.withLock {
            var cc: Int = 0
            while cc < maxLength {
                while _charBuffer.isEmpty && _run { _lock.broadcastWait() }
                if _charBuffer.isEmpty { return try handleError(cc) }
                cc += _copy(&chars, count: (maxLength - cc))
            }
            return cc
        }
    }

    @inlinable final func handleError<T>(_ v: T) throws -> T {
        if let e = _err { throw e }
        return v
    }

    /*===========================================================================================================================================================================*/
    /// Copy characters from the buffer into the given character array.
    /// 
    /// - Parameters:
    ///   - chars: the receiving array.
    ///   - count: the number of characters to copy.
    /// - Returns: the number of characters actually copied.
    ///
    @inlinable final func _copy(_ chars: inout [Character], count: Int) -> Int {
        let cc   = min(_charBuffer.count, count)
        let sIdx = _charBuffer.startIndex
        let eIdx = _charBuffer.index(sIdx, offsetBy: cc)
        chars.append(contentsOf: stash(chars: _charBuffer[sIdx ..< eIdx]))
        _charBuffer.removeFirst(cc)
        return cc
    }

    /*===========================================================================================================================================================================*/
    /// Marks the current point in the stream so that it can be returned to later. You can set more than one mark but all operations happen on the most recently set mark.
    ///
    open func markSet() { _lock.withLock { if _st == .open { _markStack.append(MarkItem()) } } }

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

    open func markBackup(count cc: Int) -> Int {
        _lock.withLock {
            if let m = _markStack.last {
                let eIdx = m.count
                let sIdx = (eIdx - min(cc, eIdx))
                return restoreMarkChars(markChars: m.chars[sIdx ..< eIdx])
            }
            return 0
        }
    }

    /*===========================================================================================================================================================================*/
    /// The background thread function that reads from the backing byte input stream.
    ///
    final func iConvRunner() {
        _lock.withLock {
            do {
                defer { _run = false }
                guard let iconv = IConv(toEncoding: EncodeToName, fromEncoding: encodingName, ignoreErrors: true, enableTransliterate: true) else { throw getEncodingError(encodingName: encodingName) }
                if _inputStream.streamStatus == .notOpen { _inputStream.open() }
                defer { if _autoClose { _inputStream.close() } }
                try iConvLoop(iconv, inBuff: EasyByteBuffer(length: InputBufferSize), outBuff: EasyByteBuffer(length: OutputBufferSize))
            }
            catch let e {
                _err = e
            }
        }
    }

    /*===========================================================================================================================================================================*/
    /// Returns `true` if the background thread is still good to keep running.
    ///
    @inlinable final var _running: Bool { ((_st == .open) && (_inputStream.streamStatus == .open)) }

    /*===========================================================================================================================================================================*/
    /// The loop that reads bytes from the underlying input stream and converts them using IConv into characters.
    /// 
    /// - Parameters:
    ///   - iconv: the instance of IConv
    ///   - i: the input buffer.
    ///   - o: the output buffer.
    /// - Returns: `true` if the loop should continue and `false` if it should stop.
    ///
    final func iConvLoop(_ iconv: IConv, inBuff i: EasyByteBuffer, outBuff o: EasyByteBuffer) throws {
        while _running {
            //-------------------------------------------------------------------------------------
            // Wait until there is room in the input buffer, the character stream has been closed,
            // or the underlying byte input stream is at EOF or encountered and error.
            //-------------------------------------------------------------------------------------
            while (_charBuffer.count >= MaxReadAhead) && _running { _lock.broadcastWait() }
            //----------------------------------------------------------
            // If we've been closed or the underlying byte input stream
            // is at EOF or encountered an error, exit.
            //----------------------------------------------------------
            guard _running else { break }
            //--------------------------------------------------------
            // Read bytes from the input stream. If the EOF was found
            // or there was a problem, exit.
            //--------------------------------------------------------
            guard try inputStreamRead(buffer: i) else { break }
            //-------------------------------------------------
            // Decode them and store them in the `charBuffer`.
            //-------------------------------------------------
            try iConv(iconv, input: i, output: o)
            //-------------------------------------------------
            // Give the readers a chance to read.
            //-------------------------------------------------
            _lock.broadcastWait()
        }
        try finalIConv(iconv: iconv, inBuff: i, outBuff: o)
    }

    /*===========================================================================================================================================================================*/
    /// Read the next set of bytes from the byte input stream.
    /// 
    /// - Parameter inBuff: the input buffer to receive the bytes.
    /// - Returns: `true` if any bytes were read or `false` if the EOF was found.
    /// - Throws: if an I/O error was encountered.
    ///
    @inlinable final func inputStreamRead(buffer inBuff: EasyByteBuffer) throws -> Bool {
        let rc = _inputStream.read(buffer: inBuff)
        guard rc >= 0 else { throw (_inputStream.streamError ?? StreamError.UnknownError()) }
        return (rc > 0)
    }

    /*===========================================================================================================================================================================*/
    /// Converts the data from the input stream to UTF-32 characters and stores them in the `charBuffer` for a final time.
    /// 
    /// - Parameters
    ///   - input: the input buffer.
    ///   - output: the output buffer.
    ///
    @inlinable final func finalIConv(iconv: IConv, inBuff i: EasyByteBuffer, outBuff o: EasyByteBuffer) throws {
        if (i.count > 0) {
            try iConv(iconv, input: i, output: o)
            _charBuffer.append(UnicodeReplacementChar)
            i.count = 0
        }
        storeCharacters(buffer: o)
    }

    /*===========================================================================================================================================================================*/
    /// Converts the data from the input stream to UTF-32 characters and stores them in the `charBuffer`.
    /// 
    /// - Parameters
    ///   - iconv: the instance of `IConv`.
    ///   - input: the input buffer.
    ///   - output: the output buffer.
    ///
    @inlinable final func iConv(_ iconv: IConv, input inBuff: EasyByteBuffer, output outBuff: EasyByteBuffer) throws {
        var resp: IConv.Results = .OK
        //--------------------------------------------------------------------------
        // We've sized everything so that the input being too big shouldn't happen,
        // but just in case we'll take it into account.
        //--------------------------------------------------------------------------
        repeat {
            resp = iconv.convert(input: inBuff, output: outBuff)
            storeCharacters(buffer: outBuff)
        }
        while resp == .InputTooBig
        guard value(resp, isOneOf: .OK, .IncompleteSequence) else { throw StreamError.UnknownError(description: "IConv encoding error.") }
    }

    /*===========================================================================================================================================================================*/
    /// Take `count` UTF-32 characters from the buffer and store them in the `charBuffer`.
    /// 
    /// - Parameters:
    ///   - buffer: the buffer.
    ///   - count: the number of UTF-32 characters.
    ///
    @inlinable final func storeCharacters(buffer o: EasyByteBuffer) {
        o.withBufferAs(type: UInt32.self) { (b: UnsafeMutableBufferPointer<UInt32>, c: inout Int) in
            _charBuffer.append(contentsOf: b.map { Character(scalar: UnicodeScalar($0)) })
            c = 0
        }
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
        return char
    }

    /*===========================================================================================================================================================================*/
    /// Stash the sequence of characters onto the most recently set `MarkItem`. If there is no set `MarkItem` then nothing happens.
    /// 
    /// - Parameter chars: the sequence of characters.
    /// - Returns: the same sequence of characters.
    ///
    @inlinable final func stash<C>(chars: C) -> C where C: Collection, C.Element == Character {
        if !chars.isEmpty {
            if let ms = _markStack.last { chars.forEach { ms.append($0, _position); _position.update(character: $0, tabWidth: _tabWidth) } }
            else { chars.forEach { _position.update(character: $0, tabWidth: _tabWidth) } }
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
            if _st == .open {
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
        _charBuffer.insert(contentsOf: markChars.map({ $0.char }), at: _charBuffer.startIndex)
        _position = first.position
        return markChars.count
    }

    /*===========================================================================================================================================================================*/
    /// Perform either a `markDelete()` or a `markUpdate()` (which is just a `markDelete()` followed by a `markSet()`).
    /// 
    /// - Parameter delete: `true` if we're performing a `markDelete()`, otherwise we're performing a `markUpdate()`.
    ///
    @inlinable final func markDeleteOrUpdate(delete: Bool) { withTopMarkDo { _ in delete } }

    @inlinable final func stE(_ s: Status) -> Status { ((_err == nil) ? s : .error) }

    deinit { close() }

    /*===========================================================================================================================================================================*/
    /// Holds a saved character's position.
    ///
    @usableFromInline final class Position {
        public var line:     Int
        public var column:   Int
        public var prevChar: Character?

        public init(line l: Int, column c: Int, prevChar p: Character?) { line = l; column = c; prevChar = p }

        @discardableResult @inlinable public final func update(character ch: Character, tabWidth tab: Int) -> Character {
            switch ch {
                case "\t":         column = (((column + tab) / tab) * tab)
                case "\n":         if prevChar != "\r" { newLine() }
                case "\r", "\r\n": newLine()
                case "\u{0b}":     newLine(count: ((((line + tab) / tab) * tab) - line))
                case "\u{0c}":     newLine(count: 24)
                default:           column++
            }
            prevChar = ch
            return ch
        }

        @inlinable public final func copy() -> Position { Position(line: line, column: column, prevChar: prevChar) }

        @inlinable final func newLine(count: Int = 1) {
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
        @inlinable final var count: Int { chars.count }
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
