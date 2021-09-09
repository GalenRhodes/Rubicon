/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/8/21
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
#if os(Windows)
    import WinSDK
#endif

/*==============================================================================================================*/
/// The number of nanoseconds in one second.
///
public let OneSecondNanos:  time_t = 1_000_000_000

/*==============================================================================================================*/
/// The number of microseconds in one second.
///
public let OneSecondMicros: time_t = 1_000_000

/*==============================================================================================================*/
/// The number of milliseconds in one second.
///
public let OneSecondMillis: time_t = 1_000

/*==============================================================================================================*/
/// Get the system time in nanoseconds.
///
/// - Parameter delta: The number of nanoseconds to add to the system time.
/// - Returns: The system time plus the value of `delta`.
///
@inlinable public func getSysTime(delta: time_t = 0) -> time_t {
    var ts: timespec = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return ((ts.tv_sec * OneSecondNanos) + ts.tv_nsec + delta)
}

fileprivate var sysTimeAdj:     Int?      = nil
fileprivate let sysTimeAdjLock: MutexLock = MutexLock()

/*==============================================================================================================*/
/// Calculates the average overhead of calling `getSysTime(delta:)` so that it can be factored into calculations.
///
/// - Returns: The average time in nanoseconds to call `getSysTime(delta:)`.
///
public func getSysTimeAdjustment() -> Int {
    sysTimeAdjLock.withLock {
        if let adj = sysTimeAdj { return adj }

        let reps:  Int = 10_000
        var total: Int = 0
        var time:  Int = getSysTime()

        for _ in (0 ..< reps) {
            let t = getSysTime()
            total += (t - time)
            time = t
        }

        let adj = (total / reps)
        sysTimeAdj = adj
        #if DEBUG
            print("\nSysTime Adjustment: \(adj) ns average.\n")
        #endif
        return adj
    }
}

/*==============================================================================================================*/
/// The `NanoSleep(seconds:nanos:)` function causes the calling thread to sleep for the amount of time specified
/// in the `seconds` and `nanos` parameters (the actual time slept may be longer, due to system latencies and
/// possible limitations in the timer resolution of the hardware). An unmasked signal will cause
/// `NanoSleep(seconds:nanos:)` to terminate the sleep early, regardless of the `SA_RESTART` value on the
/// interrupting signal.
///
/// - Parameters:
///   - seconds: The number of seconds to sleep.
///   - nanos: The number of additional nanoseconds to sleep.
/// - Throws: `CErrors.EINTER(description:)` if `NanoSleep(seconds:nanos:)` was interrupted by an unmasked signal.
/// - Throws: `CErrors.EINVAL(description:)` if `nanos` was greater than or equal to 1,000,000,000.
///
public func NanoSleep(seconds: time_t = 0, nanos: Int = 0) -> Int {
    guard nanos >= 0 && nanos < OneSecondNanos else { fatalError("Nanosecond value is invalid: \(nanos)") }
    var t1 = timespec(tv_sec: seconds, tv_nsec: nanos)
    var t2 = timespec(tv_sec: 0, tv_nsec: 0)
    guard nanosleep(&t1, &t2) != 0 else { return 0 }
    return ((t2.tv_sec * OneSecondNanos) + t2.tv_nsec)
}

/*==============================================================================================================*/
/// The `NanoSleep(seconds:nanos:)` function causes the calling thread to sleep for the amount of time specified
/// in the `seconds` and `nanos` parameters (the actual time slept may be longer, due to system latencies and
/// possible limitations in the timer resolution of the hardware). An unmasked signal will cause
/// `NanoSleep(seconds:nanos:)` to terminate the sleep early, regardless of the `SA_RESTART` value on the
/// interrupting signal.
///
/// - Parameters:
///   - seconds: The number of seconds to sleep.
///   - nanos: The number of additional nanoseconds to sleep.
///
public func NanoSleep2(seconds: time_t = 0, nanos: Int = 0) {
    guard nanos >= 0 && nanos < OneSecondNanos else { fatalError("Nanosecond value is invalid: \(nanos)") }
    var t1 = timespec(tv_sec: seconds, tv_nsec: nanos)
    var t2 = timespec(tv_sec: 0, tv_nsec: 0)

    repeat {
        guard nanosleep(&t1, &t2) != 0 else { break }
        guard errno == EINTR else { fatalError("Nanosleep error") }
        t1 = t2
        t2.tv_sec = 0
        t2.tv_nsec = 0
    }
    while true
}
