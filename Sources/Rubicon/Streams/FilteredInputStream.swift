// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: FilteredInputStream.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 03, 2022
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

open class FilteredInputStream: InputStream {
    @usableFromInline let inputStream: InputStream

    open override var streamStatus:      Status { inputStream.streamStatus }
    open override var streamError:       Error? { inputStream.streamError }
    open override var hasBytesAvailable: Bool { inputStream.hasBytesAvailable }

    #if os(macOS) || os(tvOS) || os(watchOS) || os(iOS) || os(OSX)
        open override unowned(unsafe) var delegate: StreamDelegate? {
            get { inputStream.delegate }
            set { inputStream.delegate = newValue }
        }
    #else
        open override weak var delegate: StreamDelegate? {
            get { inputStream.delegate }
            set { inputStream.delegate = newValue }
        }
    #endif

    public init(inputStream: InputStream) {
        self.inputStream = inputStream
        super.init(data: Data())
    }

    public override convenience init(data: Data) {
        self.init(inputStream: InputStream(data: data))
    }

    public override convenience init?(url: URL) {
        guard let inputStream = InputStream(url: url) else { return nil }
        self.init(inputStream: inputStream)
    }

    public convenience init?(fileAtPath path: String) {
        guard let inputStream = InputStream(fileAtPath: path) else { return nil }
        self.init(inputStream: inputStream)
    }

    open override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        inputStream.read(buffer, maxLength: len)
    }

    open override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        inputStream.getBuffer(buffer, length: len)
    }

    open override func open() {
        inputStream.open()
    }

    open override func close() {
        inputStream.close()
    }

    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        inputStream.schedule(in: aRunLoop, forMode: mode)
    }

    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        inputStream.remove(from: aRunLoop, forMode: mode)
    }

    #if os(macOS) || os(tvOS) || os(watchOS) || os(iOS) || os(OSX)
        open override func property(forKey key: PropertyKey) -> Any? {
            inputStream.property(forKey: key)
        }

        open override func setProperty(_ property: Any?, forKey key: PropertyKey) -> Bool {
            inputStream.setProperty(property, forKey: key)
        }

        open override class func getBoundStreams(withBufferSize bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
            InputStream.getBoundStreams(withBufferSize: bufferSize, inputStream: inputStream, outputStream: outputStream)
        }
    #else
        open override func property(forKey key: PropertyKey) -> AnyObject? {
            inputStream.property(forKey: key)
        }

        open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
            inputStream.setProperty(property, forKey: key)
        }
    #endif
}
