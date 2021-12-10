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

private var nestLevel: Int       = 0
private let nestLock:  MutexLock = MutexLock()

/*==============================================================================================================*/
/// Enum used with `nDebug(_:_:separator:)`
///
public enum NestType { case None, In, Out }

private func nDebugIndent(_ count: Int, _ string: inout String, _ msg: String) {
    for _ in (0 ..< count) { string.append("    ") }
    string.append(msg)
}

/*==============================================================================================================*/
/// Output debugging text. This method only produces output when the code is compiled with a `-DDEBUG` flag. This
/// method outputs text in a nested fashion. Calling this method with NestType.In increases the nesting level.
/// Calling this method with NestType.Out decreases the nesting level. Calling this method with NestType.None
/// keeps the nesting level the same.
///
/// - Parameters:
///   - nestType: The nesting type.
///   - obj: The objects to print. They are converted to a string with `String(describing:)`.
///   - separator: The string to put between objects. Defaults to a single space character.
///
public func nDebug(_ nestType: NestType = .None, _ obj: Any..., separator: String = " ") {
    #if DEBUG
        nestLock.withLock {
            var str: String = ""
            if obj.isEmpty {
                switch nestType {
                    case .None: break
                    case .In:   nestLevel++
                    case .Out:  if nestLevel > 0 { nestLevel-- }
                }
            }
            else {
                switch nestType {
                    case .None: nDebugIndent(nestLevel, &str, "  | ")
                    case .In:   nDebugIndent(nestLevel++, &str, ">>> ")
                    case .Out:  nDebugIndent(nestLevel > 0 ? --nestLevel : nestLevel, &str, "<<< ")
                }

                str.append("\(obj[obj.startIndex])")
                for i in (obj.index(after: obj.startIndex) ..< obj.endIndex) { str.append("\(separator)\(obj[i])") }
            }
            print(str)
        }
    #endif
}

/*==============================================================================================================*/
/// Returns a <code>[String](https://developer.apple.com/documentation/swift/string/)</code> that represents the
/// given integer in hexadecimal format.
///
/// - Parameters:
///   - n: The integer number.
///   - pad: 0 means no padding. negative number means the number is padded with spaces to that many places.
///          Positive number means the number is padded with zeros to that many places.
/// - Returns: The <code>[String](https://developer.apple.com/documentation/swift/string/)</code>
///
public func toHex<T: BinaryInteger>(_ n: T, pad: Int = 0) -> String {
    var str: String   = ""
    var spd: String   = ""
    var n:   T        = n
    let w:   Int      = n.bitWidth
    let bw:  Int      = ((pad == 0) ? w : max(w, abs(pad)))
    let pc:  String   = ((pad < 0) ? " " : "0")
    let hx:  [String] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ]

    for i: Int in stride(from: 0, to: bw, by: 4) {
        if i < w {
            str = "\(hx[Int(n & 0x0f)])\(str)"
            n = (n >> 4)
        }
        else {
            spd = "\(pc)\(spd)"
        }
    }

    return "\(spd)0x\(str)"
}

/*==============================================================================================================*/
/// Simple function to convert an integer number into a string represented as a series of ones - "1" - or zeros -
/// "0" starting with the high bits first and the low bits to the right.
///
/// - Parameters:
///   - n: The integer number.
///   - sep: The string will be grouped into octets separated by a space unless you provide a separator string in
///          this field.
///   - pad: The number of places to left pad the string with zeros.
/// - Returns: The string.
///
public func toBinary<T: BinaryInteger>(_ n: T, sep: String? = nil, pad: Int = 0) -> String {
    var str: String = ""
    var n:   T      = n
    let w:   Int    = n.bitWidth
    let bw:  Int    = ((pad == 0) ? w : max(w, abs(pad)))
    let pc0: String = ((sep == nil) ? "" : sep!)
    let pc1: String = ((pad < 0) ? " " : "0")
    let pc2: String = ((sep == nil) ? pc1 : ((pad < 0) ? "  " : "0\(sep!)"))

    for i: Int in (0 ..< bw) {
        if i < w {
            str = "\(n & 1)\((i > 0 && (i % 4) == 0) ? pc0 : "")\(str)"
            n = (n >> 1)
        }
        else {
            str = "\((i > 0 && (i % 4) == 0) ? pc2 : pc1)\(str)"
        }
    }

    return str
}

/*==============================================================================================================*/
/// Output debugging text. This method only produces output when the code is compiled with a `-DDEBUG` flag.
///
/// - Parameters:
///   - obj: The objects to print. They are converted to string with `String(describing:)`.
///   - separator: The string to put between objects. Defaults to a single space character.
///   - terminator: The string to put at the end of all the objects. Defaults to a single line-feed (`\n`)
///                 character.
///
@inlinable public func debug(_ obj: Any..., separator: String = " ", terminator: String? = nil) {
    let _obj: [Any] = obj.map { $0 }
    debug(_obj, separator: separator, terminator: terminator)
}

/*==============================================================================================================*/
/// Output debugging text. This method only produces output when the code is compiled with a `-DDEBUG` flag.
///
/// - Parameters:
///   - obj: The objects to print. They are converted to string with `String(describing:)`.
///   - separator: The string to put between objects. Defaults to a single space character.
///   - terminator: The string to put at the end of all the objects. Defaults to a single, platform dependent
///                 new-line character.
///
@inlinable public func debug(_ obj: [Any], separator: String = " ", terminator: String? = nil) {
    #if DEBUG
        #if os(Windows)
            let term: String = (terminator ?? "\r\n")
        #else
            let term: String = (terminator ?? "\n")
        #endif
        if !obj.isEmpty {
            print(obj[obj.startIndex], terminator: "")
            for i in (obj.index(after: obj.startIndex) ..< obj.endIndex) {
                print(separator, terminator: "")
                print("\(obj[i])", terminator: "")
            }
        }
        print("", terminator: term)
    #endif
}

@inlinable public func debugQuote<S>(_ str: S?, _ q: Character = "\"") -> String where S: StringProtocol {
    guard let s = str else { return "nil" }
    return "\(q)\(s)\(q)"
}
