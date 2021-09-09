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

/*==============================================================================================================*/
/// Thread Local Property Wrapper. A property marked with this wrapper will reserve storage for each thread so
/// that the values gotten and set will only be seen by that thread.
///
/// NOTE: DispatchQueues reuse threads. This means that multiple items put onto a dispatch queue may see and
/// manipulate each other's data.
///
@propertyWrapper
public class ThreadLocal<T> {

    private var nextKeyId:    Int                         = 0
    private var keyIdMap:     [Int: T]                    = [:]
    private var keyIdList:    [UnsafeMutablePointer<Int>] = []
    private let lock:         MutexLock                   = MutexLock()
    private let threadKey:    OSThreadKey
    private let initialValue: T

    public var wrappedValue: T {
        get {
            lock.withLock {
                if let id: Int = getID() { return (keyIdMap[id] ?? storeInitialValue(id: id)) }
                return storeInitialValue(id: generateNewID())
            }
        }
        set {
            lock.withLock {
                if let id: Int = getID() { keyIdMap[id] = newValue }
                else { keyIdMap[generateNewID()] = newValue }
            }
        }
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
        initialValue = wrappedValue
        keyIdMap[generateNewID()] = wrappedValue
    }

    deinit {
        #if os(Windows)
            TlsSetValue(threadKey, nil)
            TlsFree(threadKey)
        #else
            pthread_setspecific(threadKey, nil)
            pthread_key_delete(threadKey)
        #endif
        keyIdList.forEach { kp in kp.deallocate() }
        keyIdList.removeAll()
        keyIdMap.removeAll()
    }

    private func getID() -> Int? {
        #if os(Windows)
            guard let p: UnsafeMutableRawPointer = TlsGetValue(threadKey) else { return nil }
        #else
            guard let p: UnsafeMutableRawPointer = pthread_getspecific(threadKey) else { return nil }
        #endif
        return p.assumingMemoryBound(to: Int.self).pointee
    }

    private func generateNewID() -> Int {
        let pt = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        pt.initialize(to: nextKeyId)
        keyIdList <+ pt
        #if os(Windows)
            TlsSetValue(threadKey, pt)
        #else
            pthread_setspecific(threadKey, pt)
        #endif
        return nextKeyId++
    }

    private func storeInitialValue(id: Int) -> T {
        keyIdMap[id] = initialValue
        guard let v: T = keyIdMap[id] else { fatalError() }
        return v
    }
}
