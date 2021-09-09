/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/8/21
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
#if os(Windows)
    import WinSDK
#endif

/*==============================================================================================================*/
/// A good size for a basic buffer.
///
public let BasicBufferSize: Int = 4096

/*==============================================================================================================*/
/// Read the data from a Pipe and return it as a string.
///
/// - Parameters:
///   - pipe: The pipe to read from.
///   - encoding: The encoding. Defaults to `UTF-8`.
/// - Returns: The string or `nil` if the encoding failed.
///
@inlinable public func readFromPipe(pipe: Pipe, encoding: String.Encoding = .utf8) -> String? { String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: encoding) }
