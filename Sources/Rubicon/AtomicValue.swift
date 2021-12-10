/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: AtomicValue.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/20/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

open class AtomicValue<T> {
    private var v:    T
    private let lock: Conditional = Conditional()

    open var value: T {
        get { lock.withLock { v } }
        set { lock.withLock { v = newValue } }
    }

    public init(initialValue: T) { v = initialValue }

    open func waitUntil(valueIn c: T..., thenWithVal val: T? = nil) where T: Equatable { waitUntil(valueIn: c) }

    open func waitUntil(valueIn c: [T], thenWithVal val: T? = nil) where T: Equatable { waitUntil { check(c, for: $0) } }

    open func waitUntil(predicate: (T) -> Bool, thenWithVal val: T? = nil) { waitUntil(predicate: predicate, thenWithVal: val, {}) }

    /*==========================================================================================================*/
    /// Wait Until
    /// 
    /// - Parameters:
    ///   - c: The predicate values to test the variable for before the closure gets executed.
    ///   - val: The value you want the variable set to while executing the closure.
    ///   - cl: The closure to execute.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    open func waitUntil<V>(valueIn c: T..., thenWithVal val: T? = nil, _ cl: () throws -> V) rethrows -> V where T: Equatable { try waitUntil(valueIn: c, thenWithVal: val, cl) }

    open func waitUntil<V>(valueIn c: [T], thenWithVal val: T? = nil, _ cl: () throws -> V) rethrows -> V where T: Equatable { try waitUntil(predicate: { check(c, for: $0) }, thenWithVal: val, cl) }

    open func waitUntil<V>(predicate: (T) -> Bool, thenWithVal val: T? = nil, _ cl: () throws -> V) rethrows -> V {
        #if DEBUGRUBICON
            nDebug(.In, "waitUntil")
            defer { nDebug(.Out, "waitUntil") }
        #endif
        let vt: T = lock.withLock {
            #if DEBUGRUBICON
                nDebug(.In, "Predicate Test")
                defer { nDebug(.Out, "Predicate Test") }
            #endif
            while !predicate(v) {
                #if DEBUGRUBICON
                    nDebug(.In, "Wait for Predicate")
                    defer { nDebug(.Out, "Wait for Predicate") }
                #endif
                lock.broadcastWait()
            }
            return v
        }
        defer { value = vt }
        if let val = val { value = val }
        #if DEBUGRUBICON
            nDebug(.In, "waitUntil executing closure")
            defer { nDebug(.Out, "waitUntil executing closure") }
        #endif
        return try cl()
    }

    private func check(_ list: [T], for x: T) -> Bool where T: Equatable { list.contains { y in (x == y) } }
}
