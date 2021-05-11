/*=============================================================================================================================================================================*//*
 *     PROJECT: Rubicon
 *    FILENAME: DateComponents.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/11/21
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

private let DaysSoFar: [[Int]] = [ [ 0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 ], [ 0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 ] ]

extension DateComponents {

    public var hour12: Int? {
        guard let h = hour else { return nil }
        return ((h == 0) ? 12 : ((h > 12) ? (h - 12) : h))
    }

    public var isLeapYear: Bool {
        guard let y = year else { return false }
        return (y.divisible(by: 4) && (!y.divisible(by: 100) || y.divisible(by: 400)))
    }

    public var dayOfYear: Int? {
        guard let d = day, let m = month else { return nil }
        return (DaysSoFar[isLeapYear ? 1 : 0][m] + d)
    }

    public var millisecond: Int? {
        guard let ns = nanosecond else { return nil }
        return (ns / 1_000_000)
    }

    public var millisecondsSinceEpoc: Int? {
        guard let secEpoch = date?.timeIntervalSince1970 else { return nil }
        return Int(secEpoch * 1_000.0)
    }

    public var secondsSinceEpoc: Int? {
        guard let secEpoch = date?.timeIntervalSince1970 else { return nil }
        return Int(secEpoch)
    }

    public var amPM: String? {
        guard let h = hour, let c = calendar else { return nil }
        return ((h < 12) ? c.amSymbol : c.pmSymbol)
    }

    public var secondsFromGMT: Int? {
        guard let dt = date else { return nil }
        let tz = (timeZone ?? TimeZone.current)
        return tz.secondsFromGMT(for: dt)
    }

    public var rfc822TimeZone: String? {
        guard let stz = secondsFromGMT else { return nil }
        let qr = stz.quotientAndRemainder(dividingBy: 3_600)
        return "\("%+03d".format(qr.quotient))\("%02d".format(qr.remainder))"
    }

    public var abbreviatedTimeZone: String? { (timeZone ?? TimeZone.current).abbreviation(for: date ?? Date()) }
}
