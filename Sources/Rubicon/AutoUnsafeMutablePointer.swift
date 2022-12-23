// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: AutoUnsafeMutablePointer.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: December 22, 2022
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

/*==============================================================================================================================================================================*/
public final class AutoUnsafeMutablePointer<Pointee>: CVarArg, Hashable, Comparable, CustomDebugStringConvertible, CustomReflectable, Sendable, Strideable {
    public typealias Distance = UnsafeMutablePointer<Pointee>.Distance
    public typealias Stride = UnsafeMutablePointer<Pointee>.Stride

    @usableFromInline let pointer: UnsafeMutablePointer<Pointee>
    @usableFromInline let count:   Int
/*@f0*/
    @inlinable public var _cVarArgEncoding: [Int]   { pointer._cVarArgEncoding }
    @inlinable public var debugDescription: String  { pointer.debugDescription }
    @inlinable public var customMirror:     Mirror  { pointer.customMirror     }
    @inlinable public var pointee:          Pointee { pointer.pointee          }
/*@f1*/

    /*==========================================================================================================================================================================*/
    public init(_ pointer: UnsafeMutablePointer<Pointee>, count: Int) {
        self.count = count
        self.pointer = pointer
    }

    /*==========================================================================================================================================================================*/
    @usableFromInline init(_ pointer: UnsafeMutablePointer<Pointee>) {
        self.count = 0
        self.pointer = pointer
    }

    /*==========================================================================================================================================================================*/
    deinit { pointer.deallocate() }

    /*==========================================================================================================================================================================*/
    @inlinable @discardableResult public func deinitialize(count: Int) -> UnsafeMutableRawPointer { pointer.deinitialize(count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func advanced(by n: Stride) -> AutoUnsafeMutablePointer<Pointee> { AutoUnsafeMutablePointer(pointer.advanced(by: n)) }

    /*==========================================================================================================================================================================*/
    @inlinable public func assign(from source: AutoUnsafeMutablePointer<Pointee>, count: Int) { pointer.assign(from: source.pointer, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func assign(from source: UnsafePointer<Pointee>, count: Int) { pointer.assign(from: source, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func assign(repeating repeatedValue: Pointee, count: Int) { pointer.assign(repeating: repeatedValue, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func distance(to other: AutoUnsafeMutablePointer<Pointee>) -> Stride { pointer.distance(to: other.pointer) }

    /*==========================================================================================================================================================================*/
    @inlinable public func hash(into hasher: inout Hasher) { pointer.hash(into: &hasher) }

    /*==========================================================================================================================================================================*/
    @inlinable public func initialize(from source: AutoUnsafeMutablePointer<Pointee>, count: Int) { pointer.initialize(from: source.pointer, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func initialize(from source: UnsafePointer<Pointee>, count: Int) { pointer.initialize(from: source, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func initialize(repeating repeatedValue: Pointee, count: Int) { pointer.initialize(repeating: repeatedValue, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func initialize(to value: Pointee) { pointer.initialize(to: value) }

    /*==========================================================================================================================================================================*/
    @inlinable public func move() -> Pointee { pointer.move() }

    /*==========================================================================================================================================================================*/
    @inlinable public func moveAssign(from source: AutoUnsafeMutablePointer<Pointee>, count: Int) { pointer.moveAssign(from: source.pointer, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func moveAssign(from source: UnsafeMutablePointer<Pointee>, count: Int) { pointer.moveAssign(from: source, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func moveInitialize(from source: AutoUnsafeMutablePointer<Pointee>, count: Int) { pointer.moveInitialize(from: source.pointer, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func moveInitialize(from source: UnsafeMutablePointer<Pointee>, count: Int) { pointer.moveInitialize(from: source, count: count) }

    /*==========================================================================================================================================================================*/
    @inlinable public func pointer<Property>(to property: KeyPath<Pointee, Property>) -> UnsafePointer<Property>? { pointer.pointer(to: property) }

    /*==========================================================================================================================================================================*/
    @inlinable public func pointer<Property>(to property: WritableKeyPath<Pointee, Property>) -> UnsafeMutablePointer<Property>? { pointer.pointer(to: property) }

    /*==========================================================================================================================================================================*/
    @inlinable public subscript(offset: Int) -> Pointee { pointer[offset] }

    /*==========================================================================================================================================================================*/
    @inlinable public func withMemoryRebound<T, Result>(to type: T.Type, capacity count: Int, _ body: (UnsafeMutablePointer<T>) throws -> Result) rethrows -> Result {
        try pointer.withMemoryRebound(to: T.self, capacity: count, body)
    }

    /*==========================================================================================================================================================================*/
    @inlinable public class func _step(after current: (index: Int?, value: AutoUnsafeMutablePointer<Pointee>), from start: AutoUnsafeMutablePointer<Pointee>, by distance: Stride) -> (index: Int?, value: AutoUnsafeMutablePointer<Pointee>) {
        let r = UnsafeMutablePointer._step(after: (current.index, current.value.pointer), from: start.pointer, by: distance)
        return (r.index, AutoUnsafeMutablePointer<Pointee>(r.value))
    }

    /*==========================================================================================================================================================================*/
    @inlinable public class func allocate(capacity: Int) -> AutoUnsafeMutablePointer<Pointee> {
        AutoUnsafeMutablePointer<Pointee>(UnsafeMutablePointer<Pointee>.allocate(capacity: capacity), count: capacity)
    }

    /*==========================================================================================================================================================================*/
    @inlinable public static func == (lhs: AutoUnsafeMutablePointer<Pointee>, rhs: AutoUnsafeMutablePointer<Pointee>) -> Bool { (lhs.pointer == rhs.pointer) }

    /*==========================================================================================================================================================================*/
    @inlinable public static func < (lhs: AutoUnsafeMutablePointer<Pointee>, rhs: AutoUnsafeMutablePointer<Pointee>) -> Bool { (lhs.pointer < rhs.pointer) }
}
