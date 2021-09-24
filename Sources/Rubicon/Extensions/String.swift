/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: String.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 3/19/20
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

public typealias StringIndex = String.Index
public typealias StringRange = Range<StringIndex>

extension String {
//@f:0
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    @inlinable public var abbreviatingWithTildeInPath: String   { (self as NSString).abbreviatingWithTildeInPath }
    #endif
    @inlinable public var deletingLastPathComponent:   String   { (self as NSString).deletingLastPathComponent   }
    @inlinable public var deletingPathExtension:       String   { (self as NSString).deletingPathExtension       }
    @inlinable public var expandingTildeInPath:        String   { (self as NSString).expandingTildeInPath        }
    @inlinable public var isAbsolutePath:              Bool     { (self as NSString).isAbsolutePath              }
    @inlinable public var lastPathComponent:           String   { (self as NSString).lastPathComponent           }
    @inlinable public var pathComponents:              [String] { (self as NSString).pathComponents              }
    @inlinable public var pathExtension:               String   { (self as NSString).pathExtension               }
    @inlinable public var standardizingPath:           String   { (self as NSString).standardizingPath           }
//@f:1

    /*==========================================================================================================*/
    /// Allows creating a <code>[String](https://developer.apple.com/documentation/swift/string/)</code> from the
    /// contents of an
    /// <code>[InputStream](https://developer.apple.com/documentation/foundation/inputstream)</code>.
    /// 
    /// - Parameters:
    ///   - inputStream: The input stream.
    ///   - encoding: The encoding. Defaults to
    ///               <code>[String.Encoding.utf8](https://developer.apple.com/documentation/swift/string/encoding/1780106-utf8)</code>
    ///
    public init?(inputStream: InputStream, encoding: String.Encoding = String.Encoding.utf8) {
        guard let data = Data(inputStream: inputStream) else { return nil }
        self.init(data: data, encoding: encoding)
    }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// for _ in (0 ..< count) { aString.append(char) }
    /// ```
    /// 
    /// - Parameters:
    ///   - char: The character to append to this string.
    ///   - count: The number of times to append the character.
    ///
    @inlinable public mutating func append(_ char: Character, count: Int) { for _ in (0 ..< count) { append(char) } }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// for _ in (0 ..< count) { aString.insert(char, at: aString.startIndex) }
    /// ```
    /// 
    /// - Parameters:
    ///   - char: The character to prepend to the beginning of this string.
    ///   - count: The number of times to prepend the character.
    /// - Returns: The index of first character in the string BEFORE calling this method.
    ///
    @inlinable @discardableResult public mutating func prepend(_ char: Character, count: Int = 1) -> StringIndex {
        for _ in (0 ..< count) { insert(char, at: startIndex) }
        return (index(startIndex, offsetBy: count, limitedBy: endIndex) ?? endIndex)
    }

    /*==========================================================================================================*/
    /// Shorthand for:
    /// 
    /// ```
    /// aString.insert(contentsOf: aCollection, at: aString.startIndex)
    /// ```
    /// 
    /// - Parameter c: The collection of characters to prepend.
    /// - Returns: The index of first character in the string BEFORE calling this method.
    ///
    @inlinable @discardableResult public mutating func prepend<C>(contentsOf c: C) -> StringIndex where C: Collection, C.Element == Character {
        insert(contentsOf: c, at: startIndex)
        return (index(startIndex, offsetBy: c.count, limitedBy: endIndex) ?? endIndex)
    }

    @inlinable public static func path(withComponents components: [String]) -> String { NSString.path(withComponents: components) }

    @inlinable public func appendingPathComponent(_ str: String) -> String { (self as NSString).appendingPathComponent(str) }

    @inlinable public func appendingPathExtension(_ str: String) -> String {
        if let s = (self as NSString).appendingPathExtension(str) { return s }
        var c = pathComponents

        while let lpc = c.last {
            if lpc.isEmpty { c.removeLast(1) }
            else { return "\(String.path(withComponents: c)).\(str)" }
        }

        return ""
    }

    @inlinable public func absolutePath(relativeTo dir: String) -> String {
        guard dir.isAbsolutePath else { fatalError("Not an absolute path: \"\(dir)\"") }
        return (isAbsolutePath ? self : String.path(withComponents: [ dir, self ]).standardizingPath)
    }
}
