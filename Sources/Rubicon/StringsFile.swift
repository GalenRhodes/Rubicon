// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: StringsFile.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: December 29, 2022
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

public let ErrMsgCannotRotate:        String = "ERROR: No %@ node - cannot rotate %@."
public let ErrMsgIllegalAction:       String = "ERROR: Illegal Action."
public let ErrMsgInconsistentState:   String = "ERROR: %@ Inconsistent State"
public let ErrMsgIndexOutOfBounds:    String = "ERROR: Index out of bounds."
public let ErrMsgInsufficientMemory:  String = "ERROR: Insufficient Memory."
public let ErrMsgInternalError:       String = "ERROR: Internal Error"
public let ErrMsgInvalidRange:        String = "ERROR: Invalid Range"
public let ErrMsgNoMain:              String = "ERROR: main() not implemented and no closure provided."
public let ErrMsgNotImplemented:      String = "ERROR: Not Implemented."
public let ErrMsgNoValue:             String = "ERROR: No value."
public let ErrMsgUnableToCreateLock:  String = "ERROR: Unable to create %@ lock: %@"
public let ErrMsgUnableToObtainLock:  String = "ERROR: Unable to obtain %@ lock: %@"
public let ErrMsgUnknownError:        String = "ERROR: %@"
public let ErrMsgWindowsNotSupported: String = "ERROR: Windows is not yet supported."

public let ErrDescDeadLock:                 String = "[EDEADLK] A deadlock has occurred."
public let ErrDescInsufficientMemory:       String = "[ENOMEM] Insufficient memory."
public let ErrDescInsufficientPermissions:  String = "[EPERM] Insufficient permissions."
public let ErrDescInsufficientResources:    String = "[EAGAIN] Insufficient resources."
public let ErrDescLockOwnedByAnotherThread: String = "[EBUSY] The lock is currently owned by another thread."
public let ErrDescUnknownError:             String = "[%d] Unknown Error."

public let StrIConvIgnore:        String = "//IGNORE"
public let StrIConvTranslit:      String = "//TRANSLIT"
public let StrLeft:               String = "left"
public let StrRight:              String = "right"
public let StrNeither:            String = "neither"
public let StrRead:               String = "read"
public let StrReadWrite:          String = "read/write"
public let StrWrite:              String = "write"
public let StrRedBlackDictionary: String = "RedBlackDictionary"
public let StrUTF8:               String = "UTF-8"

public let MsgInvalidPattern: String = "Invalid Pattern"
