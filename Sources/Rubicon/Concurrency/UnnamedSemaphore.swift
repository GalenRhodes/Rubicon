/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: UnnamedSemaphore.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/4/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation

/*==============================================================================================================*/
/// This class implements an unnamed (inter-process) semaphore. This type of semaphore is visible only to threads
/// of the same process. If you need a semaphore that is visible to multiple processes then use a
/// `NamedSemaphore`.
///
open class UnnamedSemaphore: PGSemaphore {
    /*==========================================================================================================*/
    /// The maximum value of the semaphore. The current value will never go above this value.
    ///
    public let maxValue: Int
    /*==========================================================================================================*/
    /// The current value of the semaphore. If this value is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> then any call to `acquire()`, `tryAcquire()`, or
    /// `tryAcquire(until:)` will respectively either block, fail, or potentially timeout until this value becomes
    /// greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code>.
    ///
    public var value: Int { _lock.withLock { _value } }

    private var _value: Int
    private let _lock:  Conditional = Conditional()

    /*==========================================================================================================*/
    /// Create a new semaphore with the given initial `value`. Optionally you can give a maximum value as well. If
    /// you don't specify a maximum value then the value of
    /// <code>[Int.max](https://developer.apple.com/documentation/swift/int)</code> (9,223,372,036,854,775,807 on
    /// 64-bit CPUs or 2,147,483,647 on 32-bit CPUs) is used. _NOTE:_ If you use a value less than one (1) then
    /// the semaphore will need one or more calls to `release()` before any calls to `acquire()`, `tryAcquire()`,
    /// or `tryAcquire(until:)` will be allowed to acquire the semaphore.
    /// 
    /// - Parameters:
    ///   - initialValue: The initial value. May be less than <code>[zero](https://en.wikipedia.org/wiki/0)</code>
    ///                   but cannot be greater than the maximum value nor less than the value of
    ///                   <code>[Int.min](https://developer.apple.com/documentation/swift/int)</code>
    ///                   (-9,223,372,036,854,775,808 on 64-bit CPUs or -2,147,483,648 on 32-bit CPUs)
    ///   - maxValue: The maximum value. Defaults to the value of
    ///               <code>[Int.max](https://developer.apple.com/documentation/swift/int)</code>.
    ///
    public init(initialValue: Int, maxValue: Int = Int.max) {
        guard initialValue <= maxValue else { fatalError("Initial value (\(initialValue)) cannot be larger than the maximum value (\(maxValue)).") }
        self.maxValue = maxValue
        self._value = initialValue
    }

    /*==========================================================================================================*/
    /// Release the semaphore. Increments the value by one (1). If the value was previously less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then a waiting thread will be woken up and
    /// allowed to acquire the semaphore.
    /// 
    /// - Returns: `true` if successful. If the value before calling `release()` is already equal to the maximum
    ///            value then it is left unchanged and `false` is returned.
    ///
    @discardableResult open func release() -> Bool {
        _lock.withLock {
            guard _value < maxValue else { return false }
            _value += 1
            return true
        }
    }

    /*==========================================================================================================*/
    /// Acquire the semaphore. If the value before calling is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then the calling thread is blocked until it is
    /// greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
    ///
    open func acquire() {
        _lock.withLock {
            while _value < 1 { _lock.broadcastWait() }
            _value -= 1
        }
    }

    /*==========================================================================================================*/
    /// Attempt to acquire the semaphore. If the value before calling is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then this method fails by returning `false`.
    /// 
    /// - Returns: `true` if successful. `false` if value is less than or equal to
    ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
    ///
    open func tryAcquire() -> Bool {
        _lock.withLock {
            guard _value < 1 else { return false }
            _value -= 1
            return true
        }
    }

    /*==========================================================================================================*/
    /// Attempt to acquire the semaphore. If the value before calling is less than or equal to
    /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then the calling thread is blocked until either
    /// the value is greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) or until the amount of
    /// time specified by `until` has elapsed.
    /// 
    /// - Parameter until: the absolute time that this method will wait trying to acquire the semaphore.
    /// - Returns: `true` if successful or `false` if the specified time has elapsed.
    ///
    open func tryAcquire(until: Date) -> Bool {
        _lock.withLock {
            while _value < 1 {
                guard _lock.broadcastWait(until: until) else {
                    guard _value > 0 else { return false }
                    break
                }
            }
            _value -= 1
            return true
        }
    }
}
