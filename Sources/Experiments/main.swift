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
import Rubicon

let projectPath:     String = "/Users/grhodes/Projects/SwiftProjects/Rubicon"
let sourcePath:      String = "\(projectPath)/Sources/Rubicon"
let stringsFile:     String = "StringsFile.swift"
let stringsFilePath: String = "\(sourcePath)/\(stringsFile)"

func doIt() throws {
    let propKeys:   [URLResourceKey]  = [ .nameKey, .pathKey, .isDirectoryKey, .parentDirectoryURLKey ]
    let fm:         FileManager       = FileManager.default
    var enc:        String.Encoding   = .ascii
    let regex1:     RegularExpression = try RegularExpression(pattern: "^public\\s+let\\s+(\\w+)\\:\\s*String\\s*\\=\\s*\".*?\"$", options: [ .anchorsMatchLines ])
    var stringsOut: String            = try String(contentsOf: URL(filePath: stringsFilePath), usedEncoding: &enc)

    for case let fileURL as URL in fm.enumerator(at: URL(filePath: sourcePath), includingPropertiesForKeys: propKeys)! {
        do {
            let resVals = try fileURL.resourceValues(forKeys: Set<URLResourceKey>(propKeys))
            guard let name = resVals.name, let isDirectory = resVals.isDirectory, !isDirectory, name.hasSuffix(".swift") else { continue }
            guard name != stringsFile else { continue }

            var data:    String      = try String(contentsOf: fileURL, usedEncoding: &enc).trimmed
            var last:    StringIndex = data.startIndex
            var out:     String      = ""
            var changed: Bool        = false

            regex1.enumerateMatches(in: data) { m, _, _ in
                guard let m = m else { return }
                out.append(contentsOf: data[last ..< m.range.lowerBound])
                last = m.range.upperBound
                stringsOut.append(contentsOf: "\n")
                stringsOut.append(contentsOf: m.substring)
                changed = true
            }

            out.append(contentsOf: data[last...])

            guard changed else { continue }

            try out.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch let e {
            print("ERROR: \(e)", to: &ErrorOutput.errorOut)
        }
    }

    try stringsOut.write(to: URL(filePath: stringsFilePath), atomically: false, encoding: .utf8)
}

DispatchQueue.main.async {
    do {
        try doIt()
        exit(0)
    }
    catch let e {
        print("ERROR: \(e)", to: &ErrorOutput.errorOut)
    }
}
dispatchMain()
