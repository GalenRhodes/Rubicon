/*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleStringCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/1/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*============================================================================================================================================================================*/

import Foundation
import CoreFoundation

open class SimpleStringCharInputStream: SimpleCharInputStream {
    //@f:0
    /*===========================================================================================================================================================================*/
    /// Just for looks.  Encoding is always UTF-32.
    ///
    public let encodingName: String = "UTF-32"
    /*===========================================================================================================================================================================*/
    /// Just for looks.  Errors will never happen.
    ///
    public let streamError:  Error? = nil

    open var streamStatus:      Stream.Status { lock.withLock { ((status == .open) ? ((index < eIdx) ? .open : .atEnd) : status) } }
    open var hasCharsAvailable: Bool          { lock.withLock { ((status == .open) && (index < eIdx))                            } }
    open var isEOF:             Bool          { lock.withLock { ((status != .open) || (index == eIdx))                           } }

    @usableFromInline let string: String
    @usableFromInline let eIdx:   String.Index
    @usableFromInline var index:  String.Index
    @usableFromInline var status: Stream.Status = .notOpen
    @usableFromInline let lock:   RecursiveLock = RecursiveLock()
    //@f:1

    public init(string: String) {
        self.string = string
        self.eIdx = self.string.endIndex
        self.index = self.string.startIndex
    }

    deinit { _close() }

    open func read() throws -> Character? { try lock.withLock { try _read() } }

    open func read(chars: inout [Character], maxLength: Int) throws -> Int { try lock.withLock { try _read(chars: &chars, maxLength: maxLength) } }

    open func append(to chars: inout [Character], maxLength: Int) throws -> Int { try lock.withLock { try _append(to: &chars, maxLength: maxLength) } }

    open func open() { lock.withLock { _open() } }

    open func close() { lock.withLock { _close() } }

    func _open() { if status == .notOpen { status = .open } }

    func _close() { if status == .open { status = .closed } }

    func _read() throws -> Character? {
        guard status == .open && index < eIdx else { return nil }
        let i = index
        string.formIndex(after: &index)
        return string[i]
    }

    func _read(chars: inout [Character], maxLength: Int) throws -> Int {
        if !chars.isEmpty { chars.removeAll(keepingCapacity: true) }
        return try _append(to: &chars, maxLength: maxLength)
    }

    func _append(to chars: inout [Character], maxLength: Int) throws -> Int {
        guard status == .open && maxLength != 0 && index < eIdx else { return 0 }

        let c = chars.count
        let i = (string.index(index, offsetBy: ((maxLength < 0) ? Int.max : maxLength), limitedBy: eIdx) ?? eIdx)

        chars.append(contentsOf: string[index ..< i])
        index = i
        return (chars.count - c)
    }
}
