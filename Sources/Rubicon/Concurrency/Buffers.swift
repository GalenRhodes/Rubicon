// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Buffers.swift
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

extension UnsafeRawBufferPointer {
    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafeRawPointer, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}

extension UnsafeMutableRawBufferPointer {
    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafeMutableRawPointer, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}

extension UnsafeBufferPointer {

    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafePointer<Element>, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}

extension UnsafeMutableBufferPointer {

    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafeMutablePointer<Element>, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}
