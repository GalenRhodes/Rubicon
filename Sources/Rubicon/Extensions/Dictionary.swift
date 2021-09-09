/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: Dictionary.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 7/1/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation

extension Dictionary {

    public func remapValues(_ body: (Key, Value) throws -> (Key, Value)) rethrows -> [Key:Value] {
        var out: [Key:Value] = [:]
        for (key, value) in self {
            let (k, v) = try body(key, value)
            out[k] = v
        }
        return out
    }
}

extension Dictionary where Key == FileAttributeKey, Value == Any {
//@f:0
    #if (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
        @inlinable public var fileCreationDate:          Date?     { (self as NSDictionary).fileCreationDate()          }
        @inlinable public var fileExtensionHidden:       Bool      { (self as NSDictionary).fileExtensionHidden()       }
        @inlinable public var fileGroupOwnerAccountID:   NSNumber? { (self as NSDictionary).fileGroupOwnerAccountID()   }
        @inlinable public var fileGroupOwnerAccountName: String?   { (self as NSDictionary).fileGroupOwnerAccountName() }
        @inlinable public var fileHFSCreatorCode:        OSType    { (self as NSDictionary).fileHFSCreatorCode()        }
        @inlinable public var fileHFSTypeCode:           OSType    { (self as NSDictionary).fileHFSTypeCode()           }
        @inlinable public var fileIsAppendOnly:          Bool      { (self as NSDictionary).fileIsAppendOnly()          }
        @inlinable public var fileIsImmutable:           Bool      { (self as NSDictionary).fileIsImmutable()           }
        @inlinable public var fileModificationDate:      Date?     { (self as NSDictionary).fileModificationDate()      }
        @inlinable public var fileOwnerAccountID:        NSNumber? { (self as NSDictionary).fileOwnerAccountID()        }
        @inlinable public var fileOwnerAccountName:      String?   { (self as NSDictionary).fileOwnerAccountName()      }
        @inlinable public var filePosixPermissions:      Int       { (self as NSDictionary).filePosixPermissions()      }
        @inlinable public var fileSize:                  UInt64    { (self as NSDictionary).fileSize()                  }
        @inlinable public var fileSystemFileNumber:      Int       { (self as NSDictionary).fileSystemFileNumber()      }
        @inlinable public var fileSystemNumber:          Int       { (self as NSDictionary).fileSystemNumber()          }
    #else
        @inlinable public var fileCreationDate:          Date?     { when(self[FileAttributeKey.creationDate],          isNil: nil) { $0 as? Date     }          }
        @inlinable public var fileExtensionHidden:       Bool      { when(self[FileAttributeKey.extensionHidden],       isNil: nil) { $0 as? Bool     } ?? false }
        @inlinable public var fileGroupOwnerAccountID:   NSNumber? { when(self[FileAttributeKey.groupOwnerAccountID],   isNil: nil) { $0 as? NSNumber }          }
        @inlinable public var fileGroupOwnerAccountName: String?   { when(self[FileAttributeKey.groupOwnerAccountName], isNil: nil) { $0 as? String   }          }
        @inlinable public var fileHFSCreatorCode:        OSType    { when(self[FileAttributeKey.hfsCreatorCode],        isNil: nil) { $0 as? OSType   } ?? 0     }
        @inlinable public var fileHFSTypeCode:           OSType    { when(self[FileAttributeKey.hfsTypeCode],           isNil: nil) { $0 as? OSType   } ?? 0     }
        @inlinable public var fileIsAppendOnly:          Bool      { when(self[FileAttributeKey.appendOnly],            isNil: nil) { $0 as? Bool     } ?? false }
        @inlinable public var fileIsImmutable:           Bool      { when(self[FileAttributeKey.immutable],             isNil: nil) { $0 as? Bool     } ?? false }
        @inlinable public var fileModificationDate:      Date?     { when(self[FileAttributeKey.modificationDate],      isNil: nil) { $0 as? Date     }          }
        @inlinable public var fileOwnerAccountID:        NSNumber? { when(self[FileAttributeKey.ownerAccountID],        isNil: nil) { $0 as? NSNumber }          }
        @inlinable public var fileOwnerAccountName:      String?   { when(self[FileAttributeKey.ownerAccountName],      isNil: nil) { $0 as? String   }          }
        @inlinable public var filePosixPermissions:      Int       { when(self[FileAttributeKey.posixPermissions],      isNil: nil) { $0 as? Int      } ?? 0     }
        @inlinable public var fileSize:                  UInt64    { when(self[FileAttributeKey.size],                  isNil: nil) { $0 as? UInt64   } ?? 0     }
        @inlinable public var fileSystemFileNumber:      Int       { when(self[FileAttributeKey.systemFileNumber],      isNil: nil) { $0 as? Int      } ?? 0     }
        @inlinable public var fileSystemNumber:          Int       { when(self[FileAttributeKey.systemNumber],          isNil: nil) { $0 as? Int      }          }
    #endif
//@f:1

    @inlinable public var fileType: FileAttributeType {
        guard let t = (self[.type] as? String) else { return .typeUnknown }
        switch t {
            case FileAttributeType.typeBlockSpecial.rawValue:     return .typeBlockSpecial
            case FileAttributeType.typeDirectory.rawValue:        return .typeDirectory
            case FileAttributeType.typeRegular.rawValue:          return .typeRegular
            case FileAttributeType.typeSymbolicLink.rawValue:     return .typeSymbolicLink
            case FileAttributeType.typeSocket.rawValue:           return .typeSocket
            case FileAttributeType.typeCharacterSpecial.rawValue: return .typeCharacterSpecial
            default:                                              return .typeUnknown
        }
    }
}

