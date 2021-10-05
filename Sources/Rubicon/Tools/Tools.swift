/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Tools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/30/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation
import CoreFoundation
#if os(Windows)
    import WinSDK
#endif

/*==============================================================================================================*/
/// Values that indicate should be sorted against another object.
///
public enum SortOrdering: Int {
    /*==========================================================================================================*/
    /// One object comes before another object.
    ///
    case LessThan    = -1
    /*==========================================================================================================*/
    /// One object holds the same place as another object.
    ///
    case EqualTo     = 0
    /*==========================================================================================================*/
    /// One object comes after another object.
    ///
    case GreaterThan = 1
}

/*==============================================================================================================*/
/// A new operator for comparing two objects.
///
infix operator <=>: ComparisonPrecedence

/*==============================================================================================================*/
/// Compares two objects to see what their `SortOrdering` is. Both objects have to conform to the
/// [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol.
///
/// Usage:
/// ```
///     func `foo(str1: String, str2: String)` { switch str1 <=> str2 { case .LessThan: `print("'\(str1)`' comes
///     before '\(str2)'") case .EqualTo: `print("'\(str1)`' is the same as '\(str2)'") case .GreaterThan:
///     `print("'\(str1)`' comes after '\(str2)'") } }
/// ```
///
/// - Parameters:
///   - l: The left hand operand
///   - r: The right hand operand
///
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand
///            operand should be sorted before, at the same place as, or after the right-hand operand.
///
@inlinable public func <=> <T: Comparable>(l: T?, r: T?) -> SortOrdering {
    (l == nil ? (r == nil ? .EqualTo : .LessThan) : (r == nil ? .GreaterThan : (l! < r! ? .LessThan : (l! > r! ? .GreaterThan : .EqualTo))))
}

/*==============================================================================================================*/
/// Compares two arrays to see what their `SortOrdering` is. The objects of both arrays have to conform to the
/// [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol. This method first compares the number
/// of objects in each array. If they are not the same then the function will return `SortOrdering.Before` or
/// `SortOrdering.After` as the left-hand array has fewer or more objects than the right-hand array. If the both
/// hold the same number of objects then the function compares each object in the left-hand array to the object in
/// the same position in the right-hand array. In other words it compares `leftArray[0]` to `rightArray[0]`,
/// `leftArray[1]` to `rightArray[1]` and so on until it finds the first pair of objects that do not of the same
/// sort ordering and returns ordering. If all the objects in the same positions in both arrays are
/// `SortOrdering.Same` then this function returns `SortOrdering.Same`.
///
/// Example:
/// ```
///     let array1: [Int] = [ 1, 2, 3, 4 ] let array2: [Int] = [ 1, 2, 3, 4 ] let array3: [Int] = [ 1, 2, 3 ] let
///     array4: [Int] = [ 1, 2, 5, 6 ]
///
///     let result1: SortOrdering = array1 <=> array2 // result1 is set to `SortOrdering.EqualTo` let result2:
///     SortOrdering = array1 <=> array3 // result2 is set to `SortOrdering.GreaterThan` let result3: SortOrdering
///     = array1 <=> array4 // result3 is set to `SortOrdering.LessThan`
/// ```
///
/// - Parameters:
///   - l: The left hand array operand
///   - r: The right hand array operand
///
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand array
///            comes before, in the same place as, or after the right-hand array.
///
@inlinable public func <=> <T: Comparable>(l: [T?], r: [T?]) -> SortOrdering {
    var cc: SortOrdering = (l.count <=> r.count)

    if cc == .EqualTo {
        for i: Int in (0 ..< l.count) {
            cc = (l[i] <=> r[i])
            guard cc == .EqualTo else { break }
        }
    }

    return cc
}

/*==============================================================================================================*/
/// If the `maxLength` is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then return the largest
/// integer possible (<code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>)
/// otherwise returns the value of `maxLength`.
///
/// - Parameter maxLength: the length to fix.
/// - Returns: Either the value of `maxLength` or
///            <code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>.
///
@inlinable public func fixLength(_ maxLength: Int) -> Int { ((maxLength < 0) ? Int.max : maxLength) }

/*==============================================================================================================*/
/// Tests one value to see if it is one of the listed values. Instead of doing this:
/// ```
///     if number == 1 || number == 5 || number == 99 { /* do something */ }
/// ```
///
/// You can now do this:
/// ```
///     if `value(number, isOneOf: 1, 5, 99)` { /* do something */ }
/// ```
///
/// - Parameters:
///   - value: The value to be tested.
///   - isOneOf: The desired values.
/// - Returns: `true` of the value is one of the desired values.
///
@inlinable public func value<T: Equatable>(_ value: T, isOneOf: T...) -> Bool { isOneOf.isAny { value == $0 } }

@inlinable public func value<T: Equatable>(_ value: T, isOneOf: [T]) -> Bool { isOneOf.isAny { value == $0 } }

/*==============================================================================================================*/
/// Calculate the number of instances of a given datatype will occupy a given number of bytes. For example, if
/// given a type of `Int64.self` and a byte count of 16 then this function will return a value of 2.
///
/// - Parameters:
///   - type: The target datatype.
///   - value: The number of bytes.
/// - Returns: The number of instances of the datatype that can occupy the given number of bytes.
///
@inlinable public func fromBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<UInt8>.stride) / MemoryLayout<T>.stride) }

/*==============================================================================================================*/
/// Calculate the number of bytes that make up a given number of instances of the given datatype. For example if
/// given a datatype of `Int64.self` and a count of 2 then this function will return 16.
///
/// - Parameters:
///   - type: The target datatype.
///   - value: The number of instances of the datatype.
/// - Returns: The number of bytes that make up that many instances of that datatype.
///
@inlinable public func toBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<T>.stride) / MemoryLayout<UInt8>.stride) }

/*==============================================================================================================*/
/// Get a hash value from just about anything.
///
/// - Parameter v: The item you want the hash of.
/// - Returns: The hash.
///
@inlinable public func HashOfAnything(_ v: Any) -> Int {
    if let x = (v as? AnyHashable) { return x.hashValue }
    else { return ObjectIdentifier(v as AnyObject).hashValue }
}

/*==============================================================================================================*/
/// Somewhat shorthand for:
/// ```
/// type(of: o) == t.self
/// ```
///
/// - Parameters:
///   - o: The instance to check the type of.
///   - t: The type to check for.
/// - Returns: `true` if the type of `o` is equal to `t`.
///
@inlinable public func isType<O, T>(_ o: O, _ t: T.Type) -> Bool { (type(of: o) == t) }

/*==============================================================================================================*/
/// A type alias for the closure used by `xferBytes(read:write:maxLength:bufferSize:)` to read bytes into an
/// intermediate buffer.
///
/// If successful the closure returns either the number of bytes put into the buffer or `nil` to indicate that the
/// End-of-Input has been reached and that there are no more bytes left to read. Returning a value of 0
/// (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) DOES NOT indicate that the End-of-Input has been
/// reached. Only returning `nil` will indicate the End-of-Input. This implies that returning a value of 0
/// (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) is a valid byte count that also indicates that there
/// are more bytes to be read. This way the closure can, for example, also be used to simply update a progress
/// indicator rather than returning any bytes.
///
/// The closure takes two parameters:
///
/// <table class="gsr">
///     <thead>
///         <tr>
///             <th align="left">Parameter</th>
///             <th align="left">Description</th>
///         </tr>
///     </thead>
///     <tbody>
///         <tr>
///             <td align="left"><code>BytePointer</code></td>
///             <td align="left">The buffer to read bytes into.</td>
///         </tr>
///         <tr>
///             <td align="left"><code>Int</code></td>
///             <td align="left">The maximum number of bytes the buffer can hold.</td>
///         </tr>
///     </tbody>
/// </table>
///
public typealias XferInClosure = (BytePointer, Int) throws -> Int?

/*==============================================================================================================*/
/// A type alias for the closure used by `xferBytes(read:write:maxLength:bufferSize:)` to write bytes from an
/// intermediate buffer.
///
/// If successful the closure returns either the number of bytes written from the buffer or `nil` to indicate that
/// the End-of-Output has been reached and that the output cannot receive anymore data. Returning a value of 0
/// (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) DOES NOT indicate that the End-of-Output has been
/// reached. Only returning `nil` will indicate the End-of-Output. This implies that returning a value of 0
/// (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) is a valid byte count that also indicates that more
/// bytes can be written. This way the closure can, for example, also be used to simply update a progress
/// indicator rather than writing any bytes.
///
/// The closure takes two parameters:
///
/// <table class="gsr">
///     <thead>
///         <tr>
///             <th align="left">Parameter</th>
///             <th align="left">Description</th>
///         </tr>
///     </thead>
///     <tbody>
///         <tr>
///             <td align="left"><code>ByteROPointer</code></td>
///             <td align="left">The buffer to write from.</td>
///         </tr>
///         <tr>
///             <td align="left"><code>Int</code></td>
///             <td align="left">The number of bytes in the buffer.</td>
///         </tr>
///     </tbody>
/// </table>
///
public typealias XferOutClosure = (ByteROPointer, Int) throws -> Int?

/*==============================================================================================================*/
/// Transfer bytes.
///
/// - Parameters:
///   - bufferSize: The maximum size of the buffer.
///   - maxLength: The maximum number of bytes to transfer.
///   - read: The closure to read a block of bytes into a buffer.
///   - write: The closure to write a block of bytes from a buffer.
/// - Returns: The actual number of bytes transfered.
/// - Throws: Any error thrown by either closure.
///
public func xferBytes(bufferSize: Int = 1_048_576, maxLength: Int, read: XferInClosure, write: XferOutClosure) rethrows -> Int {
    guard maxLength > 0 else { return 0 }

    let buffer = BytePointer.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    return try xferBytes(buffer: buffer, bufferSize: bufferSize, maxLength: maxLength, read: read, write: write)
}

public func xferBytes(buffer bf: BytePointer, bufferSize sz: Int, maxLength mx: Int, read: XferInClosure, write: XferOutClosure) rethrows -> Int {
    func _xferBytes_02(_ buffer: BytePointer, _ leftOverByteCount: Int, _ newLeftOverByteCount: inout Int, _ totalBytesCopied: inout Int, _ write: XferOutClosure) rethrows -> Bool {
        guard let bytesWritten = try write(buffer, leftOverByteCount) else { return false }
        totalBytesCopied += bytesWritten                                                         // update total so far
        newLeftOverByteCount = (leftOverByteCount - bytesWritten).clamp(0 ... leftOverByteCount) // update left over byte count
        if newLeftOverByteCount > 0 {
            MemMove(dest: buffer, src: (buffer + bytesWritten) as BytePointer, count: newLeftOverByteCount)
        }
        return true
    }

    var totalBytesCopied  = 0 // total so far
    var leftOverByteCount = 0 // left over bytes in buffer

    while totalBytesCopied < mx {
        guard let x = try read((bf + leftOverByteCount), min((mx - totalBytesCopied), (sz - leftOverByteCount))) else { break }
        guard try _xferBytes_02(bf, (leftOverByteCount + x), &leftOverByteCount, &totalBytesCopied, write) else { return totalBytesCopied }
    }

    while totalBytesCopied < mx && leftOverByteCount > 0 {
        guard try _xferBytes_02(bf, leftOverByteCount, &leftOverByteCount, &totalBytesCopied, write) else { break }
    }
    return totalBytesCopied
}

/// Convienience function for the C function `memmove`.
///
/// - Parameters:
///   - dest: The destination pointer.
///   - src: The source pointer.
///   - count: The number of bytes to move.
///
@inlinable public func MemMove(dest: BytePointer, src: ByteROPointer, count: Int) {
    memmove(UnsafeMutableRawPointer(dest), UnsafeRawPointer(src), count)
}
