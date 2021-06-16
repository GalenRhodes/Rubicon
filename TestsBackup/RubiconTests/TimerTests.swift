/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: TimerTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/5/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation

@inlinable func getSysTime() -> UInt64 {
    var ts:    timespec  = timespec(tv_sec: 0, tv_nsec: 0)
    let clkid: clockid_t = CLOCK_MONOTONIC_RAW
    clock_gettime(clkid, &ts)
    return (UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec))
}

let reqRunTime: UInt64 = 20_000_000_000
let startTime:  UInt64 = getSysTime()
let runTime:    UInt64 = (startTime + reqRunTime) // run for two microseconds...
var endTime:    UInt64 = 0
var calls:      UInt64 = 1

repeat {
    endTime = getSysTime()
    calls += 1
}
while endTime < runTime

let elapsedTime = (endTime - startTime)

print("Requested Run Time: \(reqRunTime)ns")
print("        Start Time: \(startTime)ns")
print("          End Time: \(endTime)ns")
print("      Elapsed Time: \(elapsedTime)ns")
print("         Overshoot: \(elapsedTime - reqRunTime)ns")
print("        Iterations: \(calls)")
print("      Average Time: \((elapsedTime) / calls)ns")
