// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Date.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: July 09, 2022
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

extension Date {
    #if os(Windows)
    @inlinable public func futureTimeSpec() -> DWORD? {
        let t = timeIntervalSinceNow
        guard t > 0 else { return nil }
        return DWORD(t * 1_000_000_000.0)
    }

    #else
    @inlinable public func futureTimeSpec() -> timespec? {
        return ((timeIntervalSinceNow > 0) ? absoluteTimeSpec() : nil)
    }

    @inlinable public func absoluteTimeSpec() -> timespec {
        let t = timeIntervalSince1970
        return timespec(tv_sec: Int(t), tv_nsec: Int(t.fraction() * 1_000_000_000.0))
    }
    #endif
}
