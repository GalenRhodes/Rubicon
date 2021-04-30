/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: ByteInputStreamTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/18/20
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

class ByteInputStreamTests: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    func testOpenAndFirstRead() {
        do {
            if let stream = MarkInputStream(fileAtPath: "Tests/RubiconTests/Files/Test_UTF-8.xml") {
                let bufSize = 200
                let buffer = BytePointer.allocate(capacity: bufSize + 1)
                buffer.initialize(repeating: 0, count: bufSize + 1)
                defer {
                    stream.close()
                    buffer.deinitialize(count: bufSize + 1)
                    buffer.deallocate()
                }
                stream.open()
                print("Stream Status: \(stream.streamStatus)")

                stream.markSet()
                print("Mark Set")
                try doRead(stream: stream, buffer: buffer, maxLength: 55)

                stream.markSet()
                print("Mark Set")
                try doRead(stream: stream, buffer: buffer, maxLength: 100)

                stream.markReturn()
                print("Mark Release")
                try doRead(stream: stream, buffer: buffer, maxLength: 100)

                stream.markReturn()
                print("Mark Release")
                try doRead(stream: stream, buffer: buffer, maxLength: 155)
            }
            else {
                throw CErrors.NOENT()
            }
        }
        catch let e {
            XCTFail("ERROR: \(e.localizedDescription)")
        }
    }

    private func doRead(stream: MarkInputStream, buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) throws {
//        let result = try stream.read(to: buffer, maxLength: len)
//
//        print("Read Result: \(result)")
//        print("Stream Status: \(stream.streamStatus)")
//
//        if result < 0, let e = stream.streamError {
//            throw e
//        }
//
//        buffer[result] = 0
//        let str = String(cString: buffer)
//        print("Data: \"\(str)\"")
    }
}
