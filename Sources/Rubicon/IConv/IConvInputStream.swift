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

    public class IConvInputStream: InputStream {
        public static let   MaxReadAheadLimit: Int = 65536
        public static let   HeadRoomSize:      Int = (MaxReadAheadLimit / 32)
        public static let   ReadMoreThreshold: Int = (MaxReadAheadLimit - HeadRoomSize)
        public static let   ReadBufferSize:    Int = (HeadRoomSize * 2)
        public static let   IConvBufferSize:   Int = ((ReadBufferSize + 4) * 4)

        /*@f:0*/
        public override var delegate:          StreamDelegate? { get { worker.delegate } set { worker.delegate = newValue } }
        public override var hasBytesAvailable: Bool            { worker.hasBytesAvailable }
        public override var streamStatus:      Status          { worker.streamStatus      }
        public override var streamError:       Error?          { worker.streamError       }
        public          let inputEncoding:     String
        public          let toEncoding:        String
        public          let options:           IConv.Options
        private         let worker:            IConvInputStreamThread
        /*@f:1*/

        public init(inputStream: InputStream, inputEncoding: String, toEncoding: String = "UTF-8", options: IConv.Options = .None) throws {
            self.toEncoding = toEncoding
            self.inputEncoding = inputEncoding
            self.options = options
            self.worker = try IConvInputStreamThread(inputStream, inputEncoding, toEncoding, options)
            super.init(data: Data())
        }

        deinit {
            print("DEBUG: deinit called. Closing stream.")
            worker.close()
        }

        public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int { worker.read(buffer, maxLength: len) }

        public override func open() { worker.open() }

        public override func close() { worker.close() }

        /*==========================================================================================================================================================*/
        class IConvInputStreamThread: Thread {
/*@f:0*/
            private let lock:         NSCondition = NSCondition()
            private var notDone:      Bool        = true
            private var error:        Error?
            private var reader:       Reader!
            private let inputStream:  InputStream

            override var isFinished:  Bool { lock.withLock { (super.isFinished || !notDone) } }
            override var isExecuting: Bool { lock.withLock { (super.isExecuting && notDone) } }
            override var isCancelled: Bool { lock.withLock { (super.isCancelled)            } }

            var streamError:       Error?          { lock.withLock { error ?? inputStream.streamError } }
            var hasBytesAvailable: Bool            { lock.withLock { inputStream.hasBytesAvailable    } }
            var delegate:          StreamDelegate? { get { lock.withLock { inputStream.delegate } } set { lock.withLock { inputStream.delegate = newValue } } }
/*@f:1*/
            var streamStatus: Stream.Status {
                lock.withLock {
                    let st = inputStream.streamStatus
                    switch st {
                        case .notOpen, .error, .closed, .opening: return st
                        case .open, .reading, .writing:           return ((error == nil) ? .open : .error)
                        case .atEnd:                              return ((error == nil) ? ((reader.bytesAvailable > 0) ? .open : .atEnd) : .error)
                        @unknown default:                         return ((error == nil) ? st : .error)
                    }
                }
            }

            init(_ inputStream: InputStream, _ inputEncoding: String, _ toEncoding: String, _ options: IConv.Options) throws {
                self.inputStream = inputStream
                super.init()
                self.reader = try Reader(inputEncoding, toEncoding, options)
                pStart()
            }

            deinit {
                close()
            }

            override func start() { lock.withLock { pStart() } }

            override func cancel() {
                lock.withLock {
                    guard notDone else { return }
                    super.cancel()
                    while notDone { lock.wait() }
                }
            }

            func open() {
                lock.withLock {
                    if inputStream.streamStatus == .notOpen {
                        inputStream.open()
                        rStart()
                    }
                }
            }

            func close() {
                lock.withLock {
                    super.cancel()
                    inputStream.close()
                }
            }

            func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
                var cc = 0
                while cc < len { guard reader.read(buffer, len, lock, &cc, notDone) else { break } }
                return cc
            }

            private func pStart() {
                if isValue(inputStream.streamStatus, in: .closed, .atEnd, .error) { notDone = false }
                else if inputStream.streamStatus != .notOpen { rStart() }
            }

            private func rStart() {
                qualityOfService = .background
                super.start()
            }

            override func main() {
                defer { notDone = false }
                reader.readLoop(lock, inputStream, &error, !super.isCancelled)
            }

            /*==========================================================================================================================================================*/
            class Reader {

                var bytesAvailable: Int { outputBuffer.count }

                private var inIdx:        Int                         = 0
                private let inputBuffer:  UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: ReadBufferSize)
                private let iconvBuffer:  UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: IConvBufferSize)
                private let outputBuffer: SwRingBuffer                = SwRingBuffer(initialSize: MaxReadAheadLimit)
                private let iconv:        IConv

                init(_ inputEncoding: String, _ toEncoding: String, _ options: IConv.Options) throws {
                    self.iconv = try IConv(to: toEncoding, from: inputEncoding, options: options)
                }

                deinit {
                    inputBuffer.deallocate()
                    iconvBuffer.deallocate()
                }

                func read(_ buffer: UnsafeMutablePointer<UInt8>, _ len: Int, _ lock: NSCondition, _ cc: inout Int, _ isRunning: @autoclosure () -> Bool) -> Bool {
                    lock.withLock {
                        lock.wait(while: outputBuffer.isEmpty && isRunning())
                        guard isRunning() else { return false }
                        cc += outputBuffer.getNext(into: (buffer + cc), maxLength: (len - cc))
                        return true
                    }
                }

                func readLoop(_ lock: NSCondition, _ inputStream: InputStream, _ error: inout Error?, _ isRunning: @autoclosure () -> Bool) {
                    lock.withLock {
                        while isRunning() {
                            while (isRunning() && (outputBuffer.count > ReadMoreThreshold)) { lock.wait() }
                            guard isRunning() && readAndConvert(inputStream, &error) else { break }
                        }
                    }
                }

                func readAndConvert(_ inputStream: InputStream, _ error: inout Error?) -> Bool {
                    let cc = inputStream.read((inputBuffer + inIdx), maxLength: (ReadBufferSize - inIdx))
                    return ((cc > 0) && convert(byteCount: (inIdx + cc), error: &error))
                }

                func convert(byteCount bc: Int, error: inout Error?) -> Bool {
                    let rs = iconv.convert(input: inputBuffer, inputSize: bc, output: iconvBuffer, outputSize: IConvBufferSize)

                    switch rs.status {
                        case .Error(let e):
                            error = e
                            return false
                        default:
                            if rs.outputCount > 0 { outputBuffer.append(data: iconvBuffer, length: rs.outputCount) }
                            inIdx = ((PGMemCpy(inputBuffer, (inputBuffer + rs.inputCount), (bc - rs.inputCount)) > 0) ? rs.inputCount : 0)
                            return true
                    }
                }
            }
        }
    }
#endif
