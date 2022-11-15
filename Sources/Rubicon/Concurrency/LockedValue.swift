// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: LockedValue.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 05, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation

@propertyWrapper public struct LockedValue<T> {
    private var _wrappedValue: T
    public let  lock:          NSCondition = NSCondition()

    public var wrappedValue: T {
        get { lock.withLock { _wrappedValue } }
        set { lock.withLock { _wrappedValue = newValue } }
    }

    public init(wrappedValue: T) {
        _wrappedValue = wrappedValue
    }

    public mutating func withLock<R>(_ action: (inout T) throws -> R) rethrows -> R {
        try lock.withLock { try action(&_wrappedValue) }
    }

    public func isValue(_ predicate: (T) -> Bool) -> Bool {
        lock.withLock { predicate(_wrappedValue) }
    }

    public func waitWhile(_ predicate: (T) -> Bool) {
        lock.withLockWait(while: predicate(_wrappedValue))
    }

    public func waitUntil(_ limit: Date, while predicate: (T) -> Bool) -> Bool {
        lock.withLockWait(until: limit, while: predicate(_wrappedValue))
    }

    public mutating func withLock<R>(whenNot predicate: (T) -> Bool, _ action: (inout T) throws -> R) rethrows -> R {
        try lock.withLockWait(while: predicate(_wrappedValue)) { try action(&_wrappedValue) }
    }

    public mutating func withLock<R>(whenNot predicate: (T) -> Bool, waitUntil limit: Date, _ action: (inout T) throws -> R) rethrows -> R? {
        try lock.withLockWait(until: limit, while: predicate(_wrappedValue)) { try action(&_wrappedValue) }
    }
}
