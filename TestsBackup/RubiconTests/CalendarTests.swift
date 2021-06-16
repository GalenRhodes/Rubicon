/*=============================================================================================================================================================================*//*
 *     PROJECT: Rubicon
 *    FILENAME: CalendarTests.swift
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

import XCTest
import Foundation
import CoreFoundation
@testable import Rubicon

class CalendarTests: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    func printList(title: String, list: [String]) {
        print("==================================================================================")
        print("    \(title)")
        print("==================================================================================")
        for (i, s) in list.enumerated() { print("%02d> %s".format(i, s)) }
    }

    func testDaysSoFar() {
        //                        Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
        let counts: [[Int]] = [ [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ], [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ] ]
        var sofars: [[Int]] = [ [ 0, 0 ], [ 0, 0 ] ]

        for ly in (0 ..< 2) {
            let ccAr = counts[ly]
            var cc   = 0

            for m in (0 ..< 12) {
                cc += ccAr[m]
                sofars[ly].append(cc)
            }
        }

        print("[", terminator: "")
        for ly in (0 ..< 2) {
            let sfAR = sofars[ly]
            print(" [", terminator: "")

            for i in sfAR {
                print(" \(i),", terminator: "")
            }

            print(" ],", terminator: "")
        }
        print(" ]")
    }

    func testTimeZone() {
        let cmp = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        guard let s = cmp.secondsFromGMT else { fatalError("No Seconds From GMT!") }
        let qr = (-s).quotientAndRemainder(dividingBy: 3_600)
        print("Seconds From GMT: \(s); Hours: \(qr.quotient); Minutes: \(qr.remainder)")
        print("TimeZone: \("%+03d".format(qr.quotient))\("%02d".format(qr.remainder))")
        guard let tz = cmp.timeZone?.abbreviation(for: cmp.date ?? Date()) else { fatalError("No TimeZone?") }
        print("TimeZone Abbreviation: \"\(tz)\"")
    }

    func testNanos() {
        let cmp = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        guard let nanos = cmp.nanosecond else { fatalError("No Nanoseconds!") }
        guard let hour = cmp.hour else { fatalError("No Hours!") }
        guard let minute = cmp.minute else { fatalError("No Minutes!") }
        guard let seconds = cmp.second else { fatalError("No Seconds!") }

        let calcNanos = ((seconds + (minute * 60) + (hour * 3600)) * 1_000_000_000)

        print("Nanos Reported: \(nanos); Nanos Today: \(calcNanos)")
    }

    func testHour() {
        let cmp = Calendar.current.dateComponents(in: TimeZone.current, from: Date(timeIntervalSinceNow: 57600.0))
        print("Current Hour: \(cmp.hour ?? -1)")
    }

    func testCalendarLists() {
        let cal = Calendar.current

        printList(title: "AM/PM Symbols", list: [ cal.amSymbol, cal.pmSymbol ])

        printList(title: "weekdaySymbols", list: cal.weekdaySymbols)
        printList(title: "shortWeekdaySymbols", list: cal.shortWeekdaySymbols)
        printList(title: "veryShortWeekdaySymbols", list: cal.veryShortWeekdaySymbols)
        printList(title: "standaloneWeekdaySymbols", list: cal.standaloneWeekdaySymbols)
        printList(title: "shortStandaloneWeekdaySymbols", list: cal.shortStandaloneWeekdaySymbols)
        printList(title: "veryShortStandaloneWeekdaySymbols", list: cal.veryShortStandaloneWeekdaySymbols)

        printList(title: "monthSymbols", list: cal.monthSymbols)
        printList(title: "shortMonthSymbols", list: cal.shortMonthSymbols)
        printList(title: "veryShortMonthSymbols", list: cal.veryShortMonthSymbols)
        printList(title: "standaloneMonthSymbols", list: cal.standaloneMonthSymbols)
        printList(title: "shortStandaloneMonthSymbols", list: cal.shortStandaloneMonthSymbols)
        printList(title: "veryShortStandaloneMonthSymbols", list: cal.veryShortStandaloneMonthSymbols)

        printList(title: "quarterSymbols", list: cal.quarterSymbols)
        printList(title: "shortQuarterSymbols", list: cal.shortQuarterSymbols)
        printList(title: "standaloneQuarterSymbols", list: cal.standaloneQuarterSymbols)
        printList(title: "shortStandaloneQuarterSymbols", list: cal.shortStandaloneQuarterSymbols)

        printList(title: "eraSymbols", list: cal.eraSymbols)
        printList(title: "longEraSymbols", list: cal.longEraSymbols)
    }
}
