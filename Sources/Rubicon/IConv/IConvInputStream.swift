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
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #endif

    public let MaxReadAheadLimit: Int = 65536
    public let ReadMoreThreshold: Int = (65536 - 2048)
    public let ReadBufferSize:    Int = 4096
    public let IConvBufferSize:   Int = ((ReadBufferSize + 2) * 4)

    public class IConvInputStream: InputStream {
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
    }

    /*==========================================================================================================================================================*/
    fileprivate class IConvInputStreamThread: Thread {
/*@f:0*/
        private let _inputStream:  InputStream
        private let _iconv:        IConv
        private let _inputBuffer:  UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: ReadBufferSize)
        private let _iconvBuffer:  UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: IConvBufferSize)
        private let _outputBuffer: SwRingBuffer                = SwRingBuffer(initialSize: MaxReadAheadLimit)
        private let _lock:         NSCondition                 = NSCondition()
        private var _error:        Error?                      = nil
        private var _allDone:      Bool                        = false

        override var isFinished:  Bool { _lock.withLock { (super.isFinished || _allDone)   } }
        override var isExecuting: Bool { _lock.withLock { (super.isExecuting && !_allDone) } }
        override var isCancelled: Bool { _lock.withLock { (super.isCancelled)              } }

        var streamStatus:      Stream.Status   { _lock.withLock { _inputStream.streamStatus          } }
        var streamError:       Error?          { _lock.withLock { _error ?? _inputStream.streamError } }
        var hasBytesAvailable: Bool            { _lock.withLock { _inputStream.hasBytesAvailable     } }
        var delegate:          StreamDelegate? { get { _lock.withLock { _inputStream.delegate } } set { _lock.withLock { _inputStream.delegate = newValue } } }
/*@f:1*/
        init(_ inputStream: InputStream, _ inputEncoding: String, _ toEncoding: String, _ options: IConv.Options) throws {
            self._inputStream = inputStream
            self._iconv = try IConv(to: toEncoding, from: inputEncoding, options: options)
            super.init()
            _start()
        }

        deinit {
            close()
            _inputBuffer.deallocate()
            _iconvBuffer.deallocate()
        }

        override func start() { _lock.withLock { _start() } }

        override func cancel() { _lock.withLock { _cancel() } }

        func open() {
            _lock.withLock {
                if _inputStream.streamStatus == .notOpen {
                    _inputStream.open()
                    qualityOfService = .background
                    super.start()
                }
            }
        }

        func close() {
            _lock.withLock {
                _inputStream.close()
                cancel()
            }
        }

        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            _lock.withLock {
                var cc = 0
                while cc < len {
                    _lock.wait(while: _outputBuffer.isEmpty && !_allDone)
                    if _allDone { return cc }
                    cc += _outputBuffer.getNext(into: buffer + cc, maxLength: len - cc)
                    _lock.broadcast()
                }
                return cc
            }
        }

        @inlinable var running:  Bool { !super.isCancelled }
        @inlinable var needMore: Bool { (_outputBuffer.count > ReadMoreThreshold) }

        override func main() {
            _lock.withLock {
                defer { _allDone = true }
                var inputOffset = 0

                repeat {
                    guard _foo01() else { break }
                    let cc = _inputStream.read(_inputBuffer + inputOffset, maxLength: ReadBufferSize - inputOffset)
                    guard cc > 0 else { break }

                    let inputBytes = (inputOffset + cc)
                    let res        = _iconv.convert(input: _inputBuffer, inputSize: inputBytes, output: _iconvBuffer, outputSize: IConvBufferSize)

                    switch res.0 {
                        case .Complete, .IncompleteSequence, .InvalidSequence, .OutputBufferFull:

                            break
                        case .Error(let e):
                            _error = e
                            return
                    }
                }
                while true
            }
        }

        private func _foo01() -> Bool {
            while (running && needMore) { _lock.wait() }
            return running
        }

        private func _start() {
            if !isValue(_inputStream.streamStatus, in: .notOpen, .error, .closed) {
                qualityOfService = .background
                super.start()
            }
        }

        private func _cancel() { super.cancel() }
    }
#endif
