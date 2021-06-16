/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: IConvTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/3/20
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

import XCTest
import Foundation
import CoreFoundation
@testable import Rubicon

public class IConvTests: XCTestCase {

    let testDataDir: String = "Tests/RubiconTests/Files"
    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (IConvTests) -> () throws -> Void)] {
            [ ("testIConvCharInputStream_UTF_8", testIConvCharInputStream_UTF_8), ("testIConvList", testIConvList), ]
        }
    #endif

    public override func setUp() {}

    public override func tearDown() {}

    func testIConvCharInputStream_UTF_8() {
        do {
            let fileName: String = "\(testDataDir)/Test_UTF-8.xml"
            guard let file = InputStream(fileAtPath: fileName) else { XCTFail("Cannot open file: \"\(fileName)\""); return }
            let iconv = IConvCharInputStream(inputStream: file, encodingName: "UTF-8", autoClose: true)

            iconv.open()
            defer { iconv.close() }

            var chars: [Character] = []
            iconv.markSet()
            if try iconv.read(chars: &chars, maxLength: 10) > 0 {
                print("Marked Text: \"\(makeString(chars: &chars))\"")

                iconv.markSet()
                if try iconv.read(chars: &chars, maxLength: 10) > 0 {
                    print("More Marked Text: \"\(makeString(chars: &chars))\"")
                }
                iconv.markReturn()
            }
            iconv.markReturn()

            while try iconv.read(chars: &chars, maxLength: 1000) > 0 {
                print("\(makeString(chars: &chars))", terminator: "")
            }
            print("")
        }
        catch let e {
            XCTFail("ERROR: \(e)")
        }
    }

    func testIConvList() {
        let list: [String] = IConv.encodingsList
        for i in (0 ..< list.count) {
            print("\(i + 1)> \"\(list[i])\"")
        }
    }

    private func makeString(chars: inout [Character]) -> String {
        let str = String(chars)
        chars.removeAll(keepingCapacity: true)
        return str
    }
}
