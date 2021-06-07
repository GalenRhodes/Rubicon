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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

DispatchQueue.main.async {
    let queue: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, attributes: .concurrent)
    let group: DispatchGroup = DispatchGroup()
    let proc:  Process       = Process()

    proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconv")
    proc.arguments = [ "-l" ]
    proc.standardError = Pipe()
    proc.standardOutput = Pipe()

    do {
        try proc.run()
    }
    catch let e {
        try? "\(e)".write(toFile: "/dev/stderr", atomically: false, encoding: String.Encoding.utf8)
    }

    var _stderr: String = ""
    var _stdout: String = ""

    queue.async(group: group) { _stderr = String(data: (proc.standardError! as! Pipe).fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? "" }
    print("================> A")
    queue.async(group: group) { _stdout = String(data: (proc.standardOutput! as! Pipe).fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? "" }
    print("================> B")
    group.wait()
    print("================> C")
    proc.waitUntilExit()
    print("================> D")
    print("stdout: \(_stdout)")
    print("stderr: \(_stderr)")
    print("Results: \(proc.terminationStatus)")
    print("================> E")
    var ts: timespec = timespec(tv_sec: 10, tv_nsec: 0)
    var tt: timespec = timespec(tv_sec: 0, tv_nsec: 0)
    let rs: Int32    = nanosleep(&ts, &tt)
    print("nanosleep results: \(rs)")
    exit(0)
}

dispatchMain()
