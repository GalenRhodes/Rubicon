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

#if !os(Windows)
    import Foundation
    import CoreFoundation
    import RingBuffer
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #endif

    /*==========================================================================================================================================================*/
    @usableFromInline let OutMaxLen:   Int = 65536
    @usableFromInline let OutThresh:   Int = ((OutMaxLen * 8) / 10)
    @usableFromInline let IcInLength:  Int = 1024
    @usableFromInline let IcOutLength: Int = ((IcInLength + 4) * 4) // For conversion of anything to UTF-32...

    public class IConvInputStream: InputStream {
/*@f:0*/
        public override var streamStatus: Status { thread.lock.withLock { thread.status } }
        public override var streamError: Error? { thread.lock.withLock { thread.error } }
        public override var hasBytesAvailable: Bool { thread.lock.withLock { thread.bytesAvail } }
/*@f:1*/
        @usableFromInline let thread: IConvThread

        public init(inputStream: InputStream, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            self.thread = try IConvThread(inputStream, from, to, option)
            super.init(data: Data())
        }

        public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int { thread.getBytes(buffer, maxLength: len) }

        public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { fatalError("ERROR: Not implemented.") }

        public override func open() {
        }

        public override func close() {
        }

        @usableFromInline class IConvThread: Thread {
            @usableFromInline let inputStream:  InputStream
            @usableFromInline let iconv:        IConv
            @usableFromInline let lock:         NSCondition    = NSCondition()
            @usableFromInline var started:      Bool           = false
            @usableFromInline var notDone:      Bool           = true
            @usableFromInline var error:        Error?         = nil
            @usableFromInline let outputBuffer: ByteRingBuffer = ByteRingBuffer(initialSize: IcOutLength)

            @inlinable var status:     Stream.Status { .notOpen }
            @inlinable var bytesAvail: Bool { notDone }
            @inlinable var keepGoing:  Bool { !(isValue(inputStream.streamStatus, in: .error, .atEnd, .closed) || isCancelled) }

            @usableFromInline init(_ inputStream: InputStream, _ from: String, _ to: String, _ option: IConv.Option) throws {
                self.inputStream = inputStream
                self.iconv = try IConv(fromEncoding: from, toEncoding: to, option: option)
                super.init()
                if self.inputStream.streamStatus != .notOpen { start() }
            }

            func open() {
                lock.withLock {
                    guard inputStream.streamStatus == .notOpen else { return }
                    inputStream.open()
                    start()
                }
            }

            func close() {
                lock.withLock {
                    guard inputStream.streamStatus != .notOpen else { return }
                    super.cancel()
                    while notDone { lock.wait() }
                    inputStream.close()
                }
            }

            override func start() {
                waitForOpening()
                if inputStream.streamStatus == .error {
                    error = inputStream.streamError
                }
                else {
                    qualityOfService = .background
                    started = true
                    super.start()
                }
            }

            override func main() {
                lock.withLock {
                    let inBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: IcInLength)
                    let icBuffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: IcOutLength)
                    var inIndex:  Int                         = 0

                    defer {
                        inBuffer.deallocate()
                        icBuffer.deallocate()
                        notDone = false
                    }

                    while keepGoing {
                        while outputBuffer.count > OutThresh && keepGoing { lock.wait(until: Date(timeIntervalSinceNow: 0.1)) }
                        guard refillBuffer(icBuffer, inBuffer, &inIndex) else { break }
                    }
                }
            }

            func refillBuffer(_ icBuffer: UnsafeMutablePointer<UInt8>, _ inBuffer: UnsafeMutablePointer<UInt8>, _ inIndex: inout Int) -> Bool {
                do {
                    while keepGoing && outputBuffer.count < OutMaxLen {
                        let delta = inputStream.read((inBuffer + inIndex), maxLength: (IcInLength - inIndex))

                        if delta > 0 {
                            try convert(icBuffer: icBuffer, inBuffer: inBuffer, inIndex: &inIndex, delta: delta)
                        }
                        else {
                            if delta < 0 { error = inputStream.streamError }
                            return false
                        }
                    }
                    return keepGoing
                }
                catch let ex {
                    error = ex
                    return false
                }
            }

            func convert(icBuffer: UnsafeMutablePointer<UInt8>, inBuffer: UnsafeMutablePointer<UInt8>, inIndex: inout Int, delta: Int) throws {
                let s = try iconv.convert(input: inBuffer, inputLength: (inIndex + delta), output: icBuffer, outputMaxLength: IcOutLength)
                inIndex = s.newInputLength
                outputBuffer.append(data: icBuffer, length: s.outputLength)
            }

            @inlinable func getBytes(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
                lock.withLock {
                    guard started else { return 0 }
                    var cc: Int = 0
                    while cc < len {
                        while notDone && outputBuffer.count == 0 { lock.wait() }
                        if outputBuffer.count > 0 { cc += outputBuffer.getNext(into: (buffer + cc), maxLength: (len - cc)) }
                        else if notDone { break }
                    }
                    return cc
                }
            }

            @inlinable func waitForOpening() { while inputStream.streamStatus == .opening {} }
        }
    }

    public enum IConvInputStreamErrors: Error {
        case FileNotFoundAtURL(url: URL)
        case FileNotFoundAtPath(path: String)
    }

    extension IConvInputStream {
        public convenience init(data: Data, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            try self.init(inputStream: InputStream(data: data), fromEncoding: from, toEncoding: to, option: option)
        }

        public convenience init(url: URL, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            guard let i = InputStream(url: url) else { throw IConvInputStreamErrors.FileNotFoundAtURL(url: url) }
            try self.init(inputStream: i, fromEncoding: from, toEncoding: to, option: option)
        }

        public convenience init(fileAtPath path: String, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            guard let i = InputStream(fileAtPath: path) else { throw IConvInputStreamErrors.FileNotFoundAtPath(path: path) }
            try self.init(inputStream: i, fromEncoding: from, toEncoding: to, option: option)
        }
    }
#endif
