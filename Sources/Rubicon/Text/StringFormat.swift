/*
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
 *//*============================================================================================================================================================================*/

import Foundation
import CoreFoundation

private let FormatPattern:       String = "\\%(\\%|[nNrR]|(?:([1-9][0-9]*\\$|\\<)?([ 0#(+,-]*)(?:([0-9]+)(?:\\.([1-9][0-9]*))?)?([aAbBcCdeEfgGhHosSxX]|[tT]([aAbBcCdDeFhHIjJklLmMNpQrRsSTyYzZ]))))"
private let TextNaN:             String = "NaN"
private let TextInfinity:        String = "Infinity"
private let ErrorMessagePrefix:  String = "StringProtocol.format(_:...)"
private let WildAssErrorMessage: String = "\(ErrorMessagePrefix): Something really bad happened that shouldn't have happened!"

public var StringFormatIsStrict: Bool = false

extension StringProtocol {
    /*==========================================================================================================*/
    /// Allows creating a string using printf like formatting strings and arguments. However this version is
    /// modeled more after the Java version than the C version in order to make it a little easier to use.
    ///
    ///
    /// - Parameter args:
    /// - Returns:
    ///
    public func format(_ args: Any?...) -> String {
        var out: String       = ""
        var idx: String.Index = startIndex
        var aIdx              = args.startIndex

        guard let regex = RegularExpression(pattern: FormatPattern) else { fatalError(WildAssErrorMessage) }
        regex.forEachMatch(in: String(self)) { match, flags, b in
            if let match = match {
                let range = match.range

                out.append(contentsOf: self[idx ..< range.lowerBound])
                idx = range.lowerBound

                if var convSpec = match.groups[6].subString {
                    let argSpec = match.groups[2].subString
                    let flags   = FlagSet(match.groups[3].subString, convSpec: &convSpec)
                    let scale   = (match.groups[4].subString?.toInteger() ?? 1).clamp(minValue: 1)
                    let prec    = (match.groups[5].subString?.toInteger() ?? 6).clamp(minValue: 1)
                    let _arg    = getFormatArgument(argumentSpec: argSpec, argumentIndex: &aIdx, arguments: args)

                    switch convSpec {
                        case "b": formatBoolean(to: &out, argument: _arg, scale: scale, flags: flags)
                        default:
                            if let arg = _arg {
                                switch convSpec {
                                    case "%": formatString(to: &out, argument: "%", scale: scale, flags: flags)
                                    case "a": break
                                    case "c": formatCharacter(to: &out, argument: arg, scale: scale, flags: flags)
                                    case "d": formatInteger(to: &out, argument: arg, scale: scale, flags: flags)
                                    case "e": formatScientific(to: &out, argument: arg, scale: scale, prec: prec, flags: flags)
                                    case "f": formatFloatingPoint(to: &out, argument: arg, scale: scale, prec: prec, flags: flags)
                                    case "g": formatDecimalOrScientific(to: &out, argument: arg, scale: scale, prec: prec, flags: flags)
                                    case "h": formatHexadecimal(to: &out, argument: HashOfAnything(arg), scale: scale, flags: flags)
                                    case "n": out.append(flags.isUppercase ? "\r\n" : "\n")
                                    case "o": formatOctal(to: &out, argument: arg, scale: scale, flags: flags)
                                    case "r": out.append(flags.isUppercase ? "\r\n" : "\r")
                                    case "s": formatString(to: &out, argument: arg, scale: scale, flags: flags)
                                    case "x": formatHexadecimal(to: &out, argument: arg, scale: scale, flags: flags)
                                    default:  formatDateTime(to: &out, dateSpecifier: match.groups[7].subString, argument: arg, scale: scale, flags: flags)
                                }
                            }
                            else {
                                fatalError(WildAssErrorMessage)
                            }
                    }
                    idx = range.upperBound
                }
                else {
                    out.append(contentsOf: self[idx ..< range.upperBound])
                    idx = range.upperBound
                }
            }
        }

        out.append(contentsOf: self[idx ..< endIndex])
        return out
    }

    private func formatDateTime(to out: inout String, dateSpecifier tSpec: String?, argument arg: Any, scale: Int, flags: FlagSet) {
        if let tSpec = tSpec {
            if let dt = getDateFromArgument(argument: arg) {
                let cal  = Calendar.current
                let cmps = cal.dateComponents(in: TimeZone.current, from: dt)
                let f2   = NumberFormatter()
                f2.formatWidth = 2
                f2.paddingCharacter = "0"
                f2.paddingPosition = .beforePrefix
                f2.usesGroupingSeparator = false

                switch tSpec {
                    case "a":      if let i = cmps.weekday { formatString(to: &out, argument: cal.shortWeekdaySymbols[i], scale: scale, flags: flags) }
                    case "A":      if let i = cmps.weekday { formatString(to: &out, argument: cal.weekdaySymbols[i], scale: scale, flags: flags) }
                    case "b", "h": if let i = cmps.month { formatString(to: &out, argument: cal.shortMonthSymbols[i], scale: scale, flags: flags) }
                    case "B":      if let i = cmps.month { formatString(to: &out, argument: cal.monthSymbols[i], scale: scale, flags: flags) }
                    case "c":      formatString(to: &out, argument: "%ta %<tb %<td %<tT %<tZ %<tY".format(dt), scale: scale, flags: flags)
                    case "C":      if let y = cmps.year { formatString(to: &out, argument: FmtDt(y / 100, places: 2), scale: scale, flags: flags) }
                    case "d":      if let d = cmps.day { formatString(to: &out, argument: FmtDt(d, places: 2), scale: scale, flags: flags) }
                    case "D":      formatString(to: &out, argument: "%tm/%<td/%<ty".format(dt), scale: scale, flags: flags)
                    case "e":      if let d = cmps.day { formatString(to: &out, argument: "\(d)", scale: scale, flags: flags) }
                    case "F":      formatString(to: &out, argument: "%tY-%<tm-%<td".format(dt), scale: scale, flags: flags)
                    case "H":      if let h = cmps.hour { formatString(to: &out, argument: FmtDt(h, places: 2), scale: scale, flags: flags) }
                    case "I":      if let h = cmps.hour12 { formatString(to: &out, argument: FmtDt(h, places: 2), scale: scale, flags: flags) }
                    case "j":      if let d = cmps.dayOfYear { formatString(to: &out, argument: FmtDt(d, places: 3), scale: scale, flags: flags) }
                    case "J":      if let d = cmps.dayOfYear { formatString(to: &out, argument: "\(d)", scale: scale, flags: flags) }
                    case "k":      if let h = cmps.hour { formatString(to: &out, argument: "\(h)", scale: scale, flags: flags) }
                    case "l":      if let h = cmps.hour12 { formatString(to: &out, argument: "\(h)", scale: scale, flags: flags) }
                    case "L":      if let m = cmps.millisecond { formatString(to: &out, argument: FmtDt(m, places: 3), scale: scale, flags: flags) }
                    case "m":      if let m = cmps.month { formatString(to: &out, argument: FmtDt(m, places: 2), scale: scale, flags: flags) }
                    case "M":      if let m = cmps.minute { formatString(to: &out, argument: FmtDt(m, places: 2), scale: scale, flags: flags) }
                    case "N":      if let n = cmps.nanosecond { formatString(to: &out, argument: FmtDt(n, places: 9), scale: scale, flags: flags) }
                    case "p":      if let s = cmps.amPM { formatString(to: &out, argument: s, scale: scale, flags: flags) }
                    case "Q":      if let m = cmps.millisecondsSinceEpoc { formatString(to: &out, argument: "\(m)", scale: scale, flags: flags) }
                    case "r":      formatString(to: &out, argument: "%tI:%<tM:%<tS %<Tp".format(dt), scale: scale, flags: flags)
                    case "R":      formatString(to: &out, argument: "%tH:%<tM".format(dt), scale: scale, flags: flags)
                    case "s":      if let s = cmps.secondsSinceEpoc { formatString(to: &out, argument: "\(s)", scale: scale, flags: flags) }
                    case "S":      if let s = cmps.second { formatString(to: &out, argument: FmtDt(s, places: 2), scale: scale, flags: flags) }
                    case "T":      formatString(to: &out, argument: "%tI:%<tM:%<tS".format(dt), scale: scale, flags: flags)
                    case "y":      if let y = cmps.year { formatString(to: &out, argument: FmtDt(y % 100, places: 2), scale: scale, flags: flags) }
                    case "Y":      if let y = cmps.year { formatString(to: &out, argument: FmtDt(y, places: 2), scale: scale, flags: flags) }
                    case "z":      if let s = cmps.rfc822TimeZone { formatString(to: &out, argument: s, scale: scale, flags: flags) }
                    case "Z":      if let s = cmps.abbreviatedTimeZone { formatString(to: &out, argument: s, scale: scale, flags: flags) }
                    default:       fatalError(WildAssErrorMessage)
                }
            }
            else if StringFormatIsStrict {
                fatalError("\(ErrorMessagePrefix): Argument is not a date.")
            }
        }
        else {
            fatalError(WildAssErrorMessage)
        }
    }

    private func getDateFromArgument(argument arg: Any) -> Date? {
        let oneSecInNanos: Double = 1_000_000_000.0

        if let d = (arg as? Date) { return d }
        if let d = (arg as? Double) { return Date(timeIntervalSince1970: d) }
        if let f = (arg as? Float) { return Date(timeIntervalSince1970: Double(f)) }
        #if !os(Windows) && (arch(i386) || arch(x86_64))
            if let f80 = (arg as? Float80) { return Date(timeIntervalSince1970: Double(f80)) }
        #endif
        #if arch(arm64) || arch(x86_64) || arch(powerpc64) || arch(powerpc64le) || arch(s390x)
            if let i = (arg as? Int) { return Date(timeIntervalSince1970: Double(i) / oneSecInNanos) }
            if let ui = (arg as? UInt) { return Date(timeIntervalSince1970: Double(ui) / oneSecInNanos) }
        #else
            if let i = (arg as? Int64) { return Date(timeIntervalSince1970: Double(i) / oneSecInNanos) }
            if let ui = (arg as? UInt64) { return Date(timeIntervalSince1970: Double(ui) / oneSecInNanos) }
        #endif
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
    private func formatDecimalOrScientific(to out: inout String, argument arg: Any, scale: Int, prec: Int, flags: FlagSet) {
        let dbl = getArgAsDouble(arg)
        if dbl.isNaN {
            formatString(to: &out, argument: TextNaN, scale: scale, flags: flags)
        }
        else if dbl.isInfinite {
            formatString(to: &out, argument: TextInfinity, scale: scale, flags: flags)
        }
        else {
            let x = dbl.roundTo(places: prec)
            let m = x.magnitude
            if m >= 0.0001 && m < (10.0 ** prec) { formatFloatingPoint(to: &out, argument: dbl, scale: scale, prec: prec, flags: flags) }
            else { formatScientific(to: &out, argument: dbl, scale: scale, prec: prec, flags: flags) }
        }
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
    private func formatScientific(to out: inout String, argument arg: Any, scale: Int, prec: Int, flags: FlagSet) {
        let f = NumberFormatter()
        f.numberStyle = .scientific
        f.exponentSymbol = (flags.isUppercase ? "E" : "e")
        f.minimumIntegerDigits = 1
        f.maximumIntegerDigits = 1
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 12
        f.usesGroupingSeparator = flags.useSeparators
        f.positivePrefix = (flags.alwaysShowPlusSign ? "+" : (flags.useSpaceForPlusSign ? " " : ""))

        if flags.useParensForMinusSign {
            f.negativePrefix = "("
            f.negativeSuffix = ")"
        }

        if scale > 1 {
            f.formatWidth = scale
            if flags.isZeroPadded {
                f.paddingPosition = .afterPrefix
                f.paddingCharacter = "0"
            }
            else {
                f.paddingPosition = (flags.isLeftJustified ? .afterSuffix : .beforePrefix)
                f.paddingCharacter = " "
            }
        }

        if prec > 1 {
            f.minimumFractionDigits = prec
            f.maximumFractionDigits = prec
        }

        formatFloatingPoint(to: &out, formatter: f, argument: arg)
    }

    /*==========================================================================================================*/
    /// Format the argument as a character. If the argument is a string, or a type that can be converted to a
    /// string, that has more than one character, then only the first character is displayed.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale (width).
    ///   - flags: The formatting flags.
    ///
    private func formatCharacter(to out: inout String, argument arg: Any, scale: Int, flags: FlagSet) {
        let s = String(describing: arg)
        if !s.isEmpty {
            let c = s[s.startIndex]
            formatString(to: &out, argument: c, scale: scale, flags: flags)
        }
    }

    /*==========================================================================================================*/
    /// Format the argument as a boolean value. A boolean value displays as "`true`" or "`false`". If the argument
    /// is `nil` then it is taken to be "`false`". Non-boolean arguments are converted into strings and if the
    /// string is equal to "`true`" then it is taken as "`true`" otherwise it is taken as "`false`".
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale (width).
    ///   - flags: The formatting flags.
    ///
    private func formatBoolean(to out: inout String, argument arg: Any?, scale: Int, flags: FlagSet) {
        let bStr = String(describing: (arg ?? false))
        formatString(to: &out, argument: ((bStr == "true") ? bStr : "false"), scale: scale, flags: flags)
    }

    /*==========================================================================================================*/
    /// Format the argument as an integer in octal notation.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale (width).
    ///   - flags: The formatting flags.
    ///
    private func formatOctal(to out: inout String, argument arg: Any, scale: Int, flags: FlagSet) {
        formatRadix(to: &out, argument: arg, radix: 8, prefix: "0", scale: scale, flags: flags)
    }

    /*==========================================================================================================*/
    /// Format the argument as an integer in hexadecimal notation.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - scale: The scale (width).
    ///   - flags: The formatting flags.
    ///
    private func formatHexadecimal(to out: inout String, argument arg: Any, scale: Int, flags: FlagSet) {
        formatRadix(to: &out, argument: arg, radix: 16, prefix: "0x", scale: scale, flags: flags)
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
    private func formatRadix(to out: inout String, argument arg: Any, radix: Int, prefix: String, scale: Int, flags: FlagSet) {
        if let i = getArgAsUInt(arg) {
            var s  = String(i, radix: radix)
            var ip = s.startIndex

            if flags.isAlternate {
                s.prepend(contentsOf: prefix)
                s.formIndex(&ip, offsetBy: prefix.count)
            }

            if flags.isZeroPadded && scale > 1 && scale > s.count {
                for _ in (s.count ..< scale) {
                    s.insert("0", at: ip)
                }
            }

            formatString(to: &out, argument: s, scale: scale, flags: flags)
        }
        else {
            formatString(to: &out, argument: TextNaN, scale: scale, flags: flags)
        }
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
    private func formatInteger(to out: inout String, argument arg: Any, scale: Int, flags: FlagSet) {
        if let n = getArgAsNSNumber(arg) {
            let f = getDecimalFormatter(flags: flags, scale: scale)
            out.append(contentsOf: f.string(from: n) ?? TextNaN)
        }
        else {
            out.append(contentsOf: TextNaN)
        }
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
    private func formatFloatingPoint(to out: inout String, argument arg: Any, scale: Int, prec: Int, flags: FlagSet) {
        let f = getDecimalFormatter(flags: flags, scale: scale)
        if prec > 0 {
            f.minimumFractionDigits = prec
            f.maximumFractionDigits = prec
        }
        else {
            f.minimumFractionDigits = 1
            f.maximumFractionDigits = 6
        }
        formatFloatingPoint(to: &out, formatter: f, argument: arg)
    }

    /*==========================================================================================================*/
    /// Formats a floating point number.
    ///
    /// - Parameters:
    ///   - out: The output string.
    ///   - arg: The argument.
    ///   - f: The number formatter.
    ///
    private func formatFloatingPoint(to out: inout String, formatter f: NumberFormatter, argument arg: Any) {
        let d = getArgAsDouble(arg)
        if d.isNaN { out.append(contentsOf: TextNaN) }
        else if d.isInfinite { out.append(contentsOf: TextInfinity) }
        else { out.append(contentsOf: (f.string(from: NSNumber(value: d)) ?? TextNaN)) }
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
    private func formatString(to out: inout String, argument arg: Any, scale: Int, flags: FlagSet) {
        let s  = String(describing: arg)
        let cc = (scale - s.count)
        if cc > 0 && !flags.isLeftJustified { out.append(" ", count: cc) }
        out.append(contentsOf: flags.isUppercase ? s.uppercased() : s)
        if cc > 0 && flags.isLeftJustified { out.append(" ", count: cc) }
    }

    /*==========================================================================================================*/
    /// Attempt to get the argument as a Double value. If the argument cannot be converted into a Double value
    /// then a NaN value is returned.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The Double value. If conversion failed then the value's Double.isNaN property will return
    ///            `true`.
    ///
    private func getArgAsDouble(_ arg: Any) -> Double {
        if let d = castArgAsDouble(argument: arg) { return d }
        if let i = castArgAsInt(argument: arg) { return Double(i) }
        if let i = castArgAsUInt(argument: arg) { return Double(i) }
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
        if let i = castArgAsUInt(argument: arg) { return i }
        else if let i = castArgAsInt(argument: arg) { return UInt64(bitPattern: i) }
        else if let d = castArgAsDouble(argument: arg) { return UInt64(d + 0.5) }
        return UInt64(String(describing: arg))
    }

    /*==========================================================================================================*/
    /// Attempt to get the argument as a Double or Integer NSNumber value. If the argument cannot be converted
    /// into a NSNumber value then `nil` is returned.
    ///
    /// - Parameter arg: The argument.
    /// - Returns: The NSNumber value. If conversion failed then `nil` is returned instead.
    ///
    private func getArgAsNSNumber(_ arg: Any) -> NSNumber? {
        if let i = castArgAsUInt(argument: arg) { return NSNumber(value: i) }
        else if let i = castArgAsInt(argument: arg) { return NSNumber(value: i) }
        else if let d = castArgAsDouble(argument: arg) { return NSNumber(value: Int64(d + 0.5)) }
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
    private func castArgAsDouble(argument arg: Any) -> Double? {
        let t = type(of: arg)
        if t == Double.self { return (arg as! Double) }
        if t == Float.self { return Double(arg as! Float) }
        #if !os(Windows) && (arch(i386) || arch(x86_64))
            if t == Float80.self { return Double(arg as! Float80) }
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
    private func castArgAsUInt(argument arg: Any) -> UInt64? {
        let t = type(of: arg)
        if t == UInt.self { return numericCast(arg as! UInt) }
        if t == UInt8.self { return numericCast(arg as! UInt8) }
        if t == UInt16.self { return numericCast(arg as! UInt16) }
        if t == UInt32.self { return numericCast(arg as! UInt32) }
        if t == UInt64.self { return (arg as! UInt64) }
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
    private func castArgAsInt(argument arg: Any) -> Int64? {
        let t = type(of: arg)
        if t == Int.self { return numericCast(arg as! Int) }
        if t == Int8.self { return numericCast(arg as! Int8) }
        if t == Int16.self { return numericCast(arg as! Int16) }
        if t == Int32.self { return numericCast(arg as! Int32) }
        if t == Int64.self { return (arg as! Int64) }
        return nil
    }

    /*==========================================================================================================*/
    /// Creates the base number formatter for use by `format(_:)`. Java will throw an exception when you provide
    /// conflicting flags such as `-` and `0`. In our case we will simply choose one over the other.
    ///
    /// - Parameters:
    ///   - flags: The formatting flags.
    ///   - scale: The scale (minimum width).
    /// - Returns: The instance of
    ///            <code>[NumberFormatter](https://developer.apple.com/documentation/foundation/NumberFormatter)</code>
    ///
    private func getDecimalFormatter(flags: FlagSet, scale: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        if scale > 1 {
            if flags.isZeroPadded {
                f.formatWidth = scale
                f.paddingPosition = .afterPrefix
                f.paddingCharacter = "0"
            }
            else {
                f.formatWidth = scale
                f.paddingPosition = (flags.isLeftJustified ? .afterSuffix : .beforePrefix)
            }
        }
        f.usesGroupingSeparator = flags.useSeparators
        f.positivePrefix = (flags.alwaysShowPlusSign ? "+" : (flags.useSpaceForPlusSign ? " " : ""))
        if flags.useParensForMinusSign {
            f.negativePrefix = "("
            f.negativeSuffix = ")"
        }
        return f
    }

    /*==========================================================================================================*/
    /// Get the argument to format. If the argument specifier was provided it will tell us which one to use.
    /// Instead of throwing an exception like Java does for invalid or missing arguments we will simply return
    /// `nil`.
    ///
    /// - Parameters:
    ///   - argp: The argument specifier in the form of either `&lt;` or `n$` where `n` is the ordinal number,
    ///           starting with `1`.
    ///   - aIdx: The current <code>[zero](https://en.wikipedia.org/wiki/0)</code>-based index of the next
    ///           argument to get if no argument specifier is given.
    ///   - args: The arguments.
    /// - Returns: The argument or `nil` if an invalid specifier was given or there is no next argument.
    ///
    private func getFormatArgument(argumentSpec argp: String?, argumentIndex aIdx: inout Int, arguments args: [Any?]) -> Any? {
        guard let p = argp else {
            return getFormatArgument(errorMessage: "Not enough arguments.", argumentIndex: aIdx++, arguments: args)
        }
        guard p == "<" else {
            return getFormatArgument(errorMessage: "Argument index out of bounds.", argumentIndex: ((p.withLastCharsRemoved(1).toInteger() - 1) - args.startIndex), arguments: args)
        }
        return getFormatArgument(errorMessage: "No previous argument.", argumentIndex: (aIdx - 1), arguments: args)
    }

    /// Get the argument to format.
    ///
    /// - Parameters:
    ///   - msg: The error message to display if `StringFormatIsString` is true and the argument doesn't exist.
    ///   - idx: The index of the argument - zero based.
    ///   - args: The arguments.
    /// - Returns: The argument or nil if `StringFormatIsString` is false and the argument doesn't exist.
    ///
    private func getFormatArgument(errorMessage msg: String, argumentIndex idx: Int, arguments args: [Any?]) -> Any? {
        if idx >= args.startIndex && idx < args.endIndex { return args[idx] }
        if StringFormatIsStrict { fatalError("\(ErrorMessagePrefix): \(msg)") }
        return nil
    }
}

/// A class for holding formatting flags.
///
fileprivate class FlagSet {
    /// An enumeration of the possible flags.
    ///
    enum FormatFlags { case Space, Zeros, Sign, Parenthesis, Justified, Separators, Uppercase, Alternate }

    /// A set of the current active flags.
    ///
    private(set) lazy var flags: Set<FormatFlags> = getSet()

    let useSpaceForPlusSign:   Bool
    let isZeroPadded:          Bool
    let useParensForMinusSign: Bool
    let alwaysShowPlusSign:    Bool
    let isLeftJustified:       Bool
    let useSeparators:         Bool
    let isUppercase:           Bool
    let isAlternate:           Bool

    init(_ str: String?, convSpec: inout String) {
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

    init(set: FlagSet, without flags: FormatFlags...) {
        self.useSpaceForPlusSign = (set.useSpaceForPlusSign && !flags.contains(.Space))
        self.isZeroPadded = (set.isZeroPadded && !flags.contains(.Zeros))
        self.useParensForMinusSign = (set.useParensForMinusSign && !flags.contains(.Parenthesis))
        self.alwaysShowPlusSign = (set.alwaysShowPlusSign && !flags.contains(.Sign))
        self.isLeftJustified = (set.isLeftJustified && !flags.contains(.Justified))
        self.useSeparators = (set.useSeparators && !flags.contains(.Separators))
        self.isUppercase = (set.isUppercase && !flags.contains(.Uppercase))
        self.isAlternate = (set.isAlternate && !flags.contains(.Alternate))
    }

    private func getSet() -> Set<FormatFlags> {
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
    }
}

@usableFromInline let DateNumberFormatter: NumberFormatter = CreateDateNumberFormatter()

@inlinable func CreateDateNumberFormatter() -> NumberFormatter {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 0
    f.usesGroupingSeparator = false
    f.paddingPosition = .beforePrefix
    f.paddingCharacter = "0"
    f.formatWidth = 2
    return f
}

@inlinable func FmtDt(_ value: Int, places: Int) -> String {
    DateNumberFormatter.formatWidth = places
    return DateNumberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
