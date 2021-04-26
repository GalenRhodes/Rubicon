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

    private typealias MarkTuple = (char: Character, pos: TextPosition)

    //@f:0
    open         var tabWidth:          Int8          { get { lock.withLock { tab } } set { lock.withLock { tab = newValue }                                     } }
    open         var markCount:         Int           { lock.withLock { marks.count                                                                              } }
    open         var position:          TextPosition  { lock.withLock { pos                                                                                      } }
    open         var streamError:       Error?        { lock.withLock { (isOpen ? error : nil)                                                                   } }
    open         var streamStatus:      Stream.Status { lock.withLock { (isOpen ? (hasBChars ? .open : (nErr ? (isRunning ? .open : .atEnd) : .error)) : status) } }
    open         var isEOF:             Bool          { (streamStatus == .atEnd)                                                                                   }
    open         var hasCharsAvailable: Bool          { lock.withLock { (isOpen && (hasBChars || (nErr && isRunning)))                                           } }
    open         var encodingName:      String        { lock.withLock { inputStream.encodingName                                                                 } }

    private      let inputStream:       SimpleCharInputStream
    private      var isRunning:         Bool          = false
    private      let isReading:         AtomicValue   = AtomicValue(initialValue: false)
    private      var buffer:            [Character]   = []
    private      var marks:             [MarkItem]    = []
    private      var tab:               Int8          = 4
    private      let lock:              Conditional   = Conditional()
    private      let rdLock:            Conditional   = Conditional()
    private      var pos:               TextPosition  = (0, 0)
    private      var error:             Error?        = nil
    private      var status:            Stream.Status = .notOpen
    private lazy var queue:             DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, autoreleaseFrequency: .workItem)

    private      var nErr:              Bool          { (error == nil)                }
    private      var isOpen:            Bool          { (status == .open)             }
    private      var noError:           Bool          { (nErr || hasBChars)           }
    private      var isGood:            Bool          { (isOpen && noError)           }
    private      var canWait:           Bool          { (isOpen && nErr && isRunning) }
    private      var hasBChars:         Bool          { !buffer.isEmpty               }
    //@f:1

    public init(inputStream: InputStream, encodingName: String, autoClose: Bool = true) {
        self.inputStream = SimpleIConvCharInputStream(inputStream: inputStream, encodingName: encodingName, autoClose: autoClose)
    }

    open func open() {
        lock.withLock {
            guard status == .notOpen else { return }
            error = nil
            pos = (1, 1)
            status = .open
            isRunning = true
            isReading.value = false
            queue.async { [weak self] in if let s = self { s.readerThread() } }
        }
    }

    open func close() {
        isReading.waitUntil(valueIs: { $0 == false }, thenWithValueSetTo: true) {
            lock.withLock {
                guard isOpen else { return }
                status = .closed
                while isRunning { lock.broadcastWait() }
                error = nil
                pos = (0, 0)
            }
        }
    }

    open func read() throws -> Character? {
        try isReading.waitUntil(valueIs: { !$0 }, thenWithValueSetTo: true) {
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

    open func append(to chars: inout [Character], maxLength: Int) throws -> Int {
        try isReading.waitUntil(valueIs: { !$0 }, thenWithValueSetTo: true) {
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
                    cc += try readBufferedChars(to: &chars, maxLength: (ln - cc))
                }

                return cc
            }
        }
    }

    private func readBufferedChars(to chars: inout [Character], maxLength ln: Int) throws -> Int {
        let x = min(ln, buffer.count)
        let r = (0 ..< x)
        let m = marks.last

        buffer[r].forEach { ch in
            if let mi = m { mi.chars <+ (ch, pos) }
            textPositionUpdate(ch, pos: &pos, tabWidth: tab)
            chars <+ ch
        }

        buffer.removeSubrange(r)
        return ln
    }

    open func markSet() {
        lock.withLock {
            marks <+ MarkItem(pos: pos)
        }
    }

    open func markDelete() {
        lock.withLock {
            marks.popLast()
        }
    }

    open func markReturn() {
        lock.withLock {
            guard let mi = marks.popLast() else { return }
            pos = mi.pos
            buffer.insert(contentsOf: mi.chars.map { $0.char }, at: 0)
        }
    }

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

    open func markBackup(count: Int) -> Int {
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

    private func readerThread() {
        lock.withLock {
            do {
                defer {
                    isRunning = false
                    inputStream.close()
                }

                if inputStream.streamStatus == .notOpen { inputStream.open() }

                guard inputStream.streamError == nil else { throw inputStream.streamError! }
                guard inputStream.streamStatus != .closed else { return }

                while isOpen {
                    while isOpen && buffer.count >= MAX_READ_AHEAD { lock.broadcastWait() }
                    guard try isOpen && inputStream.append(to: &buffer, maxLength: INPUT_BUFFER_SIZE) > 0 else { break }
                    if isReading.value { lock.broadcastWait() }
                }
            }
            catch let e {
                error = e
                #if DEBUG
                    print("ERROR> \(e)")
                #endif
            }
        }
    }

    private class MarkItem {
        var pos:   TextPosition
        var chars: [MarkTuple] = []

        init(pos: TextPosition) { self.pos = pos }
    }
}
