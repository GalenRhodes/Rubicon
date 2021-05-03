/*
 *     PROJECT: Rubicon
 *    FILENAME: AtomicProperty.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/16/21
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
#elseif CYGWIN
    fileprivate typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t?>
#else
    fileprivate typealias OSRWLock = UnsafeMutablePointer<pthread_rwlock_t>
#endif

/*==============================================================================================================*/
/// A property wrapper to ensure that read/write access to a resource is atomic with respect to writes. Encloses
/// access to the property with a read/write mutex (lock) so that any writes to the property completely finish
/// before any reads are allowed.
///
@propertyWrapper
public class Atomic<T> {

    private let lock:  OSRWLock
    private var value: T

    public var wrappedValue: T {
        get {
            #if os(Windows)
                AcquireSRWLockShared(lock)
                defer { ReleaseSRWLockShared(lock) }
            #else
                guard pthread_rwlock_rdlock(lock) == 0 else { fatalError() }
                defer { guard pthread_rwlock_unlock(lock) == 0 else { fatalError() } }
            #endif
            return value
        }
        set {
            #if os(Windows)
                AcquireSRWLockExclusive(lock)
                defer { ReleaseSRWLockExclusive(lock) }
            #else
                guard pthread_rwlock_wrlock(lock) == 0 else { fatalError() }
                defer { guard pthread_rwlock_unlock(lock) == 0 else { fatalError() } }
            #endif
            value = newValue
        }
    }

    public init(wrappedValue: T) {
        lock = OSRWLock.allocate(capacity: 1)
        #if os(Windows)
            InitializeSRWLock(lock)
        #else
            guard pthread_rwlock_init(lock, nil) == 0 else { fatalError() }
        #endif
        value = wrappedValue
    }

    deinit {
        #if !os(Windows)
            pthread_rwlock_destroy(lock)
        #endif
        lock.deallocate()
    }
}
