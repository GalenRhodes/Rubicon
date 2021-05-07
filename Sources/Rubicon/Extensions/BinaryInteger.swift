/*
 *     PROJECT: Rubicon
 *    FILENAME: BinaryInteger.swift
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

extension BinaryInteger {

    /*==========================================================================================================*/
    /// If the value is less than minValue then the minValue is returned. If the value is greater than maxValue
    /// then maxValue is returned. Otherwise this value is returned.
    /// 
    /// - Parameters:
    ///   - minValue: The minimum value.
    ///   - maxValue: The maximum value.
    /// - Returns: If the value is less than minValue then the minValue is returned. If the value is greater than
    ///            maxValue then maxValue is returned. Otherwise this value is returned.
    ///
    @inlinable public func clamp(minValue: Self, maxValue: Self) -> Self { max(min(self, maxValue), minValue) }

    @inlinable public func clamp(minValue: Self) -> Self { max(self, minValue) }

    @inlinable public func clamp(maxValue: Self) -> Self { min(self, maxValue) }

    @inlinable public func clamp(_ range: Range<Self>) -> Self { clamp(minValue: range.lowerBound, maxValue: (range.upperBound - 1)) }

    @inlinable public func inRange(_ range: Range<Self>) -> Bool { range.contains(self) }

    @inlinable public func inRange(_ range: ClosedRange<Self>) -> Bool { range.contains(self) }
}
