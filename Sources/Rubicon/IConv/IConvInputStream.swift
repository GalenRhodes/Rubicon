// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: IConvInputStream.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 09, 2022
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

public let MaxReadAheadLimit: Int = 65536
public let ReadMoreThreshold: Int = (65536 - 2048)
public let ReadBufferSize:    Int = 4096
public let IConvBufferSize:   Int = ((ReadBufferSize + 2) * 4)

public class IConvInputStream: InputStream {

    @usableFromInline let thread: IConvInputStreamThread
    /*@f:0*/
    public override var hasBytesAvailable: Bool            { super.hasBytesAvailable                                  }
    public override var delegate:          StreamDelegate? { get { super.delegate } set { super.delegate = newValue } }
    public override var streamStatus:      Status          { super.streamStatus                                       }
    public override var streamError:       Error?          { super.streamError                                        }
    /*@f:1*/

    public init(inputStream: InputStream, to outputEncoding: String = "UTF-8", from inputEncoding: String, options: IConv.Options = .None) throws {
        thread = try IConvInputStreamThread(inputStream, outputEncoding, inputEncoding, options)
        super.init(data: Data())
    }

    deinit {
        print("DEBUG: deinit called. Closing stream.")
        close()
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        thread.read(buffer, maxLength: len)
    }

    public override func open() {
    }

    public override func close() {
    }
}

@usableFromInline class IConvInputStreamThread: Thread {

    enum State { case Run, Skip, End }/*@f:0*/

    private           let inputStream: InputStream
    private           let iconv:       IConv
    private           let readBuffer:  UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: ReadBufferSize)
    private           let iconvBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: IConvBufferSize)
    private           let outBuffer:   SwRingBuffer                = SwRingBuffer(initialSize: MaxReadAheadLimit)
    private           var allDone:     Bool                        = false
    @usableFromInline let lock:        NSCondition                 = NSCondition()

    @usableFromInline override var isFinished:  Bool { (allDone || super.isFinished) }
    /*@f:1*/
    init(_ inputStream: InputStream, _ outputEncoding: String, _ inputEncoding: String, _ options: IConv.Options) throws {
        self.inputStream = inputStream
        self.iconv = try IConv(to: outputEncoding, from: inputEncoding, options: options)
        super.init()
    }

    deinit {
        print("DEBUG: deinit called. Deallocating buffer.")
        lock.withLock {
            if !allDone {
                super.cancel()
                while !allDone { lock.wait() }
            }
            readBuffer.deallocate()
            iconvBuffer.deallocate()
        }
    }

    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        lock.withLock {
            var cc = 0
            while cc < len {
                while outBuffer.isEmpty && !allDone { lock.wait() }
                guard !allDone else { break }
                cc += outBuffer.getNext(into: buffer + cc, maxLength: len - cc)
            }
            return cc
        }
    }

    override func start() {
        lock.withLock {
            self.qualityOfService = .background
            super.start()
        }
    }

    override func cancel() {
        lock.withLock {
            super.cancel()
            while !allDone { lock.wait() }
        }
    }

    override func main() {
        lock.withLock {
            defer { allDone = true }
            while !isCancelled {
            }
        }
    }
}
