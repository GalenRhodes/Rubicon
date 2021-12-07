/*=================================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: Character.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 11/10/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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
 *===============================================================================================================================================================================*/

import Foundation

/*==============================================================================================================*/
/// This special character is used as a replacement when an invalid Unicode code point is encountered.
///
public let UnicodeReplacementChar:   Character     = "�"
public let UnicodeReplacementScalar: UnicodeScalar = UnicodeScalar(0xFFFD)!

extension Character {
    /*==========================================================================================================*/
    /// Creates a new `Character` from the given UTF-32 code point.
    ///
    /// - Parameter codePoint: the code point.
    ///
    public init(codePoint: UInt32) {
        self.init(scalar: UnicodeScalar(codePoint))
    }

    /*==========================================================================================================*/
    /// Creates a new `Character` from the given `UnicodeScalar`. If the scalar is `nil` then an instance of the
    /// `UnicodeReplacementChar` (�) will be created.
    ///
    /// - Parameter s: the Unicode Scalar.
    ///
    public init(scalar s: UnicodeScalar?) {
        self.init(s ?? UnicodeReplacementScalar)
    }
}
