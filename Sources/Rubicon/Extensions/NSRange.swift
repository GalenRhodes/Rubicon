/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: NSRange.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/4/20
 *
 * Copyright © 2020 ProjectGalen. All rights reserved.
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

/*===============================================================================================================================================================================*/
/// Extensions to <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code>
///
public extension NSRange {
    /*===========================================================================================================================================================================*/
    /// Converts this <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> into a
    /// [Range](https://developer.apple.com/documentation/swift/range)&lt;[String.Index](https://developer.apple.com/documentation/swift/string/index)&gt; for the given
    /// <code>[String](https://developer.apple.com/documentation/swift/string)</code>. Returns `nil` if this
    /// <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> is not valid for the given
    /// [String](https://developer.apple.com/documentation/swift/string)</code>.
    /// 
    /// - Parameter string: the <code>[String](https://developer.apple.com/documentation/swift/string)</code>.
    /// - Returns: the slice range for the given string based on this <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> or `nil` if this
    ///            <code>[NSRange](https://developer.apple.com/documentation/foundation/nsrange)</code> is not valid.
    ///
    func strRange(string: String) -> Range<String.Index>? {
        Range<String.Index>(self, in: string)
    }

}
