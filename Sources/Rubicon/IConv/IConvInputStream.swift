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

/*==========================================================================================================================================================*/
@usableFromInline class IConvInputStreamThread: Thread {

    enum State { case Run, Skip, End }

    /*@f:0*/
    private           let inputStream:    InputStream
    private           let inputEncoding:  String
    private           let outputEncoding: String
    private           let options:        IConv.Options
    private           let outBuffer:      SwRingBuffer = SwRingBuffer(initialSize: MaxReadAheadLimit)
    private           var allDone:        Bool         = false
    private           var error:          Error?       = nil
    @usableFromInline let lock:           NSCondition  = NSCondition()

    @usableFromInline override var isFinished:  Bool { lock.withLock { pIsFinished  } }
    @usableFromInline override var isCancelled: Bool { lock.withLock { super.isCancelled } }
    @usableFromInline override var isExecuting: Bool { lock.withLock { pIsExecuting } }

    private var pIsFinished:  Bool { (allDone || super.isFinished)   }
    private var pIsExecuting: Bool { (super.isExecuting && !allDone) }
    /*@f:1*/

    init(_ inputStream: InputStream, _ outputEncoding: String, _ inputEncoding: String, _ options: IConv.Options) throws {
        self.inputStream = inputStream
        self.outputEncoding = outputEncoding
        self.inputEncoding = inputEncoding
        self.options = options
        super.init()
    }

    deinit {
        print("DEBUG: deinit called. Deallocating buffer.")
        cancel()
    }

    override func main() {
        lock.withLock {
            defer { allDone = true }
            do {
                let iconv:       IConv                       = try IConv(to: outputEncoding, from: inputEncoding, options: options)
                let readBuffer:  UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: ReadBufferSize)
                let iconvBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: IConvBufferSize)
                var offset:      Int                         = 0

                defer {
                    readBuffer.deallocate()
                    iconvBuffer.deallocate()
                }

                while !super.isCancelled {
                    guard foo1 else { break }
                    let (st, ic, oc, sz) = foo2(iconv, readBuffer, iconvBuffer, offset)
                    guard sz > 0 else { break }

                    if oc > 0 {
                        outBuffer.append(data: iconvBuffer, length: oc)
                        lock.broadcast()
                    }

                    switch st {
                        case .Error(let e): throw e
                        default:
                            let x = sz - ic
                            if x > 0 { memcpy(readBuffer, (readBuffer + ic), x) }
                            offset = x
                    }
                }
            }
            catch let e {
                error = e
            }
        }
    }

    private var foo1: Bool {
        lock.wait(while: ((outBuffer.count > ReadMoreThreshold) && !super.isCancelled))
        return !super.isCancelled
    }

    private func foo2(_ iconv: IConv, _ readBuffer: UnsafeMutablePointer<UInt8>, _ iconvBuffer: UnsafeMutablePointer<UInt8>, _ lastIn: Int) -> (IConv.Status, Int, Int, Int) {
        let cc = inputStream.read(readBuffer + lastIn, maxLength: ReadBufferSize - lastIn)
        guard cc > 0 else { return (IConv.Status.Complete, 0, 0, 0) }
        let sz           = (lastIn + cc)
        let (st, ic, oc) = iconv.convert(input: readBuffer, inputSize: sz, output: iconvBuffer, outputSize: IConvBufferSize)
        return (st, ic, oc, sz)
    }

    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        lock.withLock {
            var cc = 0

            while cc < len {
                lock.wait(while: outBuffer.isEmpty && !allDone)
                if allDone { return cc }
                cc += outBuffer.getNext(into: buffer + cc, maxLength: len - cc)
                lock.broadcast()
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
        lock.withLock(if: !allDone) {
            super.cancel()
            lock.wait(while: !allDone)
        }
    }
}
