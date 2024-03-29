// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Data.swift
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

extension Data {
    @inlinable public func asString(encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)
    }

    @inlinable public func withUnsafeBytes2<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try withUnsafeBytes { (p: UnsafeRawBufferPointer) -> R in try body(p) }
    }

    @inlinable public func withDataReboundAs<T, R>(ofType type: T.Type, _ body: (UnsafePointer<T>, Int) throws -> R) rethrows -> R {
        try withUnsafeBytes { (p: UnsafeRawBufferPointer) -> R in try p.withMemoryRebound(to: type) { try $0.withBaseAddress { try body($0, $1) } } }
    }
}
