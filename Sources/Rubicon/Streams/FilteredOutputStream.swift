// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: FilteredOutputStream.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 08, 2022
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

public class FilteredOutputStream: OutputStream {
    let outputStream: OutputStream

    public override var hasSpaceAvailable: Bool { outputStream.hasSpaceAvailable }
    public override var streamStatus:      Status { outputStream.streamStatus }
    public override var streamError:       Error? { outputStream.streamError }

    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
        public override unowned(unsafe) var delegate: StreamDelegate? {
            get { outputStream.delegate }
            set { outputStream.delegate = newValue }
        }
    #else
        public override weak var delegate: StreamDelegate? {
            get { outputStream.delegate }
            set { outputStream.delegate = newValue }
        }
    #endif

    public init(outputStream: OutputStream) {
        self.outputStream = outputStream
        super.init(toMemory: ())
    }

    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
        public override init(toMemory: Void) {
            self.outputStream = OutputStream(toMemory: toMemory)
            super.init(toMemory: ())
        }
    #else
        public required init(toMemory: Void) {
            self.outputStream = OutputStream(toMemory: toMemory)
            super.init(toMemory: ())
        }
    #endif

    public override init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int) {
        self.outputStream = OutputStream(toBuffer: buffer, capacity: capacity)
        super.init(toMemory: ())
    }

    public override init?(url: URL, append shouldAppend: Bool) {
        guard let os = OutputStream(url: url, append: shouldAppend) else { return nil }
        self.outputStream = os
        super.init(toMemory: ())
    }

    public init?(toFileAtPath path: String, append shouldAppend: Bool) {
        guard let os = OutputStream(toFileAtPath: path, append: shouldAppend) else { return nil }
        self.outputStream = os
        super.init(toMemory: ())
    }

    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        outputStream.write(buffer, maxLength: len)
    }

    public override func open() {
        outputStream.open()
    }

    public override func close() {
        outputStream.close()
    }

    #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
        public override func property(forKey key: PropertyKey) -> Any? {
            outputStream.property(forKey: key)
        }

        public override func setProperty(_ property: Any?, forKey key: PropertyKey) -> Bool {
            outputStream.setProperty(property, forKey: key)
        }
    #else
        public override func property(forKey key: PropertyKey) -> AnyObject? {
            outputStream.property(forKey: key)
        }

        public override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
            outputStream.setProperty(property, forKey: key)
        }
    #endif

    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        outputStream.schedule(in: aRunLoop, forMode: mode)
    }

    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        outputStream.remove(from: aRunLoop, forMode: mode)
    }

    public override class func toMemory() -> Self {
        FilteredOutputStream(outputStream: OutputStream.toMemory()) as! Self
    }
}
