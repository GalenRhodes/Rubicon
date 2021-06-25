/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/20/21
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

import XCTest
@testable import Rubicon

let testFilesDir: String = "Tests/RubiconTests/Files"
let testFile:     String = "\(testFilesDir)/Test_UTF-8.xml"

public class RubiconTests: XCTestCase {

    func testGetFileList() throws {
        do {
            let list = try FileManager.default.directoryFiles(atPath: "\(FileManager.default.currentDirectoryPath)", resolveSymLinks: true, traverseDirectorySymLinks: false) { p, f, a in
                (a.fileType == .typeRegular) && f.hasSuffix(".swift")
            }

            for f in list {
                print(f)
            }
        }
        catch let e {
            XCTFail("ERROR: \(e)")
        }
    }

    func testResolve() throws {
        print(try FileManager.default.realPath(path: "alink/idea"))
    }

    func testTextPosition() throws {
        guard let byteInputStream = InputStream(fileAtPath: testFile) else { throw StreamError.FileNotFound(description: testFile) }
        let inputStream = IConvCharInputStream(inputStream: byteInputStream, encodingName: "UTF-8", autoClose: true)
        inputStream.open()
        var buffer: [Character] = []
        inputStream.markSet()
        _ = try inputStream.read(chars: &buffer, maxLength: 58)
        var str = String(buffer)
        print(str)
        nDebug(.None, "Characters read: \(str.count); Text Position: (\(inputStream.position.lineNumber), \(inputStream.position.columnNumber))")
        nDebug(.None, "Backing up 10 characters...")
        inputStream.markBackup(count: 10)
        nDebug(.None, "                     Text Position: (\(inputStream.position.lineNumber), \(inputStream.position.columnNumber))")
        nDebug(.None, "Re-reading 10 characters...")
        _ = try inputStream.read(chars: &buffer, maxLength: 10)
        str = String(buffer)
        print(str)
        nDebug(.None, "Characters read: \(str.count); Text Position: (\(inputStream.position.lineNumber), \(inputStream.position.columnNumber))")
    }

    public override func setUp() {}

    public override func tearDown() {}

    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (RubiconTests) -> () throws -> Void)] {
            [ ("RubiconTests", testTextPosition), ]
        }
    #endif
}
