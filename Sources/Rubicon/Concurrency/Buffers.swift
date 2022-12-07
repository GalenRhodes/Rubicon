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

/*==============================================================================================================================================================================*/
extension UnsafeRawBufferPointer {
    /*==========================================================================================================================================================================*/
    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafeRawPointer, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }

}

/*==============================================================================================================================================================================*/
extension UnsafeMutableRawBufferPointer {
    /*==========================================================================================================================================================================*/
    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafeMutableRawPointer, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}

/*==============================================================================================================================================================================*/
extension UnsafeBufferPointer {
    /*==========================================================================================================================================================================*/
    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafePointer<Element>, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}

/*==============================================================================================================================================================================*/
extension UnsafeMutableBufferPointer {
    /*==========================================================================================================================================================================*/
    @inlinable public func withBaseAddress<R>(errorMessage: String = "Internal Error", _ block: (UnsafeMutablePointer<Element>, Int) throws -> R) rethrows -> R {
        guard let ptr = baseAddress else { fatalError(errorMessage) }
        return try block(ptr, count)
    }
}

/*==============================================================================================================================================================================*/
extension UnsafeRawPointer {
    /*==========================================================================================================================================================================*/
    @inlinable public func asMutable<R>(_ block: (UnsafeMutableRawPointer) throws -> R) rethrows -> R {
        try block(UnsafeMutableRawPointer(mutating: self))
    }
}

/*==============================================================================================================================================================================*/
extension UnsafePointer {
    /*==========================================================================================================================================================================*/
    @inlinable public func asMutable<R>(_ block: (UnsafeMutablePointer<Pointee>) throws -> R) rethrows -> R {
        try block(UnsafeMutablePointer<Pointee>(mutating: self))
    }
}

/*==============================================================================================================================================================================*/
/// Creates a mutable buffer or a specific type and capacity and then calls the given closure with that buffer. After the closure has executed
/// the buffer is deallocated automatically.
///
/// <b>NOTE:</b> The closure is responsible for initializing and de-initializing the buffer if needed.
///
/// - Parameters:
///   - type: The type of data the buffer will hold.
///   - capacity: The number of items of the given type that the buffer will hold.
///   - action: The closure.
/// - Returns: Whatever the closure returns.
/// - Throws: Anything the closure throws.
///
@discardableResult public func withTemporaryBuffer<T, R>(ofType type: T.Type, capacity: Int, _ action: (UnsafeMutablePointer<T>, Int) throws -> R) rethrows -> R {
    let buffer = UnsafeMutablePointer<T>.allocate(capacity: capacity)
    defer { buffer.deallocate() }
    return try action(buffer, capacity)
}

/*==============================================================================================================================================================================*/
/// Creates a mutable buffer or a specific type and capacity and then calls the given closure with that buffer. After the closure has executed
/// the buffer is deallocated automatically.
///
/// <b>NOTE:</b> The closure is responsible for initializing and de-initializing the buffer if needed.
///
/// - Parameters:
///   - byteCount: The number of items of the given type that the buffer will hold.
///   - alignment: The alignment.
///   - action: The closure.
/// - Returns: Whatever the closure returns.
/// - Throws: Anything the closure throws.
///
@discardableResult public func withTemporaryRawBuffer<R>(byteCount: Int, alignment: Int, _ action: (UnsafeMutableRawPointer, Int) throws -> R) rethrows -> R {
    let buffer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
    defer { buffer.deallocate() }
    return try action(buffer, byteCount)
}
