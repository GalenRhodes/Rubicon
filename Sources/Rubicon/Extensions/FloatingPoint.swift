/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: FloatingPoint.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/10/21
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

extension BinaryFloatingPoint {

    @inlinable public static func ** (lhs: Self, rhs: Int) -> Self {
        guard rhs != 0 else { return Self(1.0) }
        guard rhs != 1 else { return lhs }
        var out: Self = lhs
        if rhs > 1 { for _ in (1 ..< rhs) { out *= lhs } }
        else { for _ in (0 ..< abs(rhs)) { out /= lhs } }
        return out
    }

    @inlinable public func roundTo(places: Int) -> Self {
        guard !(isNaN || isInfinite) else { return self }
        let i = (Self(10) ** places)
        return (Self(Int((self * i) + Self(0.5))) / i)
    }
}
