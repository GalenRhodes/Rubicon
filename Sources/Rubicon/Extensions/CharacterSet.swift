/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: CharacterSet.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/11/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

extension CharacterSet {

    /*==========================================================================================================================================================================*/
    /// A simple concatenation of the
    /// <code>[CharacterSet.whitespacesAndNewlines](https://developer.apple.com/documentation/foundation/characterset/1779801-whitespacesandnewlines)</code>
    /// and
    /// <code>[CharacterSet.controlCharacters](https://developer.apple.com/documentation/foundation/characterset/1779846-controlcharacters)</code>
    /// character sets.
    ///
    public static let whitespacesAndNewlinesAndControlCharacters: CharacterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet.controlCharacters)

    @inlinable public init(codePoints: Int...) {
        self.init(codePoints: codePoints)
    }

    @inlinable public init(codePoints: [Int]) {
        self.init(codePoints.compactMap { UnicodeScalar($0) })
    }

    @inlinable public init(codePointRanges: ClosedRange<Int>...) {
        self.init(codePointRanges: codePointRanges)
    }

    @inlinable public init(codePointRanges: [ClosedRange<Int>]) {
        self.init(codePointRanges.flatMap { (r) -> [UnicodeScalar] in r.compactMap { (i) -> UnicodeScalar? in UnicodeScalar(i) } })
    }

    @inlinable public init(codePointRanges: Range<Int>...) {
        self.init(codePointRanges: codePointRanges)
    }

    @inlinable public init(codePointRanges: [Range<Int>]) {
        self.init(codePointRanges.flatMap { (r) -> [UnicodeScalar] in r.compactMap { (i) -> UnicodeScalar? in UnicodeScalar(i) } })
    }

    @inlinable public func union(codePoints: Int...) -> CharacterSet {
        union(CharacterSet(codePoints: codePoints))
    }

    @inlinable public func union(codePointRanges: ClosedRange<Int>...) -> CharacterSet {
        union(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func union(codePointRanges: Range<Int>...) -> CharacterSet {
        union(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func formUnion(codePoints: Int...) {
        formUnion(CharacterSet(codePoints: codePoints))
    }

    @inlinable public mutating func formUnion(codePointRanges: ClosedRange<Int>...) {
        formUnion(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func formUnion(codePointRanges: Range<Int>...) {
        formUnion(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func intersection(codePoints: Int...) -> CharacterSet {
        intersection(CharacterSet(codePoints: codePoints))
    }

    @inlinable public func intersection(codePointRanges: ClosedRange<Int>...) -> CharacterSet {
        intersection(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func intersection(codePointRanges: Range<Int>...) -> CharacterSet {
        intersection(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func formIntersection(codePoints: Int...) {
        formIntersection(CharacterSet(codePoints: codePoints))
    }

    @inlinable public mutating func formIntersection(codePointRanges: ClosedRange<Int>...) {
        formIntersection(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func formIntersection(codePointRanges: Range<Int>...) {
        formIntersection(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func subtracting(codePoints: Int...) -> CharacterSet {
        subtracting(CharacterSet(codePoints: codePoints))
    }

    @inlinable public func subtracting(codePointRanges: ClosedRange<Int>...) -> CharacterSet {
        subtracting(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func subtracting(codePointRanges: Range<Int>...) -> CharacterSet {
        subtracting(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func subtract(codePoints: Int...) {
        subtract(CharacterSet(codePoints: codePoints))
    }

    @inlinable public mutating func subtract(codePointRanges: ClosedRange<Int>...) {
        subtract(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func subtract(codePointRanges: Range<Int>...) {
        subtract(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func symmetricDifference(codePoints: Int...) -> CharacterSet {
        symmetricDifference(CharacterSet(codePoints: codePoints))
    }

    @inlinable public func symmetricDifference(codePointRanges: ClosedRange<Int>...) -> CharacterSet {
        symmetricDifference(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func symmetricDifference(codePointRanges: Range<Int>...) -> CharacterSet {
        symmetricDifference(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func formSymmetricDifference(codePoints: Int...) {
        formSymmetricDifference(CharacterSet(codePoints: codePoints))
    }

    @inlinable public mutating func formSymmetricDifference(codePointRanges: ClosedRange<Int>...) {
        formSymmetricDifference(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public mutating func formSymmetricDifference(codePointRanges: Range<Int>...) {
        formSymmetricDifference(CharacterSet(codePointRanges: codePointRanges))
    }
}
