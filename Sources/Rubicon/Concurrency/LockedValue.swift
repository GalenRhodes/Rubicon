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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

@propertyWrapper public struct LockedValue<T> {
    fileprivate var _wrappedValue: T
    fileprivate let _lock:         NSCondition = NSCondition()

    public var wrappedValue: T {
        get {
            _lock.lock()
            defer { _lock.unlock() }
            return _wrappedValue
        }
        set {
            _lock.lock()
            defer {
                _lock.signal()
                _lock.unlock()
            }
            _wrappedValue = newValue
        }
    }

    public init(wrappedValue: T) {
        _wrappedValue = wrappedValue
    }

    public mutating func withLock<R>(_ action: (inout T) throws -> R) rethrows -> R {
        _lock.lock()
        defer {
            _lock.signal()
            _lock.unlock()
        }
        return try action(&_wrappedValue)
    }

    public func isValue(_ predicate: (T) -> Bool) -> Bool {
        _lock.lock()
        defer { _lock.unlock() }
        return predicate(_wrappedValue)
    }

    public mutating func waitFor(condition predicate: (T) -> Bool) {
        _lock.lock()
        defer {
            _lock.signal()
            _lock.unlock()
        }
        while !predicate(_wrappedValue) { _lock.wait() }
    }

    public mutating func waitFor<R>(condition predicate: (T) -> Bool, thenWithLock action: (inout T) throws -> R) rethrows -> R {
        _lock.lock()
        defer {
            _lock.signal()
            _lock.unlock()
        }
        while !predicate(_wrappedValue) { _lock.wait() }
        return try action(&_wrappedValue)
    }

    public mutating func waitFor<R>(condition predicate: (T) -> Bool, until limit: Date, thenWithLock action: (inout T) throws -> R) rethrows -> R? {
        _lock.lock()
        defer {
            _lock.signal()
            _lock.unlock()
        }
        while !predicate(_wrappedValue) { if !_lock.wait(until: limit) { return nil } }
        return try action(&_wrappedValue)
    }
}

