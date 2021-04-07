/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Conditional.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/1/20
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

public protocol LockCondition: Locking {
    func wait()

    func wait(until limit: Date) -> Bool

    func signal()

    func broadcast()

    func withLockWait(broadcastBeforeWait: Bool, _ cond: () -> Bool)

    func withLockWait<T>(broadcastBeforeWait: Bool, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T

    func withLockWait(until limit: Date, broadcastBeforeWait: Bool, _ cond: () -> Bool) -> Bool

    func withLockWait<T>(until limit: Date, broadcastBeforeWait: Bool, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T?

    func withLockWait(_ cond: () -> Bool)

    func withLockWait<T>(_ cond: () -> Bool, do block: () throws -> T) rethrows -> T

    func withLockWait(until limit: Date, _ cond: () -> Bool) -> Bool

    func withLockWait<T>(until limit: Date, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T?

    func withLockBroadcastWait(_ cond: () -> Bool)

    func withLockBroadcastWait<T>(_ cond: () -> Bool, do block: () throws -> T) rethrows -> T

    func withLockBroadcastWait(until limit: Date, _ cond: () -> Bool) -> Bool

    func withLockBroadcastWait<T>(until limit: Date, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T?
}

extension LockCondition {
    public func withLockWait(_ cond: () -> Bool) {
        withLockWait(broadcastBeforeWait: false, cond, do: {})
    }

    public func withLockWait<T>(_ cond: () -> Bool, do block: () throws -> T) rethrows -> T {
        try withLockWait(broadcastBeforeWait: false, cond, do: block)
    }

    public func withLockWait(until limit: Date, _ cond: () -> Bool) -> Bool {
        (withLockWait(until: limit, broadcastBeforeWait: false, cond, do: { true }) ?? false)
    }

    public func withLockWait<T>(until limit: Date, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T? {
        try withLockWait(until: limit, broadcastBeforeWait: false, cond, do: block)
    }

    public func withLockWait(broadcastBeforeWait bcast: Bool, _ cond: () -> Bool) {
        withLockWait(broadcastBeforeWait: bcast, cond, do: {})
    }

    public func withLockWait(until limit: Date, broadcastBeforeWait bcast: Bool, _ cond: () -> Bool) -> Bool {
        (withLockWait(until: limit, broadcastBeforeWait: bcast, cond, do: { true }) ?? false)
    }

    public func withLockBroadcastWait(_ cond: () -> Bool) {
        withLockWait(broadcastBeforeWait: true, cond)
    }

    public func withLockBroadcastWait<T>(_ cond: () -> Bool, do block: () throws -> T) rethrows -> T {
        try withLockWait(broadcastBeforeWait: true, cond, do: block)
    }

    public func withLockBroadcastWait(until limit: Date, _ cond: () -> Bool) -> Bool {
        withLockWait(until: limit, broadcastBeforeWait: true, cond)
    }

    public func withLockBroadcastWait<T>(until limit: Date, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T? {
        try withLockWait(until: limit, broadcastBeforeWait: true, cond, do: block)
    }

    public func broadcastWait() {
        broadcast()
        wait()
    }

    public func broadcastWait(until limit: Date) -> Bool {
        broadcast()
        return wait(until: limit)
    }

    public func signalWait() {
        signal()
        wait()
    }

    public func signalWait(until limit: Date) -> Bool {
        signal()
        return wait(until: limit)
    }
}

open class Conditional: LockCondition {

    let cmutex: CondMutex = CondMutex()
    #if os(Windows) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let tmutex: CondMutex = CondMutex()
    #endif

    public var name: String? = nil

    public init() {}

    open func tryLock() -> Bool {
        cmutex.tryLock()
    }

    open func lock(before limit: Date) -> Bool {
        #if os(Windows) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            if cmutex.tryLock() { return true }
            while let time: PGLockTime = PGGetLockTime(from: limit) {
                tmutex.lWait(until: time)
                if cmutex.tryLock() { return true }
            }
            return false
        #else
            guard var time: PGLockTime = PGGetLockTime(from: limit) else { return false }
            return (testOSFatalError(pthread_mutex_timedlock(cmutex.mutex, &time), ETIMEDOUT) == 0)
        #endif
    }

    open func lock() {
        cmutex.lock()
    }

    public final func unlock() {
        cmutex.unlock()
        #if os(Windows) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            tmutex.lBroadcast()
        #endif
    }

    open func wait() {
        cmutex.wait()
    }

    open func wait(until limit: Date) -> Bool {
        guard let time: PGLockTime = PGGetLockTime(from: limit) else { return false }
        return cmutex.wait(until: time)
    }

    open func signal() {
        cmutex.signal()
    }

    open func broadcast() {
        cmutex.broadcast()
    }

    @discardableResult open func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { bcastUnlock() }
        return try body()
    }

    @discardableResult open func withLock<T>(before date: Date, _ body: () throws -> T) rethrows -> T? {
        guard lock(before: date) else { return nil }
        defer { bcastUnlock() }
        return try body()
    }

    @discardableResult open func withLockTry<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryLock() else { return nil }
        defer { bcastUnlock() }
        return try body()
    }

    @discardableResult open func withLockWait<T>(broadcastBeforeWait bcast: Bool, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        while !cond() { bcastWait(willBroadcast: bcast) }
        return try block()
    }

    @discardableResult open func withLockWait<T>(until limit: Date, broadcastBeforeWait bcast: Bool, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T? {
        guard lock(before: limit) else { return nil }
        defer { unlock() }
        while !cond() { guard bcastWait(until: limit, willBroadcast: bcast) else { return nil } }
        return try block()
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

    final func PGGetLockTime(from date: Date) -> PGLockTime? {
        #if os(Windows)
            return timeIntervalFrom(date: date)
        #else
            return absoluteTimeSpecFrom(date: date)
        #endif
    }
}
