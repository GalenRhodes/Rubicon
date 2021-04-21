/*
 *     PROJECT: Rubicon
 *    FILENAME: ReadWriteLock.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/19/21
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

#if os(Windows)
    import WinSDK
    fileprivate typealias OSRWLock = UnsafeMutablePointer<SRWLOCK>
#else
    #if CYGWIN
        fileprivate typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t?>
    #else
        fileprivate typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t>
    #endif
#endif

open class ReadWriteLock {

    private enum RWState {
        case None
        case Read
        case Write
    }

    @ThreadLocal private var rwState: RWState = .None

    private var lock: OSRWLock

    public init() {
        lock = OSRWLock.allocate(capacity: 1)
        #if os(Windows)
            InitializeSRWLock(lock)
        #else
            guard pthread_rwlock_init(lock, nil) == 0 else { fatalError("Unable to initialize read/write lock.") }
        #endif
    }

    deinit {
        #if !os(Windows)
            pthread_rwlock_destroy(lock)
        #endif
        lock.deallocate()
    }

    open func readLock() {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        #if os(Windows)
            AcquireSRWLockShared(lock)
        #else
            guard pthread_rwlock_rdlock(lock) == 0 else { fatalError("Unknown Error.") }
        #endif
        rwState = .Read
    }

    open func tryReadLock() -> Bool {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        var success: Bool = false
        #if os(Windows)
            success = (TryAcquireSRWLockShared(lock) != 0)
        #else
            let r = pthread_rwlock_tryrdlock(lock)
            guard value(r, isOneOf: 0, EBUSY) else { fatalError("Unknown Error.") }
            success = (r == 0)
        #endif
        rwState = .Read
        return success
    }

    open func tryWriteLock() -> Bool {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        var success: Bool = false
        #if os(Windows)
            success = (TryAcquireSRWLockExclusive(lock) != 0)
        #else
            let r = pthread_rwlock_tryrdlock(lock)
            guard value(r, isOneOf: 0, EBUSY) else { fatalError("Unknown Error.") }
            success = (r == 0)
        #endif
        rwState = .Read
        return success
    }

    open func writeLock() {
        guard rwState == .None else { fatalError("Thread already owns the lock  for \(rwState == .Read ? "reading" : "writing").") }
        #if os(Windows)
            AcquireSRWLockExclusive(lock)
        #else
            guard pthread_rwlock_wrlock(lock) == 0 else { fatalError("Unknown Error.") }
        #endif
        rwState = .Write
    }

    open func unlock() {
        switch rwState {
            case .None:
                fatalError("Thread does not currently own the lock.")
            case .Read:
                #if os(Windows)
                    ReleaseSRWLockShared(lock)
                #else
                    pthread_rwlock_unlock(lock)
                #endif
            case .Write:
                #if os(Windows)
                    ReleaseSRWLockExclusive(lock)
                #else
                    pthread_rwlock_unlock(lock)
                #endif
        }
        rwState = .None
    }

    open func withReadLock<T>(_ body: () throws -> T) rethrows -> T {
        readLock()
        defer { unlock() }
        return try body()
    }

    open func withWriteLock<T>(_ body: () throws -> T) rethrows -> T {
        writeLock()
        defer { unlock() }
        return try body()
    }

    open func tryWithReadLock<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryReadLock() else { return nil }
        defer { unlock() }
        return try body()
    }

    open func tryWithWriteLock<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryWriteLock() else { return nil }
        defer { unlock() }
        return try body()
    }
}
