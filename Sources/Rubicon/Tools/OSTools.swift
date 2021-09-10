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
/// Which
/// 
/// - Parameter names: The programs to look for.
/// - Returns: The paths to the programs. If any program couldn't be found then that entry is `nil`.
///
public func which(names: [String]) -> [String?] {
    let ncc: Int = names.count
    guard ncc > 0 else { return [] }

    var txt: String    = ""
    var err: String    = ""
    var out: [String?] = []

    for n in names {
        if n.hasAnyPrefix("/", "-") {
            out <+ nil
        }
        else {
            #if os(Windows)
                let result: Int = execute(exec: "where", args: [ n ], stdout: &txt, stderr: &err)
            #else
                let result: Int = execute(exec: "/bin/bash", args: [ "-c", "which \"\(n)\"" ], stdout: &txt, stderr: &err)
            #endif
            if result == 0 {
                let item: String = txt.split(on: "\\R")[0]
                out <+ (item.trimmed.isEmpty ? nil : item)
            }
            else {
                out <+ nil
            }
        }
    }

    return out
}

/*==============================================================================================================*/
/// Which
/// 
/// - Parameter name: The program to look for.
/// - Returns: The path to the program or `nil` if it couldn't be found.
///
@inlinable public func which(name: String) -> String? { which(names: [ name ])[0] }
