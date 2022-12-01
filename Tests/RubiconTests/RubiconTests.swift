// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: RubiconTests.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: July 09, 2022
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

import XCTest
@testable import Rubicon

let testFilesDir: String = "Tests/RubiconTests/Files"
let testFile:     String = "\(testFilesDir)/Test_UTF-8.xml"

public class RubiconTests: XCTestCase {

    public override func setUp() {}

    public override func tearDown() {}

    public func testWhich() {
        do {
            try whichExample(exe: "iconv")
            try whichExample(exe: "iconvss")
        }
        catch let error {
            print(error)
        }
    }

    private func whichExample(exe: String) throws {
        if let path = try ProcessInfo.osWhich(executable: exe) { print("\"\(exe)\" is located at \"\(path)\"") }
        else { print("\"\(exe)\" was not found!") }
    }

    public func testIConvList() {
        do {
            let list: [String] = try IConv.getEncodingList()

            for s in list {
                print(s)
            }
        }
        catch let error {
            print(error)
        }
    }

    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (RubiconTests) -> () throws -> Void)] {
            [ ("RubiconTests", testIConvList), ]
        }
    #endif
}
