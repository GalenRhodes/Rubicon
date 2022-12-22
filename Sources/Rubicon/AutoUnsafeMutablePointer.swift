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

public final class AutoUnsafeMutablePointer<Pointee>: CVarArg, Hashable, Comparable, CustomDebugStringConvertible, CustomReflectable, Sendable, Strideable {
    public typealias Distance = UnsafeMutablePointer<Pointee>.Distance
    public typealias Stride = UnsafeMutablePointer<Pointee>.Stride

    @usableFromInline let pointer: UnsafeMutablePointer<Pointee>
/*@f0*/
    @inlinable public var _cVarArgEncoding: [Int]   { pointer._cVarArgEncoding }
    @inlinable public var debugDescription: String  { pointer.debugDescription }
    @inlinable public var customMirror:     Mirror  { pointer.customMirror     }
    @inlinable public var pointee:          Pointee { pointer.pointee          }
/*@f1*/

    public init(capacity: Int) { pointer = UnsafeMutablePointer<Pointee>.allocate(capacity: capacity) }

    init(_ pointer: UnsafeMutablePointer<Pointee>) { self.pointer = pointer }

    deinit { pointer.deallocate() }

    public func hash(into hasher: inout Hasher) { pointer.hash(into: &hasher) }

    public static func ==(lhs: AutoUnsafeMutablePointer<Pointee>, rhs: AutoUnsafeMutablePointer<Pointee>) -> Bool { (lhs.pointer == rhs.pointer) }

    public static func <(lhs: AutoUnsafeMutablePointer<Pointee>, rhs: AutoUnsafeMutablePointer<Pointee>) -> Bool { (lhs.pointer < rhs.pointer) }

    public func distance(to other: AutoUnsafeMutablePointer<Pointee>) -> Stride { pointer.distance(to: other.pointer) }

    public func advanced(by n: Stride) -> AutoUnsafeMutablePointer<Pointee> { AutoUnsafeMutablePointer(pointer.advanced(by: n)) }

    public class func _step(after current: (index: Int?, value: AutoUnsafeMutablePointer<Pointee>), from start: AutoUnsafeMutablePointer<Pointee>, by distance: Stride) -> (index: Int?, value: AutoUnsafeMutablePointer<Pointee>) {
        let r = UnsafeMutablePointer._step(after: (current.index, current.value.pointer), from: start.pointer, by: distance)
        return (r.index, AutoUnsafeMutablePointer<Pointee>(r.value))
    }
}
