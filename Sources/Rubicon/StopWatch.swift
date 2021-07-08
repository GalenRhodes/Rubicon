/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 7/7/21
 *
 * Copyright © 2021. All rights reserved.
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

open class StopWatch {
    public enum LabelLength: Int { case Long = 0, Medium = 1, Short = 2 }

    public struct Field {
        //@f:0
        public static let names: [[String]] = [
            [ "days", "hours", "minutes", "seconds", "milliseconds", "microseconds", "nanoseconds", ],
            [ "days", "hrs",   "mins",    "secs",    "millis",       "micros",       "nanos",       ],
            [ "d",    "h",     "m",       "s",       "ms",           "µs",           "ns",          ],
        ]

        public static let Days   = Field(index: 0, div: 86_400_000_000_000, mod: Int.max)
        public static let Hours  = Field(index: 1, div: 3_600_000_000_000,  mod: 24     )
        public static let Mins   = Field(index: 2, div: 60_000_000_000,     mod: 60     )
        public static let Secs   = Field(index: 3, div: 1_000_000_000,      mod: 60     )
        public static let Millis = Field(index: 4, div: 1_000_000,          mod: 1_000  )
        public static let Micros = Field(index: 5, div: 1_000,              mod: 1_000  )
        public static let Nanos  = Field(index: 6, div: 1,                  mod: 1_000  )
        //@f:1

        public static let allFields: [Field] = [ .Days, .Hours, .Mins, .Secs, .Millis, .Micros, .Nanos, ]

        let mod:   Int
        let div:   Int
        let index: Int

        private init(index: Int, div: Int, mod: Int) {
            self.mod = mod
            self.div = div
            self.index = index
        }
    }

    typealias SWValues = (field: Field, value: Int)
    typealias SWRounding = (value: Int, carry: Int)

    private let offset:    Int
    private var descCache: String?    = nil
    private var values:    [SWValues] = []

    public private(set) var startTime:   Int  = 0
    public private(set) var stopTime:    Int  = 0
    public private(set) var elapsedTime: Int  = 0
    public private(set) var isRunning:   Bool = false

    public let labelLength: LabelLength
    public let lastField:   Field

    public init(labelLength: LabelLength = .Long, lastField: Field = .Millis, start: Bool = true) {
        self.labelLength = labelLength
        self.lastField = lastField
        self.offset = getSysTimeAdjustment()
        if start { self._start() }
    }

    open func start() {
        guard !isRunning else { return }
        _start()
    }

    open func stop() {
        guard isRunning else { return }
        stopTime = getSysTime()
        descCache = nil
        isRunning = false
        elapsedTime = ((stopTime == 0) ? 0 : (stopTime - startTime - offset))
        values = Field.allFields.map { ($0, $0.calcValue(nanos: elapsedTime)) }
    }
}

extension StopWatch.Field: Hashable {

    public func hash(into hasher: inout Hasher) { hasher.combine(index) }

    public static func == (lhs: Self, rhs: Self) -> Bool { (lhs.index == rhs.index) }
}

extension StopWatch.Field: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool { (lhs.index < rhs.index) }
}

extension StopWatch.Field {

    func calcRounding(_ value: Int) -> Int { ((value + (mod / 2)) / mod) }

    func calcOverflow(_ v: Int) -> StopWatch.SWRounding { (value: (v % mod), carry: (v / mod)) }

    func calcValue(nanos: Int) -> Int { ((nanos / div) % mod) }

    func label(_ length: StopWatch.LabelLength) -> String { Self.names[length.rawValue][index] }

    func toString(_ value: Int, length: StopWatch.LabelLength) -> String { "\(value) \(label(length))" }
}

extension StopWatch {
    public var days:    Int { values[Field.Days.index].value }
    public var hours:   Int { values[Field.Hours.index].value }
    public var minutes: Int { values[Field.Mins.index].value }
    public var seconds: Int { values[Field.Secs.index].value }
    public var millis:  Int { values[Field.Millis.index].value }
    public var micros:  Int { values[Field.Micros.index].value }
    public var nanos:   Int { values[Field.Nanos.index].value }

    func _start() {
        isRunning = true
        stopTime = 0
        elapsedTime = 0
        values = Field.allFields.map { ($0, 0) }
        descCache = nil
        startTime = getSysTime()
    }
}

extension StopWatch: CustomStringConvertible {

    public var description: String {
        if let d = descCache { return d }

        let i = Swift.min((values.firstIndex(where: { _, v in v > 0 }) ?? lastField.index), lastField.index)
        var v = roundUp(lastField.index)
        var d = lastField.toString(v.value, length: labelLength)

        for (field, value): SWValues in values[i ..< lastField.index].reversed() {
            v = field.calcOverflow(value + v.carry)
            d = "\(field.toString(v.value, length: labelLength)) \(d)"
        }

        descCache = d
        return d
    }

    func roundUp(_ i: Int) -> SWRounding {
        let (fld, val) = values[i]
        let idx        = (i + 1)

        guard idx < values.endIndex else { return (value: val, carry: 0) }
        guard idx > 1 else { return (value: calcRounding(idx: idx, value: val), carry: 0) }

        return fld.calcOverflow(calcRounding(idx: idx, value: val))
    }

    func calcRounding(idx: Int, value: Int) -> Int {
        let (fld, val): SWValues = values[idx]
        return (value + fld.calcRounding(val))
    }
}
