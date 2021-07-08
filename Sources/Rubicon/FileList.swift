/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: FileList.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/25/21
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

public enum FilePathError: Error {
    case RecursiveSymLink(path: String)
    case BadSymLink(path: String)
    case FilenameEncoding(path: String)
}

extension Dictionary where Key == FileAttributeKey, Value == Any {
//@f:0
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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
        @inlinable public var fileCreationDate:          Date?     { (self[FileAttributeKey.creationDate]          as? Date)              }
        @inlinable public var fileExtensionHidden:       Bool      { (self[FileAttributeKey.extensionHidden]       as? Bool)     ?? false }
        @inlinable public var fileGroupOwnerAccountID:   NSNumber? { (self[FileAttributeKey.groupOwnerAccountID]   as? NSNumber)          }
        @inlinable public var fileGroupOwnerAccountName: String?   { (self[FileAttributeKey.groupOwnerAccountName] as? String)            }
        @inlinable public var fileHFSCreatorCode:        OSType    { (self[FileAttributeKey.hfsCreatorCode]        as? OSType)            }
        @inlinable public var fileHFSTypeCode:           OSType    { (self[FileAttributeKey.hfsTypeCode]           as? OSType)            }
        @inlinable public var fileIsAppendOnly:          Bool      { (self[FileAttributeKey.appendOnly]            as? Bool)     ?? false }
        @inlinable public var fileIsImmutable:           Bool      { (self[FileAttributeKey.immutable]             as? Bool)     ?? false }
        @inlinable public var fileModificationDate:      Date?     { (self[FileAttributeKey.modificationDate]      as? Date)              }
        @inlinable public var fileOwnerAccountID:        NSNumber? { (self[FileAttributeKey.ownerAccountID]        as? NSNumber)          }
        @inlinable public var fileOwnerAccountName:      String?   { (self[FileAttributeKey.ownerAccountName]      as? String)            }
        @inlinable public var filePosixPermissions:      Int       { (self[FileAttributeKey.posixPermissions]      as? Int)      ?? 0     }
        @inlinable public var fileSize:                  UInt64    { (self[FileAttributeKey.size]                  as? UInt64)   ?? 0     }
        @inlinable public var fileSystemFileNumber:      Int       { (self[FileAttributeKey.systemFileNumber]      as? Int)      ?? 0     }
        @inlinable public var fileSystemNumber:          Int       { (self[FileAttributeKey.systemNumber]          as? Int)      ?? 0     }
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

extension FileManager {

//@f:0
    @inlinable public func fileCreationDate(atPath: String)          throws -> Date?             { try attributesOfItem(atPath: atPath).fileCreationDate          }
    @inlinable public func fileExtensionHidden(atPath: String)       throws -> Bool              { try attributesOfItem(atPath: atPath).fileExtensionHidden       }
    @inlinable public func fileGroupOwnerAccountID(atPath: String)   throws -> NSNumber?         { try attributesOfItem(atPath: atPath).fileGroupOwnerAccountID   }
    @inlinable public func fileGroupOwnerAccountName(atPath: String) throws -> String?           { try attributesOfItem(atPath: atPath).fileGroupOwnerAccountName }
    @inlinable public func fileHFSCreatorCode(atPath: String)        throws -> OSType            { try attributesOfItem(atPath: atPath).fileHFSCreatorCode        }
    @inlinable public func fileHFSTypeCode(atPath: String)           throws -> OSType            { try attributesOfItem(atPath: atPath).fileHFSTypeCode           }
    @inlinable public func fileIsAppendOnly(atPath: String)          throws -> Bool              { try attributesOfItem(atPath: atPath).fileIsAppendOnly          }
    @inlinable public func fileIsImmutable(atPath: String)           throws -> Bool              { try attributesOfItem(atPath: atPath).fileIsImmutable           }
    @inlinable public func fileModificationDate(atPath: String)      throws -> Date?             { try attributesOfItem(atPath: atPath).fileModificationDate      }
    @inlinable public func fileOwnerAccountID(atPath: String)        throws -> NSNumber?         { try attributesOfItem(atPath: atPath).fileOwnerAccountID        }
    @inlinable public func fileOwnerAccountName(atPath: String)      throws -> String?           { try attributesOfItem(atPath: atPath).fileOwnerAccountName      }
    @inlinable public func filePosixPermissions(atPath: String)      throws -> Int               { try attributesOfItem(atPath: atPath).filePosixPermissions      }
    @inlinable public func fileSize(atPath: String)                  throws -> UInt64            { try attributesOfItem(atPath: atPath).fileSize                  }
    @inlinable public func fileSystemFileNumber(atPath: String)      throws -> Int               { try attributesOfItem(atPath: atPath).fileSystemFileNumber      }
    @inlinable public func fileSystemNumber(atPath: String)          throws -> Int               { try attributesOfItem(atPath: atPath).fileSystemNumber          }
    @inlinable public func fileType(atPath: String)                  throws -> FileAttributeType { try attributesOfItem(atPath: atPath).fileType                  }
//@f:1

    /*==========================================================================================================*/
    /// Get a list of file from a directory.
    ///
    /// - Parameters:
    ///   - atPath: The directory to get the list of files from.
    ///   - resolveSymLinks: If `true` then any symbolic links found will be resolved before being sent to the the
    ///                      closure. The default is `false`.
    ///   - traverseDirectorySymLinks: If `true` AND resolveSymLinks is `true` then any symbolic links that point
    ///                                to a directory will have those directories traversed.
    ///   - body: The closure that gets called for each file and directory found. The closure takes three
    ///           parameters - the full pathname, the filename, and a Dictionary containing the file attributes.
    /// - Returns: An array of full filenames.
    /// - Throws: If an I/O error occurs or if the closure throws an error.
    ///
    public func directoryFiles(atPath: String, resolveSymLinks: Bool = false, traverseDirectorySymLinks: Bool = false, where body: (String, String, [FileAttributeKey: Any]) throws -> Bool) throws -> [String] {
        var files = Array<String>()
        let cwd   = atPath.absolutePath(relativeTo: currentDirectoryPath)

        if let fEnum: FileManager.DirectoryEnumerator = enumerator(atPath: cwd) {
            while let filename = fEnum.nextObject() as? String {
                let fAttribs = (fEnum.fileAttributes ?? [:])

                if resolveSymLinks && fAttribs.fileType == FileAttributeType.typeSymbolicLink {
                    if let _filename = try? realPath(path: filename.absolutePath(relativeTo: cwd)) {
                        let _fAttribs = try attributesOfItem(atPath: _filename)
                        if try body(_filename.deletingLastPathComponent, _filename.lastPathComponent, _fAttribs) { files <+ _filename }
                        if traverseDirectorySymLinks && _fAttribs.fileType == .typeDirectory { files += try directoryFiles(atPath: _filename, where: body) }
                    }
                }
                else {
                    let cFile = String.path(withComponents: cwd.pathComponents + filename.pathComponents)
                    if try body(cFile.deletingLastPathComponent, cFile.lastPathComponent, fAttribs) { files <+ cFile }
                }
            }
        }

        return files
    }

    /*==========================================================================================================*/
    /// Recursively resolve a symbolic link.
    ///
    /// This method resolves all symbolic links, extra `/` characters, and references to `.` and `..` in `path`.
    /// It will resolve both absolute and relative paths and return the absolute pathname corresponding to `path`.
    /// All components of `path` must exist when this method is called.
    ///
    /// This method behaves like the [Linux readlink
    /// utility](https://man7.org/linux/man-pages/man1/readlink.1.html) when using the `--canonicalize-existing`
    /// flag.
    ///
    /// - Parameter path: The path to resolve.
    /// - Returns: The resolved file.
    /// - Throws: If an I/O error occurs or if one of the symbolic link components is broken.
    ///
    @inlinable public func realPath(path: String) throws -> String {
        let b = UnsafeMutablePointer<CChar>.allocate(capacity: Int(truncatingIfNeeded: PATH_MAX))
        defer { b.deallocate() }
        guard realpath(path, b) != nil else { throw FilePathError.BadSymLink(path: String(cString: b, encoding: .utf8) ?? path) }
        guard let s = String(cString: b, encoding: .utf8) else { throw FilePathError.FilenameEncoding(path: path) }
        return s
    }
}
