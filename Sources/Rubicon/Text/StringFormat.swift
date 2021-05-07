/*=============================================================================================================================================================================*//*
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

private let fmtArgSpec:    String = "([1-9][0-9]*\\$|\\<)?"
private let fmtFlags:      String = "([ 0(+,-]*)"
private let fmtSize:       String = "(?:([1-9][0-9]*)(?:\\.([1-9][0-9]*))?)?"
private let fmtTime:       String = "[aAbBcCdDeFhHIjklLmMNpQrRsSTyYzZ]"
private let fmtConvSpec:   String = "([bBhHsScCdoxeEfgGaA]|[tT]\(fmtTime))"
private let FormatPattern: String = "\\%(\\%|[nNrR]|(?:\(fmtArgSpec)\(fmtFlags)\(fmtSize)\(fmtConvSpec)))"

private enum FormatFlags {
    case Space, Zeros, Sign, Parenthesis, Justified, Separators

    static func flagsFor(_ str: String?) -> Set<FormatFlags> {
        var set = Set<FormatFlags>()
        if let str = str {
            for ch in str {
                switch ch {
                    case " ": set.insert(.Space)
                    case "0": set.insert(.Zeros)
                    case "(": set.insert(.Parenthesis)
                    case "+": set.insert(.Sign)
                    case "-": set.insert(.Justified)
                    case ",": set.insert(.Separators)
                    default:   break
                }
            }
        }
        return set
    }
}

extension StringProtocol {
    /// Allows creating a string using printf like formatting strings and arguments. However this version is modeled more after the Java version than the C version in order to make it a little
    /// easier to use.
    ///
    ///
    /// - Parameter args:
    /// - Returns:
    public func format(_ args: Any?...) -> String {
        var out: String       = ""
        var idx: String.Index = startIndex
        var aIdx              = args.startIndex

        guard let regex = RegularExpression(pattern: FormatPattern) else { fatalError("Invalid Regular Expression Pattern") }

        regex.forEachMatch(in: String(self)) { match, _, stop in
            if let match = match {
                idx = format01(&out, idx ..< match.range.lowerBound)
                let char = (match[1].subString?.first ?? "%")

                if char == "%" {
                    out.append("%")
                    idx = match.range.upperBound
                }
                else if value(char, isOneOf: "n", "N", "r", "R") {
                    switch char {
                        case "n":      out.append("\n")
                        case "N", "R": out.append("\r\n")
                        default:       out.append("\r")
                    }
                    idx = match.range.upperBound
                }
                else if let fmtSpec = match.groups[6].subString {
                    let argSpec = match.groups[2].subString
                    let arg     = getFormatArgument(argumentSpec: argSpec, argumentIndex: &aIdx, arguments: args)

                    let flags = FormatFlags.flagsFor(match.groups[3].subString)
                    let scale = (match.groups[4].subString?.toInteger() ?? 0)
                    let prec  = (match.groups[5].subString?.toInteger() ?? 0)

                    switch fmtSpec {
                        case "d":
                            out.append(contentsOf: formatInteger(argument: arg, scale: scale, flags: flags))
                        case "s", "S":
                            let s = String(describing: arg)
                            let c = s.count
                            if scale > c && !flags.contains(.Justified) { for _ in (0 ..< (scale - c)) { out.append(" ") } }
                            out.append(contentsOf: s)
                            if scale > c && flags.contains(.Justified) { for _ in (0 ..< (scale - c)) { out.append(" ") } }
                        default:
                            // Here we handle the date/time formatting.
                            break
                    }
                    idx = match.range.upperBound
                }
                else {
                    idx = format01(&out, idx ..< match.range.upperBound)
                }
            }
        }

        format01(&out, idx ..< endIndex)
        return out
    }

    private func castArgAsInt(argument objv: Any) -> Int64? {
        let t = type(of: objv)
        if t == Int8.self { return numericCast(objv as! Int8) }
        if t == Int16.self { return numericCast(objv as! Int16) }
        if t == Int32.self { return numericCast(objv as! Int32) }
        if t == Int64.self { return (objv as! Int64) }
        if t == Int.self { return numericCast(objv as! Int) }
        return nil
    }

    private func castArgAsUInt(argument objv: Any) -> UInt64? {
        let t = type(of: objv)
        if t == UInt8.self { return numericCast(objv as! UInt8) }
        if t == UInt16.self { return numericCast(objv as! UInt16) }
        if t == UInt32.self { return numericCast(objv as! UInt32) }
        if t == UInt64.self { return (objv as! UInt64) }
        if t == UInt.self { return numericCast(objv as! UInt) }
        return nil
    }

    private func castArgAsDouble(argument objv: Any) -> Double? {
        let t = type(of: objv)
        if t == Double.self { return (objv as! Double) }
        if t == Float.self { return Double(objv as! Float) }
        if t == Float80.self { return Double(objv as! Float80) }
        return nil
    }

    private func formatInteger(argument objv: Any?, scale: Int, flags: Set<FormatFlags>) -> String {
        let f = getDecimalFormatter(flags: flags, scale: scale)
        if let o = objv {
            if let i = castArgAsInt(argument: o) { return f.string(from: NSNumber(value: i)) ?? "\(i)" }
            if let i = castArgAsUInt(argument: o) { return f.string(from: NSNumber(value: i)) ?? "\(i)" }
            if let d = castArgAsDouble(argument: o) { return f.string(from: NSNumber(value: Int(d))) ?? "\(Int(d))" }
            if let i = Int(String(describing: objv)) { return f.string(from: NSNumber(value: i)) ?? "\(i)" }
        }
        return f.string(from: NSNumber(integerLiteral: 0)) ?? "0"
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
    private func getDecimalFormatter(flags: Set<FormatFlags>, scale: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        if scale > 1 {
            if flags.contains(.Zeros) {
                f.formatWidth = scale
                f.paddingPosition = .afterPrefix
                f.paddingCharacter = "0"
            }
            else {
                f.formatWidth = scale
                f.paddingPosition = (flags.contains(.Justified) ? .afterSuffix : .beforePrefix)
            }
        }
        f.usesGroupingSeparator = flags.contains(.Separators)
        f.positivePrefix = (flags.contains(.Sign) ? "+" : (flags.contains(.Space) ? " " : ""))
        if flags.contains(.Parenthesis) {
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
        guard let p = argp else { return args[aIdx++] }
        guard p == "<" else {
            let idx: Int = ((p.withLastCharsRemoved(1).toInteger() - 1).clamp(args.indexRange) - args.startIndex)
            return args[idx]
        }
        return args[(aIdx - 1).clamp(minValue: 0)]
    }

    @discardableResult private func format01(_ out: inout String, _ range: Range<String.Index>) -> String.Index {
        out.append(contentsOf: self[range])
        return range.upperBound
    }
}
