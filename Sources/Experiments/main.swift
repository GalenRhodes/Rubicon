/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon/Experiments
 *    FILENAME: main.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/4/21
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

let testDataDir: String = "Tests/RubiconTests/Files"

guard let inputStream = InputStream(fileAtPath: "\(testDataDir)/Test_UTF-8.xml") else {
    print("Unable to create input stream!")
    exit(1)
}
inputStream.open()
if let e = inputStream.streamError {
    print("File not opened: \(e.localizedDescription)")
    exit(1)
}
var array  = [ UInt8 ](repeating: 0, count: 100)
let result = inputStream.read(&array, maxLength: 100)
guard result >= 0 else {
    let msg = (inputStream.streamError?.localizedDescription ?? "Unknown Error")
    print("Error reading file: \(msg)")
    exit(1)
}
let str = String(bytes: array, encoding: .utf8)
print(str ?? "???")
inputStream.close()

