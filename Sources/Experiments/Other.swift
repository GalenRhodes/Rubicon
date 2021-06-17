/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: Other.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/17/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation
import Rubicon

func testIConvCharInputStream_UTF_8() throws {
    do {
        nDebug(.In, "testIConvCharInputStream_UTF_8")
        defer {
            nDebug(.Out, "testIConvCharInputStream_UTF_8")
        }
        let fileName: String = "\(testDataDir)/Test_UTF-8.xml"
        nDebug(.None, "Opening \"\(fileName)\"")
        guard let file = InputStream(fileAtPath: fileName) else { print("Cannot open file: \"\(fileName)\""); return }
        nDebug(.None, "Opening IConvCharInputStream for \"\(fileName)\"")
        let iconv = IConvCharInputStream(inputStream: file, encodingName: "UTF-8", autoClose: true)

        iconv.open()
        defer { iconv.close() }

        nDebug(.None, "Setting Mark...")
        var chars: [Character] = []
        iconv.markSet()
//        nDebug(.None, "Reading...")
//        if try iconv.read(chars: &chars, maxLength: 10) > 0 {
//            print("Marked Text: \"\(makeString(chars: &chars))\"")
//
//            iconv.markSet()
//            if try iconv.read(chars: &chars, maxLength: 10) > 0 {
//                print("More Marked Text: \"\(makeString(chars: &chars))\"")
//            }
//            iconv.markReturn()
//        }
//
//        iconv.markReturn()

        nDebug(.None, "Reading...")
        while try iconv.read(chars: &chars, maxLength: 1000) > 0 {
            print("\(makeString(chars: &chars))", terminator: "")
        }
        print("")
    }
    catch let e {
        print("ERROR: \(e)")
    }
}

private func makeString(chars: inout [Character]) -> String {
    let str = String(chars)
    chars.removeAll(keepingCapacity: true)
    return str
}

