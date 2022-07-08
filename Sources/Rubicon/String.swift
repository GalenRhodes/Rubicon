/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: String.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: July 08, 2022
 *
 * Copyright © 2022 Project Galen. All rights reserved.
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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

extension CharacterSet {

    /// Shorthand for `.whitespacesAndNewlines.union(.controlCharacters)`.
    public static let whitespacesAndNewlinesAndControlCharacters: CharacterSet = .whitespacesAndNewlines.union(.controlCharacters)

    public func satisfies(character ch: Character) -> Bool { ch.unicodeScalars.allSatisfy { contains($0) } }

    public func satisfies(string str: String) -> Bool { str.unicodeScalars.allSatisfy { contains($0) } }
}

extension String {

    /// Shorthand for `startIndex ..< endIndex`.
    public var allRange: Range<String.Index> { startIndex ..< endIndex }

    public var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlinesAndControlCharacters) }

    public var leftTrimmed: String { whenNotNil(firstIndex { !CharacterSet.whitespacesAndNewlinesAndControlCharacters.satisfies(character: $0) }) { String(self[$0...]) } else: { "" } }

    public var rightTrimmed: String { "" }
}
