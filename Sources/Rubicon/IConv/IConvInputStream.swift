// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: IConvInputStream.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 09, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

public class IConvInputStream: FilteredInputStream {
    public override var streamStatus:      Status { super.streamStatus }
    public override var streamError:       Error? { super.streamError }
    public override var hasBytesAvailable: Bool { super.hasBytesAvailable }

    public override init(inputStream: InputStream) { super.init(inputStream: inputStream) }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int { super.read(buffer, maxLength: len) }

    public override func open() { super.open() }

    public override func close() { super.close() }
}
