/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: StringFormat.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/7/21
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

//@f:0
// All together...                        group 1
let rx_a: String = "([nNrR%]|(?:\(rx_b)\(rx_c)\(rx_h)\(rx_f)))"

// Arg position...                        group 2 & 3
let rx_b: String = "(([1-9][0-9]*)\\$|\\<)?"

// Flags...                               group 4
let rx_c: String = "([ 0#(+,-]*)"

// Precision...                           group 5
let rx_d: String = "([1-9][0-9]*)?"

// Scale...                               group 6
let rx_e: String = "([0-9]*?[1-9])"

// Conversion Specifiers...               group 7
let rx_f: String = "([aAbBcCdeEfgGhHosSxX]|[tT]\(rx_g))"

// Time Modifiers...                      group 8
let rx_g: String = "([aAbBcCdDeFhHIjJklLmMNpQrRsSTyYzZ])"

let rx_h: String = "(?:\(rx_d)(?:\\.\(rx_e))?)"

let FormatPattern:       String = "\\%\(rx_a)"

let TextNaN:             String = "NaN"
let TextInfinity:        String = "Infinity"
let ErrorMessagePrefix:  String = "StringProtocol.format(_:...)"
let WildAssErrorMessage: String = "Something really bad happened that shouldn't have happened!"
let ErrMsgTooFewArgs:    String = "Not enough arguments."
let ErrMsgArgIndex:      String = "Argument index out of bounds."
let ErrMsgNoPrevArg:     String = "No previous argument."
let ErrMsgArgNotDate:    String = "Argument is not a date."
//@f:1

public var StringFormatIsStrict: Bool = false

extension StringProtocol {

    /*==========================================================================================================*/
    /// Allows creating a string using printf like formatting strings and arguments. However this version is
    /// modeled more after the Java version than the C version in order to make it a little easier to use.
    ///
    /// - Parameter args:
    /// - Returns:
    ///
    public func format(_ args: Any?...) -> String { _format(args) }

    /*==========================================================================================================*/
    /// Allows creating a string using printf like formatting strings and arguments. However this version is
    /// modeled more after the Java version than the C version in order to make it a little easier to use.
    ///
    /// - Parameter args:
    /// - Returns:
    ///
    public func format(arguments args: [Any?]) -> String { _format(args) }

    fileprivate func _format(_ args: [Any?]) -> String {
        var idx: StringIndex   = startIndex
        let ctx: FormatContext = FormatContext()

        guard let regex = RegularExpression(pattern: FormatPattern) else { FormatSpecs.formatFatalError(message: WildAssErrorMessage) }

        regex.forEach(in: String(self)) { match, flags, b in
            if let match = match {
                let range = match.range
                ctx.out.append(contentsOf: self[idx ..< range.lowerBound])
                idx = range.upperBound
                FormatSpecs(match, args: args, context: ctx).format()
            }
        }

        ctx.out.append(contentsOf: self[idx...])
        return ctx.out
    }
}

fileprivate class FormatContext {
    var pIdx: Int?   = nil
    var aIdx: Int    = 0
    var out:  String = ""

    init() {}
}

fileprivate class FormatSpecs {
    let convSpec:     String
    let timeConvSpec: String?

    private lazy var flags: FlagSet = FlagSet(m[4].subString, convSpec: convSpec)
    private lazy var scale: Int     = (m[5].subString?.toInteger() ?? 1).clamp(minValue: 1)
    private lazy var prec:  Int?    = m[6].subString?.toInteger().clamp(minValue: 1)
    private lazy var arg:   Any?    = foo()

    private let m:   RegularExpression.Match
    private let a:   [Any?]
    private let ctx: FormatContext

    init(_ match: RegularExpression.Match, args: [Any?], context: FormatContext) {
        guard let cSpec = match[7].subString ?? match[1].subString else { FormatSpecs.formatFatalError(message: WildAssErrorMessage) }
        convSpec = cSpec
        timeConvSpec = match[8].subString
        if convSpec.hasAnyPrefix("t", "T") { guard timeConvSpec != nil else { FormatSpecs.formatFatalError(message: WildAssErrorMessage) } }

        self.m = match
        self.a = args
        self.ctx = context
    }

    private func foo() -> Any? {
        guard let x = m[2].subString else { return foo(ErrMsgTooFewArgs, ctx.aIdx++) }
        if x == "<" {
            guard let i = ctx.pIdx else { FormatSpecs.formatFatalError(message: ErrMsgNoPrevArg) }
            return foo(ErrMsgArgIndex, i)
        }
        else {
            guard let i = m[3].subString?.toInteger() else { FormatSpecs.formatFatalError(message: WildAssErrorMessage) }
            return foo(ErrMsgArgIndex, i - 1)
        }
    }

    private func foo(_ msg: String, _ aIdx: Int) -> Any? {
        if a.indexRange.contains(aIdx) {
            ctx.pIdx = aIdx
            return a[aIdx]
        }
        if StringFormatIsStrict { FormatSpecs.formatFatalError(message: msg) }
        return nil
    }

    static func formatFatalError(message msg: String) -> Never {
        fatalError("\(ErrorMessagePrefix): \(msg)")
    }

    func format() {
        switch m.subString {
            case "%%":       ctx.out.append("%")
            case "%n":       ctx.out.append("\n")
            case "%r":       ctx.out.append("\r")
            case "%N", "%R": ctx.out.append("\r\n")
            default:
                switch convSpec {
                    case "b", "B": formatString(argument: String(describing: (((arg ?? false) as? Bool) ?? true)))
                    default:
                        if let obj = arg {
                            switch convSpec {
                                case "a", "A": break
                                case "d":      formatInteger(argument: obj)
                                case "e", "E": formatScientific(argument: obj)
                                case "f":      formatFloatingPoint(argument: obj, precision: prec)
                                case "g", "G": formatDecimalOrScientific(argument: obj)
                                case "h", "H": formatRadix(argument: HashOfAnything(obj), radix: 16, prefix: "0x")
                                case "o":      formatRadix(argument: obj, radix: 8, prefix: "0")
                                case "x", "X": formatRadix(argument: obj, radix: 16, prefix: "0x")
                                case "c", "C": formatString(argument: obj, scale: scale, precision: 1)
                                case "s", "S": formatString(argument: obj)
                                default:
                                    if let dt = getDateFromArgument(argument: obj) {
                                        let cal  = Calendar.current
                                        let cmps = cal.dateComponents(in: TimeZone.current, from: dt)
                                        switch timeConvSpec! {
                                            case "a":      if let i = cmps.weekday { formatString(argument: cal.shortWeekdaySymbols[i]) }
                                            case "A":      if let i = cmps.weekday { formatString(argument: cal.weekdaySymbols[i]) }
                                            case "b", "h": if let i = cmps.month { formatString(argument: cal.shortMonthSymbols[i]) }
                                            case "B":      if let i = cmps.month { formatString(argument: cal.monthSymbols[i]) }
                                            case "c":      formatString(argument: "%ta %<tb %<td %<tT %<tZ %<tY".format(dt))
                                            case "C":      if let y = cmps.year { formatString(argument: fmtDt(y / 100, places: 2)) }
                                            case "d":      if let d = cmps.day { formatString(argument: fmtDt(d, places: 2)) }
                                            case "D":      formatString(argument: "%tm/%<td/%<ty".format(dt))
                                            case "e":      if let d = cmps.day { formatString(argument: "\(d)") }
                                            case "F":      formatString(argument: "%tY-%<tm-%<td".format(dt))
                                            case "H":      if let h = cmps.hour { formatString(argument: fmtDt(h, places: 2)) }
                                            case "I":      if let h = cmps.hour12 { formatString(argument: fmtDt(h, places: 2)) }
                                            case "j":      if let d = cmps.dayOfYear { formatString(argument: fmtDt(d, places: 3)) }
                                            case "J":      if let d = cmps.dayOfYear { formatString(argument: "\(d)") }
                                            case "k":      if let h = cmps.hour { formatString(argument: "\(h)") }
                                            case "l":      if let h = cmps.hour12 { formatString(argument: "\(h)") }
                                            case "L":      if let m = cmps.millisecond { formatString(argument: fmtDt(m, places: 3)) }
                                            case "m":      if let m = cmps.month { formatString(argument: fmtDt(m, places: 2)) }
                                            case "M":      if let m = cmps.minute { formatString(argument: fmtDt(m, places: 2)) }
                                            case "N":      if let n = cmps.nanosecond { formatString(argument: fmtDt(n, places: 9)) }
                                            case "p":      if let s = cmps.amPM { formatString(argument: s) }
                                            case "Q":      if let m = cmps.millisecondsSinceEpoc { formatString(argument: "\(m)") }
                                            case "r":      formatString(argument: "%tI:%<tM:%<tS %<Tp".format(dt))
                                            case "R":      formatString(argument: "%tH:%<tM".format(dt))
                                            case "s":      if let s = cmps.secondsSinceEpoc { formatString(argument: "\(s)") }
                                            case "S":      if let s = cmps.second { formatString(argument: fmtDt(s, places: 2)) }
                                            case "T":      formatString(argument: "%tI:%<tM:%<tS".format(dt))
                                            case "y":      if let y = cmps.year { formatString(argument: fmtDt(y % 100, places: 2)) }
                                            case "Y":      if let y = cmps.year { formatString(argument: fmtDt(y, places: 2)) }
                                            case "z":      if let s = cmps.rfc822TimeZone { formatString(argument: s) }
                                            case "Z":      if let s = cmps.abbreviatedTimeZone { formatString(argument: s) }
                                            default:       formatFatalError(message: WildAssErrorMessage)
                                        }
                                    }
                                    else if StringFormatIsStrict {
                                        formatFatalError(message: ErrMsgArgNotDate)
                                    }
                                    else {
                                        ctx.out.append(contentsOf: m.subString)
                                    }
                            }
                        }
                        else {
                            formatString(argument: "NULL")
                        }
                }
        }
    }

    /*==========================================================================================================*/
    /// Attempt to get an instance of `Date` from the argument.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: An instance of `Date` or `nil` if the argument could not be transformed into a `Date`.
    ///
    private func getDateFromArgument(argument arg: Any) -> Date? {
        let oneSecInNanos: Double = 1_000_000_000.0

        if let d = (arg as? Date) { return d }
        if let d = castArgAsDouble(arg) { return Date(timeIntervalSince1970: d) }
        if let i = castArgAsInt(arg) { return Date(timeIntervalSince1970: Double(i) / oneSecInNanos) }
        if let i = castArgAsUInt(arg) { return Date(timeIntervalSince1970: Double(i) / oneSecInNanos) }
        return nil
    }

    /*==========================================================================================================*/
    /// Format the argument as either a floating point or in scientific notation depending on the magnitude.
    ///
    /// After rounding for the precision, the formatting of the resulting magnitude `m` depends on its value.
    ///
    /// If `m` is greater than or equal to 10<sup>-4</sup> but less than 10<sup>precision</sup> then it is
    /// represented in decimal format.
    ///
    /// If `m` is less than 10<sup>-4</sup> or greater than or equal to 10<sup>precision</sup>, then it is
    /// represented in computerized scientific notation.
    ///
    /// The total number of significant digits in `m` is equal to the precision. If the precision is not
    /// specified, then the default value is 6. If the precision is 0, then it is taken to be 1.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale.
    ///   - prec: The precision.
    ///   - flags: The formatting flags.
    ///
    private func formatDecimalOrScientific(argument arg: Any) {
        let dbl = getArgAsDouble(arg)
        guard !(dbl.isNaN || dbl.isInfinite) else { return formatFloatingPoint(argument: dbl, precision: prec) }
        let p = (prec ?? 6)
        formatDecimalOrScientific(value: dbl.roundTo(places: p), precision: p)
    }

    /*==========================================================================================================*/
    /// Called by `formatDecimalOrScientific(to:argument:scale:prec:flags:)` after the double value has been
    /// rounded to the provided precision.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - value: The double value.
    ///   - scale: The scale.
    ///   - prec: The precision.
    ///   - flags: The formatting flags.
    ///
    private func formatDecimalOrScientific(value: Double, precision prec: Int) {
        guard value.magnitude >= 0.0001 && value.magnitude < (10.0 ** prec) else { return formatScientific(argument: value) }
        formatFloatingPoint(argument: value, precision: prec)
    }

    /*==========================================================================================================*/
    /// Format the argument as a floating point value in scientific (exponential) form.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale (width).
    ///   - prec: The precision (number of places after the decimal.
    ///   - flags: The formatting flags.
    ///
    private func formatScientific(argument arg: Any) {
        let f = getFloatingPointFormatter(precision: prec)
        f.numberStyle = .scientific
        f.exponentSymbol = (flags.isUppercase ? "E" : "e")
        formatFloatingPoint(formatter: f, argument: arg, precision: prec)
    }

    /*==========================================================================================================*/
    /// Format the argument as an integer in the given base such as 16 (hexadecimal) or 8 (octal).
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - radix: The radix (base) for the representation.
    ///   - prefix: The prefix to put on the representation if the alternate form is chosen such as "0x" for
    ///             hexadecimal or "0" for octal.
    ///   - scale: The scale (width).
    ///   - flags: The formatting flags.
    ///
    private func formatRadix(argument arg: Any, radix: Int, prefix: String) {
        guard let i = getArgAsUInt(arg) else { return formatString(argument: TextNaN) }
        var s  = String(i, radix: radix)
        var ip = s.startIndex
        if flags.isAlternate { ip = s.prepend(contentsOf: prefix) }
        let sc = s.count
        if flags.isZeroPadded && (scale > Swift.max(1, sc)) { s.insert(contentsOf: String(repeating: "0", count: (scale - sc)), at: ip) }
        formatString(argument: s)
    }

    /*==========================================================================================================*/
    /// Formats an integer number.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale.
    ///   - flags: The flags.
    ///
    private func formatInteger(argument arg: Any) {
        guard let n = getArgAsNSNumber(arg) else { return ctx.out.append(contentsOf: TextNaN) }
        ctx.out.append(contentsOf: getDecimalFormatter().string(from: n) ?? TextNaN)
    }

    /*==========================================================================================================*/
    /// Formats a floating point number.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale.
    ///   - prec: The precision.
    ///   - flags: The flags.
    ///
    private func formatFloatingPoint(argument arg: Any, precision prec: Int?) {
        formatFloatingPoint(formatter: getFloatingPointFormatter(precision: prec), argument: arg, precision: prec)
    }

    /*==========================================================================================================*/
    /// Formats a floating point number.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - f: The number formatter.
    ///
    private func formatFloatingPoint(formatter f: NumberFormatter, argument arg: Any, precision prec: Int?) {
        let dbl = getArgAsDouble(arg)
        guard !dbl.isNaN else { return formatString(argument: TextNaN, scale: scale, precision: prec) }
        guard !dbl.isInfinite else { return formatString(argument: TextInfinity, scale: scale, precision: prec) }
        ctx.out.append(contentsOf: (f.string(from: NSNumber(value: dbl)) ?? TextNaN))
    }

    /*==========================================================================================================*/
    /// Format the argument as a string. The string is created as by `String(describing:)`.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale (width).
    ///   - flags: The flags.
    ///
    private func formatString(argument arg: Any, scale: Int, precision prec: Int?) {
        var s = String(describing: arg).truncate(count: (prec ?? Int.max))
        if scale > s.count { s = s.padding(toLength: scale, withPad: " ", onRight: flags.isLeftJustified) }
        ctx.out.append(s)
    }

    private func formatString(argument arg: Any) { formatString(argument: arg, scale: scale, precision: prec) }

    /*==========================================================================================================*/
    /// Attempt to get the argument as a Double value. If the argument cannot be converted into a Double value
    /// then a NaN value is returned.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The Double value. If conversion failed then the value's Double.isNaN property will return
    ///            `true`.
    ///
    private func getArgAsDouble(_ arg: Any) -> Double {
        if let d = castArgAsDouble(arg) { return d }
        if let i = castArgAsInt(arg) { return Double(i) }
        if let i = castArgAsUInt(arg) { return Double(i) }
        if let d = Double(String(describing: arg)) { return d }
        return Double.nan
    }

    /*==========================================================================================================*/
    /// Attempt to get the argument as a UInt64 value. If the argument cannot be converted into a UInt64 value
    /// then `nil` is returned.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The UInt64 value. If conversion failed then `nil` is returned instead.
    ///
    private func getArgAsUInt(_ arg: Any) -> UInt64? {
        if let i = castArgAsUInt(arg) { return i }
        else if let i = castArgAsInt(arg) { return UInt64(bitPattern: i) }
        else if let d = castArgAsDouble(arg) { return UInt64(d + 0.5) }
        return UInt64(String(describing: arg))
    }

    /*==========================================================================================================*/
    /// Attempt to get the argument as a Int64 value. If the argument cannot be converted into a Int64 value
    /// then `nil` is returned.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The Int64 value. If conversion failed then `nil` is returned instead.
    ///
    private func getArgAsInt(_ arg: Any) -> Int64? {
        if let i = castArgAsInt(arg) { return i }
        if let i = castArgAsUInt(arg) { return Int64(bitPattern: i) }
        if let d = castArgAsDouble(arg) { return Int64(d + 0.5) }
        return Int64(String(describing: arg))
    }

    /*==========================================================================================================*/
    /// Attempt to get the argument as a Double or Integer NSNumber value. If the argument cannot be converted
    /// into a NSNumber value then `nil` is returned.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The NSNumber value. If conversion failed then `nil` is returned instead.
    ///
    private func getArgAsNSNumber(_ arg: Any) -> NSNumber? {
        if let n = (arg as? NSNumber) { return n }
        if let i = castArgAsUInt(arg) { return NSNumber(value: i) }
        else if let i = castArgAsInt(arg) { return NSNumber(value: i) }
        else if let d = castArgAsDouble(arg) { return NSNumber(value: Int64(d + 0.5)) }
        else if let i = Int64(String(describing: arg)) { return NSNumber(value: i) }
        return nil
    }

    /*==========================================================================================================*/
    /// Attempt to cast the argument as a Double. If the argument is not a Double, Float, or Float80 value then
    /// `nil` is returned. If the value is a Float or Float80 then it is converted to a Double.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The Double value or `nil` if the argument is not a Double, Float, or Float80.
    ///
    private func castArgAsDouble(_ arg: Any) -> Double? {
        if let n = arg as? NSNumber { return n.doubleValue }
        if let n = arg as? Double { return n }
        if let n = arg as? Float { return Double(n) }
        #if !os(Windows) && arch(x86_64)
            if let n = arg as? Float80 { return Double(n) }
        #endif
        return nil
    }

    /*==========================================================================================================*/
    /// Attempt to cast the argument as an UInt64. If the argument is not one of the five standard unsigned
    /// integer types (UInt, UInt8, UInt16, UInt32, or UInt64) then `nil` is returned. Otherwise the value is
    /// converted to a UInt64.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The UInt64 value or `nil` if the argument is not one of the five standard unsigned integer
    ///            types.
    ///
    private func castArgAsUInt(_ arg: Any) -> UInt64? {
        if let n = arg as? NSNumber { return n.uint64Value }
        if let n = arg as? UInt { return numericCast(n) }
        if let n = arg as? UInt8 { return numericCast(n) }
        if let n = arg as? UInt16 { return numericCast(n) }
        if let n = arg as? UInt32 { return numericCast(n) }
        if let n = arg as? UInt64 { return n }
        return nil
    }

    /*==========================================================================================================*/
    /// Attempt to cast the argument as an Int64. If the argument is not one of the five standard signed integer
    /// types (Int, Int8, Int16, Int32, or Int64) then `nil` is returned. Otherwise the value is converted to a
    /// Int64.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The Int64 value or `nil` if the argument is not one of the five standard signed integer types.
    ///
    private func castArgAsInt(_ arg: Any) -> Int64? {
        if let n = arg as? NSNumber { return n.int64Value }
        if let n = arg as? Int { return numericCast(n) }
        if let n = arg as? Int8 { return numericCast(n) }
        if let n = arg as? Int16 { return numericCast(n) }
        if let n = arg as? Int32 { return numericCast(n) }
        if let n = arg as? Int64 { return n }
        return nil
    }

    /*==========================================================================================================*/
    /// Creates the base number formatter for use by `format(_:)`. Some implementations will throw an exception
    /// when you provide conflicting flags such as `-` and `0`. In our case we will simply choose one over the
    /// other.
    ///
    /// - Parameters:
    ///   - flags: The formatting flags.
    ///   - scale: The scale (minimum width).
    /// - Returns: The instance of
    ///            <code>[NumberFormatter](https://developer.apple.com/documentation/foundation/NumberFormatter)</code>
    ///
    private func getDecimalFormatter() -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = flags.useSeparators
        f.positivePrefix = (flags.alwaysShowPlusSign ? "+" : (flags.useSpaceForPlusSign ? " " : ""))
        f.negativePrefix = (flags.useParensForMinusSign ? "(" : "-")
        f.negativeSuffix = (flags.useParensForMinusSign ? ")" : "")

        if scale > 1 {
            f.formatWidth = scale
            f.paddingPosition = (flags.isZeroPadded ? .afterPrefix : (flags.isLeftJustified ? .afterSuffix : .beforePrefix))
            f.paddingCharacter = (flags.isZeroPadded ? "0" : " ")
        }

        return f
    }

    /*==========================================================================================================*/
    /// Creates the floating-point number formatter for use by `format(_:)`. Some implementations will throw an
    /// exception when you provide conflicting flags such as `-` and `0`. In our case we will simply choose one
    /// over the other.
    ///
    /// - Parameters:
    ///   - flags: The formatting flags.
    ///   - scale: The scale (minimum width).
    ///   - prec: The number of digits after the decimal point.
    /// - Returns: The instance of
    ///            <code>[NumberFormatter](https://developer.apple.com/documentation/foundation/NumberFormatter)</code>
    ///
    private func getFloatingPointFormatter(precision prec: Int?) -> NumberFormatter {
        let f = getDecimalFormatter()
        let p = (prec ?? 6)
        f.minimumFractionDigits = Swift.max(1, p)
        f.maximumFractionDigits = Swift.max(6, p)
        return f
    }

    /*==========================================================================================================*/
    /// Display an error message and terminate the application.
    ///
    /// - Parameter message: The message to display.
    /// - Returns: Never.
    ///
    private func formatFatalError(message: String) -> Never { fatalError("\(ErrorMessagePrefix): \(message)") }

    /*==========================================================================================================*/
    /// Format an integer number to a given number of places padding with zeros if needed.
    ///
    /// - Parameters:
    ///   - value: The value to format.
    ///   - places: The number of places to pad to if needed.
    /// - Returns: The resulting string.
    ///
    private func fmtDt(_ value: Int, places: Int) -> String {
        var s = String(value)
        let c = (places - s.count)
        if c > 0 { s.insert(contentsOf: String(repeating: "0", count: c), at: (value < 0 ? s.index(after: s.startIndex) : s.startIndex)) }
        return s
    }

    /*==============================================================================================================*/
    /// A class for holding formatting flags.
    ///
    private class FlagSet {
        /*==========================================================================================================*/
        /// An enumeration of the possible flags.
        ///
        enum FormatFlags { case Space, Zeros, Sign, Parenthesis, Justified, Separators, Uppercase, Alternate }

        /*==========================================================================================================*/
        /// A set of the current active flags.
        ///
        private(set) lazy var flags: Set<FormatFlags> = {
            var set = Set<FormatFlags>()
            if useSpaceForPlusSign { set.insert(.Space) }
            if isZeroPadded { set.insert(.Zeros) }
            if useParensForMinusSign { set.insert(.Parenthesis) }
            if alwaysShowPlusSign { set.insert(.Sign) }
            if isLeftJustified { set.insert(.Justified) }
            if useSeparators { set.insert(.Separators) }
            if isUppercase { set.insert(.Uppercase) }
            if isAlternate { set.insert(.Alternate) }
            return set
        }()

        let useSpaceForPlusSign:   Bool
        let isZeroPadded:          Bool
        let useParensForMinusSign: Bool
        let alwaysShowPlusSign:    Bool
        let isLeftJustified:       Bool
        let useSeparators:         Bool
        let isUppercase:           Bool
        let isAlternate:           Bool

        init(_ str: String?, convSpec: String) {
            if let str = str {
                self.useSpaceForPlusSign = str.contains { $0 == " " }
                self.isZeroPadded = str.contains { $0 == "0" }
                self.useParensForMinusSign = str.contains { $0 == "(" }
                self.alwaysShowPlusSign = str.contains { $0 == "+" }
                self.isLeftJustified = str.contains { $0 == "-" }
                self.useSeparators = str.contains { $0 == "," }
                self.isAlternate = str.contains { $0 == "#" }
            }
            else {
                self.useSpaceForPlusSign = false
                self.isZeroPadded = false
                self.useParensForMinusSign = false
                self.alwaysShowPlusSign = false
                self.isLeftJustified = false
                self.useSeparators = false
                self.isAlternate = false
            }
            self.isUppercase = (convSpec.first?.isUppercase ?? false)
        }
    }
}

