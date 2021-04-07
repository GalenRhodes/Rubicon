/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: NSLock.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/29/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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
#if os(Windows)
    import WinSDK
#endif

public typealias RecursiveLock = NSRecursiveLock
public typealias MutexLock = NSLock

public protocol Locking: NSLocking {

    var name: String? { get set }

    func tryLock() -> Bool

    func lock(before limit: Date) -> Bool

    func withLock<T>(_ body: () throws -> T) rethrows -> T

    func withLock<T>(before date: Date, _ body: () throws -> T) rethrows -> T?

    func withLockTry<T>(_ body: () throws -> T) rethrows -> T?
}

public extension Locking {

    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }

    func withLock<T>(before date: Date, _ body: () throws -> T) rethrows -> T? {
        guard lock(before: date) else { return nil }
        defer { unlock() }
        return try body()
    }

    func withLockTry<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryLock() else { return nil }
        defer { unlock() }
        return try body()
    }
}

extension NSLock: Locking {
    public func tryLock() -> Bool { `try`() }
}

extension NSRecursiveLock: Locking {
    public func tryLock() -> Bool { `try`() }
}

public extension NSCondition {

    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { bcastUnlock() }
        return try body()
    }

    func withLockWait<T>(broadcastBeforeWait bcast: Bool = false, _ cond: () -> Bool, do body: () throws -> T) rethrows -> T {
        try withLock {
            while !cond() { bcastWait(willBroadcast: bcast) }
            return try body()
        }
    }

    func withLockWait(broadcastBeforeWait bcast: Bool = false, _ cond: () -> Bool) {
        withLock { while !cond() { bcastWait(willBroadcast: bcast) } }
    }

    func withLockWait<T>(until limit: Date, broadcastBeforeWait bcast: Bool = false, _ cond: () -> Bool, do body: () throws -> T) rethrows -> T? {
        try withLock { try (cond() ? body() : (bcastWait(until: limit, willBroadcast: bcast) ? (cond() ? body() : nil) : nil)) }
    }

    func withLockWait(until limit: Date, broadcastBeforeWait bcast: Bool = false, _ cond: () -> Bool) -> Bool {
        withLock { (cond() ? true : (bcastWait(until: limit, willBroadcast: bcast) ? cond() : false)) }
    }

    final func bcastUnlock() {
        broadcast()
        unlock()
    }

    @discardableResult final func bcastWait(until limit: Date? = nil, willBroadcast bcast: Bool) -> Bool {
        if bcast { broadcast() }
        if let limit = limit { return wait(until: limit) }
        wait()
        return true
    }
}
