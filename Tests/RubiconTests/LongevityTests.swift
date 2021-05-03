/*=============================================================================================================================================================================*//*
 *     PROJECT: Rubicon
 *    FILENAME: LongevityTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/28/21
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

class LongevityTests: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    func testStreamLongevity() {
        let filename = "Tests/RubiconTests/Files/Test_UTF-8.xml"

        if let stream = MarkInputStream(fileAtPath: filename) {
            stream.open()
            doSleep(seconds: 2)
            nDebug(.None, "TEST> stream retain count - \(PGGetRetainCount(stream))")
            nDebug(.None, "TEST> stream is about to go out of scope.")
        }
        else {
            nDebug(.None, "TEST> Unable to open \"\(filename)\"")
            XCTFail()
        }

        nDebug(.None, "TEST> stream is now out of scope.")
        doSleep(seconds: 20)
    }

    func testCharStreamLongevity() {
        do {
            let stream: IConvCharInputStream = try IConvCharInputStream(filename: "Tests/RubiconTests/Files/Test_UTF-8.xml", encodingName: "UTF-8")
            stream.open()
            doSleep(seconds: 2)
            nDebug(.None, "TEST> stream retain count - \(PGGetRetainCount(stream))")
            nDebug(.None, "TEST> stream is about to go out of scope.")
        }
        catch let e {
            nDebug(.None, "TEST> ERROR> \(e)")
            XCTFail()
        }

        nDebug(.None, "TEST> stream is now out of scope.")
        doSleep(seconds: 20)
    }

    private func doSleep(seconds: UInt32) {
        nDebug(.In, "TEST> Sleeping \(seconds) seconds...")
        sleep(seconds)
        nDebug(.Out, "TEST> Finished sleeping \(seconds) seconds...")
    }
}
