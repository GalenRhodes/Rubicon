/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: Locks.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: October 25, 2022
 *
 * Copyright © 2022 Project Galen. All rights reserved.
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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

extension NSLocking {
    @inlinable public func withLock<T>(_ action: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try action()
    }
}

extension NSLock {
    @inlinable public func tryWithLock<T>(_ action: () throws -> T) rethrows -> T? {
        guard `try`() else { return nil }
        defer { unlock() }
        return try action()
    }

    @inlinable public func withLock<T>(before limit: Date, _ action: () throws -> T) rethrows -> T? {
        guard lock(before: limit) else { return nil }
        defer { unlock() }
        return try action()
    }
}

extension NSRecursiveLock {
    @inlinable public func tryWithLock<T>(_ action: () throws -> T) rethrows -> T? {
        guard `try`() else { return nil }
        defer { unlock() }
        return try action()
    }

    @inlinable public func withLock<T>(before limit: Date, _ action: () throws -> T) rethrows -> T? {
        guard lock(before: limit) else { return nil }
        defer { unlock() }
        return try action()
    }
}

extension NSCondition {
    @inlinable public func withLockWait<T>(broadcast bc: Bool = false, for predicate: () throws -> Bool, _ action: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        while try (!predicate()) {
            wait()
        }
        defer {
            if bc { broadcast() }
            else { signal() }
        }
        return try action()
    }

    @inlinable public func withLockWait<T>(broadcast bc: Bool = false, until limit: Date, for predicate: () throws -> Bool, _ action: () throws -> T) rethrows -> T? {
        lock()
        defer { unlock() }
        while try (!predicate()) {
            guard wait(until: limit) else { return nil }
        }
        defer {
            if bc { broadcast() }
            else { signal() }
        }
        return try action()
    }
}
