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

public class IConvInputStream: FilteredInputStream {

    @usableFromInline let _ringBuffer: SwRingBuffer = SwRingBuffer(initialSize: MaxReadAheadLimit)
    @usableFromInline var _error:      Error?       = nil
    @usableFromInline var _status:     Status
    @usableFromInline var _iconv:      IConv
    @usableFromInline let _thread:     IConvInputStreamThread

/*@f:0*/
    public override var streamStatus:      Status { _thread.lock.withLock { _status                                                  } }
    public override var streamError:       Error? { _thread.lock.withLock { _error                                                   } }
    public override var hasBytesAvailable: Bool   { _thread.lock.withLock { (_ringBuffer.count > 0) || inputStream.hasBytesAvailable } }
/*@f:1*/

    public init(inputStream: InputStream, to outputEncoding: String = "UTF-8", from inputEncoding: String, options: IConv.Options = .None) throws {
        _status = inputStream.streamStatus
        _error = inputStream.streamError
        _iconv = try IConv(to: outputEncoding, from: inputEncoding, options: options)
        _thread = IConvInputStreamThread()
        super.init(inputStream: inputStream)
        if inputStream.streamStatus != .notOpen { _thread.start(self) }
    }

    deinit {
        close()
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        super.read(buffer, maxLength: len)
    }

    public override func open() {
        _thread.lock.withLock {
            if _status == Status.notOpen {
                inputStream.open()
                _thread.start(self)
            }
            _status = inputStream.streamStatus
            _error = inputStream.streamError
        }
    }

    public override func close() {
        if _thread.isExecuting {
            _thread.cancel()
        }
        _status = .closed
        super.close()
    }
}

@usableFromInline class IConvInputStreamThread: Thread {
    let lock: NSCondition = NSCondition()

    override func main() {
        lock.withLock {
            while true {
            }
        }
    }

    func start(_ inputStream: IConvInputStream) {
        lock.withLock {
            if !(isExecuting || isFinished || isCancelled) {
                self._inputStream = inputStream
                self.qualityOfService = .background
                super.start()
            }
        }
    }

    override func start() { fatalError() }

    override func cancel() {
        lock.withLock {
            if !(isFinished || isCancelled) {
                _inputStream = nil
                super.cancel()
            }
        }
    }

    private weak var _inputStream: IConvInputStream? = nil
}
