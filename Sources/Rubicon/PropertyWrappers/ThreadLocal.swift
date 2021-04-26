/*
 *     PROJECT: Rubicon
 *    FILENAME: ThreadLocalProperty.swift
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
    fileprivate typealias OSThreadKey = DWORD
#else
    fileprivate typealias OSThreadKey = pthread_key_t
#endif

fileprivate var tlsIdList: [Int: UnsafeMutablePointer<Int>] = [:]
fileprivate var nextTlsId: Int                              = 0
fileprivate let tlsLock:   NSLock                           = NSLock()

/*===============================================================================================================================================================================*/
/// Thread Local Property Wrapper. A property marked with this wrapper will reserve storage for each thread so that the values gotten and set will only be seen by that thread.
///
@propertyWrapper
public class ThreadLocal<T> {
    private var tlsData:      [Int: T] = [:]
    private let threadKey:    OSThreadKey
    private let defaultValue: T

    public var wrappedValue: T {
        get { (tlsData[getTlsId()] ?? defaultValue) }
        set { tlsData[getTlsId()] = newValue }
    }

    public init(wrappedValue: T) {
        #if os(Windows)
            threadKey = TlsAlloc()
            guard threadKey != TLS_OUT_OF_INDEXES else { fatalError("Unable to create thread local key.") }
        #else
            var key: OSThreadKey = 0
            guard pthread_key_create(&key, nil) == 0 else { fatalError("Unable to create thread local key.") }
            threadKey = key
        #endif
        defaultValue = wrappedValue
    }

    deinit {
        #if os(Windows)
            TlsSetValue(threadKey, nil)
            TlsFree(threadKey)
        #else
            pthread_setspecific(threadKey, nil)
            pthread_key_delete(threadKey)
        #endif
        tlsLock.withLock {
            for k: Int in tlsData.keys {
                if let ptr = tlsIdList[k] {
                    tlsIdList.removeValue(forKey: k)
                    ptr.deinitialize(count: 1)
                    ptr.deallocate()
                }
            }
        }
        tlsData.removeAll()
    }

    private func getTlsId() -> Int {
        #if os(Windows)
            guard let p = TlsGetValue(threadKey) else { return newTlsId() }
        #else
            guard let p = pthread_getspecific(threadKey) else { return newTlsId() }
        #endif
        return p.bindMemory(to: Int.self, capacity: 1).pointee
    }

    private func newTlsId() -> Int {
        let p = getNextTlsIdPtr()
        #if os(Windows)
            TlsSetValue(threadKey, p)
        #else
            pthread_setspecific(threadKey, p)
        #endif
        return p.pointee
    }

    private func getNextTlsIdPtr() -> UnsafeMutablePointer<Int> {
        tlsLock.withLock {
            let p = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            p.initialize(to: nextTlsId++)
            tlsIdList[p.pointee] = p
            return p
        }
    }
}
