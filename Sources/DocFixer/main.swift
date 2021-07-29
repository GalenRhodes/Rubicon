//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 3/26/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import PGDocFixer

DispatchQueue.main.async {
    let mAndR: [RegexRepl] = [
        RegexRepl(pattern: "(?<!\\w|`)(nil)(?!\\w|`)", repl: "`$1`"),
        RegexRepl(pattern: "(?<!\\w|`)(\\w+(?:\\.\\w+)*\\([^)]*\\))(?!\\w|`)", repl: "`$1`"),
        RegexRepl(pattern: "(?<!\\w|\\[)([Zz][Ee][Rr][Oo])(?!\\w|\\])", repl: "<code>[$1](https://en.wikipedia.org/wiki/0)</code>")
    ]
    exit(Int32(doDocFixer(args: CommandLine.arguments, replacements: mAndR)))
}
dispatchMain()
