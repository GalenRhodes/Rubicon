// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Pipe.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: December 14, 2022
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

extension Pipe {
    @usableFromInline static let BufferSize: Int = 1024

    @discardableResult public func writeToPipe(from source: (UnsafeMutablePointer<UInt8>, Int) throws -> Int) throws -> Int {
        let buffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: Pipe.BufferSize)
        defer { buffer.deallocate() }

        let fileHandle: FileHandle = fileHandleForWriting
        var cc:         Int        = try source(buffer, Pipe.BufferSize)
        var total:      Int        = 0

        while cc > 0 {
            try fileHandle.write(contentsOf: UnsafeBufferPointer<UInt8>(start: buffer, count: cc))
            total += cc
            cc = try source(buffer, Pipe.BufferSize)
        }

        return total
    }

    @discardableResult public func readFromPipe(to target: (UnsafePointer<UInt8>, Int) throws -> Bool) throws -> Int {
        let fileHandle: FileHandle = fileHandleForReading
        var total:      Int        = 0
        var data:       Data?      = try fileHandle.read(upToCount: Pipe.BufferSize)

        while let d = data, d.count > 0 {
            guard !(try d.withDataReboundAs(ofType: UInt8.self, { try target($0, $1) })) else { break }
            total += d.count
            data = try fileHandle.read(upToCount: Pipe.BufferSize)
        }

        return total
    }
}
