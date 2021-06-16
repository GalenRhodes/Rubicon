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
    typealias PGMutex = UnsafeMutablePointer<SRWLOCK>
    typealias PGCond = UnsafeMutablePointer<CONDITION_VARIABLE>
    typealias PGLockTime = DWORD
#elseif CYGWIN
    typealias PGMutex = UnsafeMutablePointer<pthread_mutex_t?>
    typealias PGCond = UnsafeMutablePointer<pthread_cond_t?>
    typealias PGLockTime = timespec
#else
    typealias PGMutex = UnsafeMutablePointer<pthread_mutex_t>
    typealias PGCond = UnsafeMutablePointer<pthread_cond_t>
    typealias PGLockTime = timespec
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
        nDebug(.In, "LockCondition.broadcastWait()")
        defer { nDebug(.Out, "LockCondition.broadcastWait()") }
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

    private let cmutex: CondMutex = CondMutex()
    #if os(Windows) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        private let tmutex: CondMutex = CondMutex()
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

    open func unlock() {
        cmutex.unlock()
        #if os(Windows) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            tmutex.lBroadcast()
        #endif
    }

    open func wait() {
        nDebug(.In, "Conditional.wait()")
        defer { nDebug(.Out, "Conditional.wait()") }
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
        nDebug(.In, "Conditional.broadcast()")
        defer { nDebug(.Out, "Conditional.broadcast()") }
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

    private func bcastUnlock() {
        broadcast()
        unlock()
    }

    @discardableResult private func bcastWait(until limit: Date? = nil, willBroadcast bcast: Bool) -> Bool {
        if bcast { broadcast() }
        if let limit = limit { return wait(until: limit) }
        wait()
        return true
    }

    private func PGGetLockTime(from date: Date) -> PGLockTime? {
        #if os(Windows)
            return absoluteTimeSpecFrom(date: date)
        #else
            return absoluteTimeSpecFrom(date: date)
        #endif
    }
}

fileprivate class CondMutex {
    let cond:  PGCond  = PGCond.allocate(capacity: 1)
    let mutex: PGMutex = PGMutex.allocate(capacity: 1)

    init() {
        #if os(Windows)
            InitializeSRWLock(mutex)
            InitializeConditionVariable(cond)
        #else
            guard pthread_mutex_init(mutex, nil) == 0 else { fatalError("Could not initialize the mutex.") }
            guard pthread_cond_init(cond, nil) == 0 else { fatalError("Could not initialize the conditional.") }
        #endif
    }

    deinit {
        #if !os(Windows)
            pthread_cond_destroy(cond)
            pthread_mutex_destroy(mutex)
        #endif
        cond.deallocate()
        mutex.deallocate()
    }

    func tryLock() -> Bool {
        #if os(Windows)
            return (TryAcquireSRWLockExclusive(mutex) != 0)
        #else
            return (testOSFatalError(pthread_mutex_trylock(mutex), EBUSY) == 0)
        #endif
    }

    func lock() {
        #if os(Windows)
            AcquireSRWLockExclusive(mutex)
        #else
            testOSFatalError(pthread_mutex_lock(mutex))
        #endif
    }

    func unlock() {
        #if os(Windows)
            ReleaseSRWLockExclusive(mutex)
        #else
            testOSFatalError(pthread_mutex_unlock(mutex))
        #endif
    }

    @discardableResult func lWait(until time: PGLockTime) -> Bool {
        withLock { wait(until: time) }
    }

    func lBroadcast() {
        withLock { broadcast() }
    }

    func wait(until time: PGLockTime) -> Bool {
        #if os(Windows)
            return SleepConditionVariableSRW(timerCond, timerMutex, time, 0)
        #else
            var tm: PGLockTime = time
            return (testOSFatalError(pthread_cond_timedwait(cond, mutex, &tm), ETIMEDOUT) == 0)
        #endif
    }

    func wait() {
        nDebug(.In, "CondMutex.wait()")
        defer { nDebug(.Out, "CondMutex.wait()") }
        #if os(Windows)
            SleepConditionVariableSRW(cond, mutex, WinSDK.INFINITE, 0)
        #else
            testOSFatalError(pthread_cond_wait(cond, mutex))
        #endif
    }

    func broadcast() {
        nDebug(.In, "CondMutex.broadcast()")
        defer { nDebug(.Out, "CondMutex.broadcast()") }
        #if os(Windows)
            WakeAllConditionVariable(cond)
        #else
            testOSFatalError(pthread_cond_broadcast(cond))
        #endif
    }

    func signal() {
        #if os(Windows)
            WakeConditionVariable(cond)
        #else
            testOSFatalError(pthread_cond_signal(cond))
        #endif
    }

    @discardableResult func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
