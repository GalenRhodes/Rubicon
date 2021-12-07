/*******************************************************************************************************************************************************************************//*
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
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation

extension CharacterSet {

    /*==========================================================================================================*/
    /// A simple concatenation of the
    /// <code>[CharacterSet.whitespacesAndNewlines](https://developer.apple.com/documentation/foundation/characterset/1779801-whitespacesandnewlines)</code>
    /// and
    /// <code>[CharacterSet.controlCharacters](https://developer.apple.com/documentation/foundation/characterset/1779846-controlcharacters)</code>
    /// character sets.
    ///
    public static let whitespacesAndNewlinesAndControlCharacters: CharacterSet = CharacterSet.whitespacesAndNewlines.union(CharacterSet.controlCharacters)

    @inlinable public init(codePoints: Int...) {
        self.init(codePoints.map({ UnicodeScalar($0)! }))
    }

    @inlinable public init(codePointRanges: ClosedRange<Int>...) { self.init(codePointRanges: codePointRanges) }

    @inlinable public init(codePointRanges: [ClosedRange<Int>]) {
        self.init()
        codePointRanges.map({ (UnicodeScalar($0.lowerBound)! ... UnicodeScalar($0.upperBound)!) }).forEach({ insert(charactersIn: $0) })
    }

    @inlinable public init(codePointRanges: Range<Int>...) { self.init(codePointRanges: codePointRanges) }

    @inlinable public init(codePointRanges: [Range<Int>]) {
        self.init()
        codePointRanges.map({ (UnicodeScalar($0.lowerBound)! ..< UnicodeScalar($0.upperBound)!) }).forEach({ insert(charactersIn: $0) })
    }

    @inlinable public func union(codePoints: Int...) -> CharacterSet {
        union(CharacterSet(codePoints.map({ UnicodeScalar($0)! })))
    }

    @inlinable public func union(codePointRanges: ClosedRange<Int>...) -> CharacterSet {
        union(CharacterSet(codePointRanges: codePointRanges))
    }

    @inlinable public func union(codePointRanges: Range<Int>...) -> CharacterSet {
        union(CharacterSet(codePointRanges: codePointRanges))
    }
}
