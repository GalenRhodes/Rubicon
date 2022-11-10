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

public class IConvInputStream: FilteredInputStream {

    @usableFromInline let _ringBuffer: SwRingBuffer = SwRingBuffer(initialSize: MaxReadAheadLimit)
    @usableFromInline let _lock:       NSCondition  = NSCondition()
    @usableFromInline var _error:      Error?       = nil
    @usableFromInline var _status:     Status
    @usableFromInline var _iconv:      IConv
    @usableFromInline let _thread:     IConvInputStreamThread

/*@f:0*/
    public override var streamStatus:      Status { _lock.withLock { _status                       } }
    public override var streamError:       Error? { _lock.withLock { _error                        } }
    public override var hasBytesAvailable: Bool   { _lock.withLock { inputStream.hasBytesAvailable } }
/*@f:1*/

    public init(inputStream: InputStream, to outputEncoding: String = "UTF-8", from inputEncoding: String, options: IConv.Options = .None) throws {
        _status = inputStream.streamStatus
        _error = inputStream.streamError
        _iconv = try IConv(to: outputEncoding, from: inputEncoding, options: options)
        _thread = IConvInputStreamThread()
        super.init(inputStream: inputStream)
        _thread.inputStream = self
        if inputStream.streamStatus != .notOpen { _thread.start() }
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        _lock.withLock {
            var cc = 0

            while cc < len {
                let c = _ringBuffer.getNext(into: buffer, maxLength: len - cc)
            }

            return cc
        }
    }

    public override func open() {
        _lock.withLock {
            if _status == Status.notOpen { inputStream.open() }
            _status = inputStream.streamStatus
            _error = inputStream.streamError
        }
    }

    public override func close() {
        super.close()
    }
}

@usableFromInline class IConvInputStreamThread: Thread {

    @usableFromInline weak var inputStream: IConvInputStream? = nil

    override init() {
        super.init()
        self.qualityOfService = .background
    }

    override func main() {
        super.main()
    }
}
