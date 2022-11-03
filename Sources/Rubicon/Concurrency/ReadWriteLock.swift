// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: ReadWriteLock.swift
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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

public class ReadWriteLock {
    private var _lock: pthread_rwlock_t

    public init() {
        #if os(Windows)
            fatalError("Windows is not yet supported.")
        #else
            _lock = pthread_rwlock_t()
            let r = pthread_rwlock_init(&_lock, nil)
            guard r == 0 else { fatalError("Unable to create read/write lock: \(errorType(r))") }
        #endif
    }

    deinit {
        #if !os(Windows)
            pthread_rwlock_destroy(&_lock)
        #endif
    }

    public func unlock() {
        pthread_rwlock_unlock(&_lock)
    }

    public func readLock() {
        let r = pthread_rwlock_rdlock(&_lock)
        guard (r == 0) else { fatalError("Unable to obtain read lock: \(errorType(r))") }
    }

    public func writeLock() {
        let r = pthread_rwlock_wrlock(&_lock)
        guard (r == 0) else { fatalError("Unable to obtain write lock: \(errorType(r))") }
    }

    public func tryReadLock() -> Bool {
        let r = pthread_rwlock_tryrdlock(&_lock)
        guard ((r == 0) || (r == EBUSY)) else { fatalError("Unable to obtain read lock: \(errorType(r))") }
        return (r == 0)
    }

    public func tryWriteLock() -> Bool {
        let r = pthread_rwlock_trywrlock(&_lock)
        guard ((r == 0) || (r == EBUSY)) else { fatalError("Unable to obtain write lock: \(errorType(r))") }
        return (r == 0)
    }

    public func readLock(before limit: Date) -> Bool {
        var r = pthread_rwlock_tryrdlock(&_lock)
        while ((r == EBUSY) && (limit.compare(Date()) == .orderedDescending)) { r = pthread_rwlock_tryrdlock(&_lock) }
        guard ((r == 0) || (r == EBUSY)) else { fatalError("Unable to obtain read lock: \(errorType(r))") }
        return (r == 0)
    }

    public func writeLock(before limit: Date) -> Bool {
        var r = pthread_rwlock_trywrlock(&_lock)
        while ((r == EBUSY) && (limit.compare(Date()) == .orderedDescending)) { r = pthread_rwlock_trywrlock(&_lock) }
        guard ((r == 0) || (r == EBUSY)) else { fatalError("Unable to obtain write lock: \(errorType(r))") }
        return (r == 0)
    }
}

extension ReadWriteLock {
    @inlinable public func withReadLock<T>(_ action: () throws -> T) rethrows -> T {
        readLock()
        defer { unlock() }
        return try action()
    }

    @inlinable public func withWriteLock<T>(_ action: () throws -> T) rethrows -> T {
        writeLock()
        defer { unlock() }
        return try action()
    }

    @inlinable public func tryWithReadLock<T>(_ action: () throws -> T) rethrows -> T? {
        guard tryReadLock() else { return nil }
        defer { unlock() }
        return try action()
    }

    @inlinable public func tryWithWriteLock<T>(_ action: () throws -> T) rethrows -> T? {
        guard tryWriteLock() else { return nil }
        defer { unlock() }
        return try action()
    }

    @inlinable public func tryWithReadLock<T>(before limit: Date, _ action: () throws -> T) rethrows -> T? {
        guard readLock(before: limit) else { return nil }
        defer { unlock() }
        return try action()
    }

    @inlinable public func tryWithWriteLock<T>(before limit: Date, _ action: () throws -> T) rethrows -> T? {
        guard writeLock(before: limit) else { return nil }
        defer { unlock() }
        return try action()
    }
}

fileprivate func errorType(_ err: Int32) -> String {
    switch err {
        case EBUSY:   return "[EBUSY] The lock is currently owned by another thread."
        case EAGAIN:  return "[EAGAIN] Insufficient resources."
        case ENOMEM:  return "[ENOMEM] Insufficient memory."
        case EPERM:   return "[EPERM] Insufficient permissions."
        case EDEADLK: return "[EDEADLK] A deadlock has occurred."
        default:      return "[\(err)] Unknown Error."
    }
}
