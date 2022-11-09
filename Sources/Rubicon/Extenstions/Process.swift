// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Process.swift
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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

extension Process {

    public class func execute(executableURL url: URL, arguments args: [String], inputString: String?, encoding: String.Encoding = .utf8) throws -> (Int32, String?, String?) {
        let (code, outData, errData) = try execute(executableURL: url, arguments: args, inputData: inputString?.data(using: encoding))
        return (code, outData.asString(encoding: encoding), errData.asString(encoding: encoding))
    }

    public class func execute(executableURL url: URL, arguments args: [String], inputData: Data?) throws -> (Int32, Data, Data) {
        let outThread: ProcessReadThread   = ProcessReadThread()
        let errThread: ProcessReadThread   = ProcessReadThread()
        let innThread: ProcessWriteThread? = (inputData == nil) ? nil : ProcessWriteThread(inputData!)
        let proc:      Process             = Process()

        proc.arguments = args
        proc.executableURL = url
        proc.standardOutput = outThread.pipe
        proc.standardError = errThread.pipe
        if innThread != nil { proc.standardInput = innThread!.pipe }

        try proc.run()
        outThread.start()
        errThread.start()
        innThread?.start()
        proc.waitUntilExit()
        innThread?.join()
        errThread.join()
        outThread.join()

        return (proc.terminationStatus, outThread.data, errThread.data)
    }
}

fileprivate class ProcessWriteThread: JoinableThread {
    let pipe: Pipe = Pipe()
    let data: Data

    init(_ data: Data) {
        self.data = data
        super.init()
    }

    override func main() { pipe.fileHandleForWriting.write(self.data) }
}

fileprivate class ProcessReadThread: JoinableThread {
    let pipe: Pipe = Pipe()
    var data: Data = Data()

    init() { super.init() }

    override func main() {
        while let d = try? pipe.fileHandleForReading.read(upToCount: 8192) {
            guard d.count > 0 else { break }
            data.append(d)
        }
    }
}
