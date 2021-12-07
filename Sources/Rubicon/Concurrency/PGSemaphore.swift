/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: Semaphore.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/3/21
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

public protocol PGSemaphore {
    /*==========================================================================================================*/
    /// The maximum value of the semaphore. The current value will never go above this value.
    ///
    var maxValue: Int { get }
    /*==========================================================================================================*/
    /// The current value of the semaphore. If this value is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> then any call to `acquire()`, `tryAcquire()`, or
    /// `tryAcquire(until:)` will respectively either block, fail, or potentially timeout until this value becomes
    /// greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code>.
    ///
    var value:    Int { get }

    /*==========================================================================================================*/
    /// Release the semaphore. Increments the value by one (1). If the value was previously less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then a waiting thread will be woken up and
    /// allowed to acquire the semaphore.
    /// 
    /// - Returns: `true` if successful. If the value before calling `release()` is already equal to the maximum
    ///            value then it is left unchanged and `false` is returned.
    ///
    @discardableResult func release() -> Bool

    /*==========================================================================================================*/
    /// Acquire the semaphore. If the value before calling is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then the calling thread is blocked until it is
    /// greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
    ///
    func acquire()

    /*==========================================================================================================*/
    /// Attempt to acquire the semaphore. If the value before calling is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then this method fails by returning `false`.
    /// 
    /// - Returns: `true` if successful. `false` if value is less than or equal to
    ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
    ///
    func tryAcquire() -> Bool

    /*==========================================================================================================*/
    /// Attempt to acquire the semaphore. If the value before calling is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then the calling thread is blocked until either
    /// the value is greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) or until the amount of
    /// time specified by `until` has elapsed.
    /// 
    /// - Parameter until: the absolute time that this method will wait trying to acquire the semaphore.
    /// - Returns: `true` if successful or `false` if the specified time has elapsed.
    ///
    func tryAcquire(until: Date) -> Bool

    /*==========================================================================================================*/
    /// Execute the given closure with the acquired semaphore. This method will acquire the semaphore, execute the
    /// closure, and then release the semaphore.
    /// 
    /// - Parameter body: The closure to execute.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure. The semaphore will be released if an error is thrown.
    ///
    func withSemaphore<T>(_ body: () throws -> T) rethrows -> T

    /*==========================================================================================================*/
    /// Execute the given closure with the acquired semaphore. This method will attempt to acquire the semaphore,
    /// execute the closure, and then release the semaphore. If the semaphore cannot be acquired then `nil` is
    /// returned without the closure ever being executed.
    /// 
    /// - Parameter body: The closure to execute.
    /// - Returns: The value returned by the closure or `nil` if the semaphore could not be acquired.
    /// - Throws: Any error thrown by the closure. The semaphore will be released if an error is thrown.
    ///
    func withSemaphoreTry<T>(_ body: () throws -> T) rethrows -> T?

    /*==========================================================================================================*/
    /// Execute the given closure with the acquired semaphore. This method will attempt to acquire the semaphore,
    /// execute the closure, and then release the semaphore. If the semaphore cannot be acquired before the
    /// timeout then `nil` is returned without the closure ever being executed.
    /// 
    /// - Parameters:
    ///   - until: the absolute time that the method will wait trying to acquire the semaphore.
    ///   - body: the closure to execute.
    /// - Returns: The value returned by the closure or `nil` if the semaphore could not be acquired.
    /// - Throws: Any error thrown by the closure. The semaphore will be released if an error is thrown.
    ///
    func withSemaphore<T>(waitUntil until: Date, _ body: () throws -> T) rethrows -> T?
}

extension PGSemaphore {

    /*==========================================================================================================*/
    /// Execute the given closure with the acquired semaphore. This method will acquire the semaphore, execute the
    /// closure, and then release the semaphore.
    /// 
    /// - Parameter body: The closure to execute.
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure. The semaphore will be released if an error is thrown.
    ///
    @inlinable public func withSemaphore<T>(_ body: () throws -> T) rethrows -> T {
        acquire()
        defer { release() }
        return try body()
    }

    /*==========================================================================================================*/
    /// Execute the given closure with the acquired semaphore. This method will attempt to acquire the semaphore,
    /// execute the closure, and then release the semaphore. If the semaphore cannot be acquired then `nil` is
    /// returned without the closure ever being executed.
    /// 
    /// - Parameter body: The closure to execute.
    /// - Returns: The value returned by the closure or `nil` if the semaphore could not be acquired.
    /// - Throws: Any error thrown by the closure. The semaphore will be released if an error is thrown.
    ///
    @inlinable public func withSemaphoreTry<T>(_ body: () throws -> T) rethrows -> T? {
        guard tryAcquire() else { return nil }
        defer { release() }
        return try body()
    }

    /*==========================================================================================================*/
    /// Execute the given closure with the acquired semaphore. This method will attempt to acquire the semaphore,
    /// execute the closure, and then release the semaphore. If the semaphore cannot be acquired before the
    /// timeout then `nil` is returned without the closure ever being executed.
    /// 
    /// - Parameters:
    ///   - until: the absolute time that the method will wait trying to acquire the semaphore.
    ///   - body: the closure to execute.
    /// - Returns: The value returned by the closure or `nil` if the semaphore could not be acquired.
    /// - Throws: Any error thrown by the closure. The semaphore will be released if an error is thrown.
    ///
    @inlinable public func withSemaphore<T>(waitUntil until: Date, _ body: () throws -> T) rethrows -> T? {
        guard tryAcquire(until: until) else { return nil }
        defer { release() }
        return try body()
    }
}
