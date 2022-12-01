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

struct Test: Hashable {
    let a: String

    init(_ a: String) {
        self.a = a
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(a)
    }

    static func == (lhs: Test, rhs: Test) -> Bool {
        if lhs.a != rhs.a { return false }
        return true
    }
}

func doIt() {
    let s1 = Test("Galen")
    let s2 = Test("Rhodes")
    let o1 = s1 as AnyObject
    let o2 = s2 as AnyObject

    print("\(s1.hashValue)")
    print("\(s2.hashValue)")
    print("\(ObjectIdentifier(o1).hashValue)")
    print("\(ObjectIdentifier(o2).hashValue)")
}

DispatchQueue.main.async {
    doIt()
    exit(0)
}
dispatchMain()
