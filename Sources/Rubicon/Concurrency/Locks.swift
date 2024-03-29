// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Locks.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: July 09, 2022
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

extension NSLocking {
    @discardableResult @inlinable public func withLock<T>(_ action: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try action()
    }
}

extension NSLock {
    @discardableResult @inlinable public func tryWithLock<T>(_ action: () throws -> T) rethrows -> T? {
        guard `try`() else { return nil }
        defer { unlock() }
        return try action()
    }

    @discardableResult @inlinable public func withLock<T>(before limit: Date, _ action: () throws -> T) rethrows -> T? {
        guard lock(before: limit) else { return nil }
        defer { unlock() }
        return try action()
    }
}

extension NSRecursiveLock {
    @discardableResult @inlinable public func tryWithLock<T>(_ action: () throws -> T) rethrows -> T? {
        guard `try`() else { return nil }
        defer { unlock() }
        return try action()
    }

    @discardableResult @inlinable public func withLock<T>(before limit: Date, _ action: () throws -> T) rethrows -> T? {
        guard lock(before: limit) else { return nil }
        defer { unlock() }
        return try action()
    }
}

extension NSCondition {
    @inlinable @discardableResult public func withLock<T>(_ action: () throws -> T) rethrows -> T {
        lock()
        defer {
            broadcast()
            unlock()
        }
        return try action()
    }

    @inlinable @discardableResult public func withLock<T>(if pred: @autoclosure () -> Bool, _ action: () throws -> T) rethrows -> T? {
        try withLock {
            guard pred() else { return nil }
            return try action()
        }
    }

    @inlinable @discardableResult public func withLockWait<T>(while pred: @autoclosure () -> Bool, _ action: () throws -> T) rethrows -> T {
        try withLock {
            while pred() { wait() }
            return try action()
        }
    }

    @inlinable @discardableResult public func withLockWait<T>(until limit: Date, while pred: @autoclosure () -> Bool, _ action: () throws -> T) rethrows -> T? {
        try withLock {
            while pred() { guard wait(until: limit) else { return nil } }
            return try action()
        }
    }

    @inlinable public func withLockWait(while pred: @autoclosure () -> Bool) {
        withLock { while pred() { wait() } }
    }

    @inlinable public func withLockWait(until limit: Date, while pred: @autoclosure () -> Bool) -> Bool {
        withLock {
            while pred() { guard wait(until: limit) else { return false } }
            return true
        }
    }

    @inlinable public func wait(while pred: @autoclosure () -> Bool) {
        while pred() { wait() }
    }

    @inlinable public func wait(while pred: @autoclosure () -> Bool, until limit: Date) -> Bool {
        while pred() { guard wait(until: limit) else { return !pred() } }
        return true
    }

    @inlinable public func wait<T>(while pred: @autoclosure () -> Bool, _ action: () throws -> T) rethrows -> T {
        while pred() { wait() }
        return try action()
    }

    @inlinable public func wait<T>(while pred: @autoclosure () -> Bool, until limit: Date, _ action: () throws -> T) rethrows -> T? {
        while pred() { guard wait(until: limit) else { return nil } }
        return try action()
    }
}
