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
            fatalError(ErrMsgWindowsNotSupported)
        #else
            _lock = pthread_rwlock_t()
            let r = pthread_rwlock_init(&_lock, nil)
            guard r == 0 else { fatalError(String(format: ErrMsgUnableToCreateLock, StrReadWrite, errorType(r))) }
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
        guard (r == 0) else { fatalError(String(format: ErrMsgUnableToObtainLock, StrRead, errorType(r))) }
    }

    public func writeLock() {
        let r = pthread_rwlock_wrlock(&_lock)
        guard (r == 0) else { fatalError(String(format: ErrMsgUnableToObtainLock, StrWrite, errorType(r))) }
    }

    public func tryReadLock() -> Bool {
        yyy(results: pthread_rwlock_tryrdlock(&_lock), busy: EBUSY, type: StrRead)
    }

    public func tryWriteLock() -> Bool {
        yyy(results: pthread_rwlock_trywrlock(&_lock), busy: EBUSY, type: StrWrite)
    }

    public func readLock(before limit: Date) -> Bool {
        return xxx(before: limit, type: StrRead) { t in
            #if os(OSX) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            return pthread_rwlock_tryrdlock(&_lock)
            #else
            return pthread_rwlock_timedrdlock(&_lock, &t)
            #endif
        }
    }

    public func writeLock(before limit: Date) -> Bool {
        return xxx(before: limit, type: StrWrite) { t in
            #if os(OSX) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            return pthread_rwlock_trywrlock(&_lock)
            #else
            return pthread_rwlock_timedwrlock(&_lock, &t)
            #endif
        }
    }

    private func xxx(before limit: Date, type s: String, _ b: (inout timespec) -> Int32) -> Bool {
        guard var t = limit.futureTimeSpec() else { return false }
        #if os(OSX) || os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        var r = b(&t)
        while (r == EBUSY) && (Date() < limit) { r = b(&t) }
        return yyy(results: r, busy: EBUSY, type: s)
        #else
        let r = b(&t)
        return yyy(results: r, busy: ETIMEDOUT, type: s)
        #endif
    }

    private func yyy(results: Int32, busy: Int32, type: String) -> Bool {
        if results == 0 { return true }
        if results == busy { return false }
        fatalError(String(format: ErrMsgUnableToObtainLock, type, errorType(results)))
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
        case EBUSY:   return ErrDescLockOwnedByAnotherThread
        case EAGAIN:  return ErrDescInsufficientResources
        case ENOMEM:  return ErrDescInsufficientMemory
        case EPERM:   return ErrDescInsufficientPermissions
        case EDEADLK: return ErrDescDeadLock
        default:      return String(format: ErrDescUnknownError, err)
    }
}
