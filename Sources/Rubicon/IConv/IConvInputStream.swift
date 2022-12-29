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

    /*==========================================================================================================================================================================*/
    @usableFromInline let IcOutMaxLen: Int = 65536
    @usableFromInline let IcOutThresh: Int = ((IcOutMaxLen * 8) / 10)
    @usableFromInline let IcInLength:  Int = 1024
    @usableFromInline let IcOutLength: Int = ((IcInLength + 4) * 4) // For conversion of anything to UTF-32...

    /*==========================================================================================================================================================================*/
    public class IConvInputStream: InputStream {
/*@f0*/
        public override var streamError:       Error? { thread.lock.withLock { (thread.status == .error) ? thread.error ?? thread.inputStream.streamError : nil } }
        public override var streamStatus:      Status { thread.lock.withLock { thread.status                                                                    } }
        public override var hasBytesAvailable: Bool   { thread.lock.withLock { thread.bytesAvail                                                                } }
/*@f1*/
        @usableFromInline let thread: IConvThread

        /*======================================================================================================================================================================*/
        public init(inputStream: InputStream, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            self.thread = try IConvThread(inputStream, from, to, option)
            super.init(data: Data())
        }

        /*======================================================================================================================================================================*/
        public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            thread.getBytes(buffer, maxLength: len)
        }

        /*======================================================================================================================================================================*/
        public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
            fatalError("ERROR: Not implemented.")
        }

        /*======================================================================================================================================================================*/
        public override func open() {
        }

        /*======================================================================================================================================================================*/
        public override func close() {
        }

        /*======================================================================================================================================================================*/
        @usableFromInline class IConvThread: Thread {
            @usableFromInline let inputStream:  InputStream
            @usableFromInline let iconv:        IConv
            @usableFromInline let lock:         NSCondition    = NSCondition()
            @usableFromInline var started:      Bool           = false
            @usableFromInline var notDone:      Bool           = true
            @usableFromInline var error:        Error?         = nil
            @usableFromInline var reading:      Bool           = false
            @usableFromInline let outputBuffer: ByteRingBuffer = ByteRingBuffer(initialSize: IcOutLength)

            @inlinable var bytesAvail: Bool { isValue(status, in: .opening, .reading) }
            @inlinable var keepGoing:  Bool { (isValue(inputStream.streamStatus, in: .open, .reading) || isCancelled) }
            @inlinable var status:     Stream.Status {
                guard error == nil || outputBuffer.count > 0 else { return .error }
                let st = inputStream.streamStatus
                switch st {
                    case .notOpen, .opening, .closed: return st
                    case .open, .reading, .writing:   return (reading ? .reading : .open)
                    case .atEnd, .error:              return ((outputBuffer.count > 0) ? (reading ? .reading : .open) : st)
                    @unknown default:                 return .error
                }
            }

            /*==================================================================================================================================================================*/
            @usableFromInline init(_ inputStream: InputStream, _ from: String, _ to: String, _ option: IConv.Option) throws {
                self.inputStream = inputStream
                self.iconv = try IConv(fromEncoding: from, toEncoding: to, option: option)
                super.init()
                if self.inputStream.streamStatus != .notOpen { start() }
            }

            /*==================================================================================================================================================================*/
            @inlinable func open() {
                lock.withLock {
                    guard inputStream.streamStatus == .notOpen else { return }
                    inputStream.open()
                    if !started { start() }
                }
            }

            /*==================================================================================================================================================================*/
            @inlinable func close() {
                lock.withLock {
                    guard inputStream.streamStatus != .notOpen else { return }
                    super.cancel()
                    while notDone { lock.wait() }
                    inputStream.close()
                }
            }

            /*==================================================================================================================================================================*/
            @usableFromInline override func start() {
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

            /*==================================================================================================================================================================*/
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

                    do {
                        while keepGoing {
                            while keepGoing && outputBuffer.count >= IcOutMaxLen { lock.wait() }
                            guard keepGoing else { break }

                            let inByteCount = inputStream.read((inBuffer + inIndex), maxLength: (IcInLength - inIndex))
                            guard inByteCount > 0 else { break }

                            let icR = try iconv.convert(input: inBuffer, inputLength: (inIndex + inByteCount), output: icBuffer, outputMaxLength: IcOutLength)
                            inIndex = icR.newInputLength
                            outputBuffer.append(data: icBuffer, length: icR.outputLength)
                        }
                    }
                    catch let e {
                        error = e
                    }
                }
            }

            /*==================================================================================================================================================================*/
            @inlinable func getBytes(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
                lock.withLock {
                    guard started else { return 0 }
                    var cc: Int = 0
                    reading = true
                    defer { reading = false }
                    while cc < len {
                        while notDone && outputBuffer.count == 0 { lock.wait() }
                        guard notDone else { break }
                        cc += outputBuffer.getNext(into: (buffer + cc), maxLength: (len - cc))
                    }
                    return cc
                }
            }

            /*==================================================================================================================================================================*/
            @inlinable func waitForOpening() { while inputStream.streamStatus == .opening {} }
        }
    }

    /*==========================================================================================================================================================================*/
    public enum IConvInputStreamErrors: Error {
        case FileNotFoundAtURL(url: URL)
        case FileNotFoundAtPath(path: String)
    }

    /*==========================================================================================================================================================================*/
    extension IConvInputStream {

        /*======================================================================================================================================================================*/
        public convenience init(data: Data, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            try self.init(inputStream: InputStream(data: data), fromEncoding: from, toEncoding: to, option: option)
        }

        /*======================================================================================================================================================================*/
        public convenience init(url: URL, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            guard let i = InputStream(url: url) else { throw IConvInputStreamErrors.FileNotFoundAtURL(url: url) }
            try self.init(inputStream: i, fromEncoding: from, toEncoding: to, option: option)
        }

        /*======================================================================================================================================================================*/
        public convenience init(fileAtPath path: String, fromEncoding from: String, toEncoding to: String = "UTF-8", option: IConv.Option = .None) throws {
            guard let i = InputStream(fileAtPath: path) else { throw IConvInputStreamErrors.FileNotFoundAtPath(path: path) }
            try self.init(inputStream: i, fromEncoding: from, toEncoding: to, option: option)
        }
    }
#endif
