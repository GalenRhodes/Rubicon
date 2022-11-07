// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: IConv.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 05, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation
import iconv
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

open class IConv {

    internal var iconvHandle: iconv_t

    public let inputEncoding:  String
    public let outputEncoding: String

    public init(to outputEncoding: String = "UTF-8", from inputEncoding: String) throws {
        self.inputEncoding = inputEncoding
        self.outputEncoding = outputEncoding
        self.iconvHandle = iconv_open(outputEncoding, inputEncoding)

        if self.iconvHandle == (iconv_t)(bitPattern: -1) {
            switch errno {
                case EMFILE: throw IConvError.NoAvailableFileDescriptors
                case ENFILE: throw IConvError.TooManyFilesOpen
                case ENOMEM: throw IConvError.InsufficientMemory
                case EINVAL: throw IConvError.UnknownCharacterEncoding
                default:     throw IConvError.UnknownError(code: errno)
            }
        }
    }

    public class func getEncodingList() throws -> [String] {
        let (_, stdOut, _) = try Process.execute(executableURL: URL(fileURLWithPath: "/usr/bin/iconv"), arguments: [ "-l" ], inputString: nil)
        if let str = stdOut {
            #if os(Linux)
                return str.split(pattern: "//\\s+").sorted()
            #elseif os(iOS) || os(macOS) || os(OSX) || os(tvOS) || os(watchOS)
                return str.split(pattern: "\\s+").sorted()
            #endif
        }
        return []
    }

    private static func splitListString(_ regex: RegularExpression, _ str: String, _ list: inout [String]) {
        let matches:   [RegularExpression.Match] = regex.matches(in: str)
        var lastIndex: String.Index              = str.startIndex

        for match in matches {
            list.append(String(str[lastIndex ..< match.range.lowerBound]))
            lastIndex = match.range.upperBound
        }
    }
}
