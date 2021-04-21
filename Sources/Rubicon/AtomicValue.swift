/*
 *     PROJECT: Rubicon
 *    FILENAME: AtomicValue.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/20/21
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

open class AtomicValue<T> {
    private var _value: T
    private let cond:   Conditional   = Conditional()
    private let rwLock: ReadWriteLock = ReadWriteLock()

    open var value: T {
        get { rwLock.withReadLock { _value } }
        set { cond.withLock { rwLock.withWriteLock { _value = newValue } } }
    }

    public init(initialValue: T) {
        _value = initialValue
    }

    open func waitUntil<V>(valueIs test: (T) -> Bool, thenWithValueSetTo val: T, _ body: () throws -> V) rethrows -> V {
        try cond.withLock {
            while !test(_value) { cond.broadcastWait() }
            let v = _value
            rwLock.withWriteLock { _value = val }
            let r = try body()
            rwLock.withWriteLock { _value = v }
            return r
        }
    }
}
