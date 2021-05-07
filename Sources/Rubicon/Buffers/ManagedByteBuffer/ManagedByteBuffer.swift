/*
 *     PROJECT: Rubicon
 *    FILENAME: ManagedByteBuffer.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/15/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*============================================================================================================================================================================*/

import Foundation
import CoreFoundation

public protocol ManagedByteBuffer {
    /*==========================================================================================================*/
    /// The total length of the buffer in bytes.
    ///
    var length: Int { get }
    /*==========================================================================================================*/
    /// This is an index that can be used to indicate the number valid bytes in the buffer starting at the
    /// beginning of the buffer. The methods in this protocol will all assume that count is used for that purpose
    /// and will be updated accordingly.
    ///
    var count:  Int { get set }

    @discardableResult func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeBufferPointer<T>, inout Int) throws -> V) rethrows -> V

    @discardableResult func withBufferAs<T, V>(type: T.Type, _ body: (UnsafePointer<T>, inout Int) throws -> V) rethrows -> V

    @discardableResult func withBytes<V>(_ body: (UnsafePointer<UInt8>, inout Int) throws -> V) rethrows -> V

    @discardableResult func withBytes<V>(_ body: (UnsafeBufferPointer<UInt8>, inout Int) throws -> V) rethrows -> V
}

public protocol MutableManagedByteBuffer: ManagedByteBuffer {

    @discardableResult func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutablePointer<T>, Int, inout Int) throws -> V) rethrows -> V

    @discardableResult func withBufferAs<T, V>(type: T.Type, _ body: (UnsafeMutableBufferPointer<T>, inout Int) throws -> V) rethrows -> V

    @discardableResult func withBytes<V>(_ body: (UnsafeMutablePointer<UInt8>, Int, inout Int) throws -> V) rethrows -> V

    /*==========================================================================================================*/
    /// Executes the given closure with an UnsafeMutableBufferPointer representing the buffer.
    /// 
    /// - Parameter body: The closure which takes two parameters: <ol><li>The instance of
    ///                                                           UnsafeMutableBufferPointer</li><li>The count of
    ///                                                           the valid bytes in the buffer passed by
    ///                                                           reference.</li></ol>
    /// - Returns: The value returned by the closure.
    /// - Throws: Any error thrown by the closure.
    ///
    @discardableResult func withBytes<V>(_ body: (UnsafeMutableBufferPointer<UInt8>, inout Int) throws -> V) rethrows -> V

    /*==========================================================================================================*/
    /// Relocates a block of bytes to the beginning of the buffer region. The number of bytes relocated will be
    /// from the given index to the end of the buffer.
    /// 
    /// - Parameter idx: the index of the first byte of the block of bytes to move to the beginning of the buffer.
    /// - Returns: The number of bytes moved.
    ///
    func relocateToFront(start idx: Int) -> Int

    /*==========================================================================================================*/
    /// Relocates a block of bytes to the beginning of the buffer region.
    /// 
    /// - Parameters:
    ///   - idx: The index of the first byte of the block of bytes to move to the beginning of the buffer.
    ///   - cc: The number of bytes.
    ///
    func relocateToFront(start idx: Int, count cc: Int)
}
