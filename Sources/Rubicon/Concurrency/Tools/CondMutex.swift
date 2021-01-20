/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: CondMutex.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/11/20
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

    @usableFromInline typealias PGMutex = UnsafeMutablePointer<SRWLOCK>
    @usableFromInline typealias PGCond = UnsafeMutablePointer<CONDITION_VARIABLE>
    @usableFromInline typealias PGLockTime = DWORD
#else
    #if CYGWIN
        @usableFromInline typealias PGMutex = UnsafeMutablePointer<pthread_mutex_t?>
        @usableFromInline typealias PGCond = UnsafeMutablePointer<pthread_cond_t?>
    #else
        @usableFromInline typealias PGMutex = UnsafeMutablePointer<pthread_mutex_t>
        @usableFromInline typealias PGCond = UnsafeMutablePointer<pthread_cond_t>
    #endif
    @usableFromInline typealias PGLockTime = timespec
#endif

class CondMutex {
    let cond:  PGCond  = PGCond.allocate(capacity: 1)
    let mutex: PGMutex = PGMutex.allocate(capacity: 1)

    init() {
        #if os(Windows)
            InitializeSRWLock(mutex)
            InitializeConditionVariable(cond)
        #else
            pthread_mutex_init(mutex, nil)
            pthread_cond_init(cond, nil)
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

    final func tryLock() -> Bool {
        #if os(Windows)
            return (TryAcquireSRWLockExclusive(mutex) != 0)
        #else
            return (testOSFatalError(pthread_mutex_trylock(mutex), EBUSY) == 0)
        #endif
    }

    final func lock() {
        #if os(Windows)
            AcquireSRWLockExclusive(mutex)
        #else
            testOSFatalError(pthread_mutex_lock(mutex))
        #endif
    }

    final func unlock() {
        #if os(Windows)
            ReleaseSRWLockExclusive(mutex)
        #else
            testOSFatalError(pthread_mutex_unlock(mutex))
        #endif
    }

    @discardableResult final func lWait(until time: PGLockTime) -> Bool { withLock { wait(until: time) } }

    final func wait(until time: PGLockTime) -> Bool {
        #if os(Windows)
            return SleepConditionVariableSRW(timerCond, timerMutex, time, 0)
        #else
            var tm: PGLockTime = time
            return (testOSFatalError(pthread_cond_timedwait(cond, mutex, &tm), ETIMEDOUT) == 0)
        #endif
    }

    final func wait() {
        #if os(Windows)
            SleepConditionVariableSRW(cond, mutex, WinSDK.INFINITE, 0)
        #else
            testOSFatalError(pthread_cond_wait(cond, mutex))
        #endif
    }

    final func lBroadcast() { withLock { broadcast() } }

    final func broadcast() {
        #if os(Windows)
            WakeAllConditionVariable(cond)
        #else
            testOSFatalError(pthread_cond_broadcast(cond))
        #endif
    }

    final func signal() {
        #if os(Windows)
            WakeConditionVariable(cond)
        #else
            testOSFatalError(pthread_cond_signal(cond))
        #endif
    }

    @discardableResult final func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
