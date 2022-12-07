// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: IConvError.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 05, 2022
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

public enum IConvError: Error, Equatable {
    case NoAvailableFileDescriptors
    case TooManyFilesOpen
    case InsufficientMemory
    case UnknownCharacterEncoding
    case InvalidInputBuffer
    case InvalidOutputBuffer
    case IconvExecutableNotFound
    case IllegalMultiByteSequence
    case InvalidCharacterForEncoding
    case OutputBufferTooSmall
    case UnknownError(code: Int32)
}

extension IConvError {
    @inlinable static func encodingError(result r: Int, code e: Int32) -> IConvError? {
        guard r == -1 else { return nil }
        switch e {
            case E2BIG:  return .OutputBufferTooSmall
            case EINVAL: return .InvalidCharacterForEncoding
            case EILSEQ: return .IllegalMultiByteSequence
            default:     return .UnknownError(code: e)
        }
    }
}
