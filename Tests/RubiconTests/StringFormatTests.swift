/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: StringFormatTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/26/21
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
import XCTest
@testable import Rubicon

public class StringFormatTests: XCTestCase {
    typealias T1 = (prefix: String, spec: String, groups: [String?])
    typealias T2 = (format: String, body: [T1], suffix: String)

    let Bar1:        String = "============================================================================================================================"
    let Bar2:        String = "----------------------------------------------------------------------------------------------------------------------------"

    //@f:0
    let TestFormats: [T2] = [
        (format: "[ Kind: %-11s; %s ]",
         body: [ (prefix: "[ Kind: ", spec: "%-11s",  groups: [ "%-11s",  "-11s",  nil, nil, "-", "11", nil, "s", nil, ]),
                 (prefix: "; ",       spec: "%s",     groups: [ "%s",     "s",     nil, nil, "",  nil,  nil, "s", nil, ]) ],
         suffix: " ]"),
        (format: "[ Kind: %11s; %s ]",
         body: [ (prefix: "[ Kind: ", spec: "%11s",   groups: [ "%11s",   "11s",   nil, nil, "",  "11", nil, "s", nil, ]),
                 (prefix: "; ",       spec: "%s",     groups: [ "%s",     "s",     nil, nil, "",  nil,  nil, "s", nil, ]) ],
         suffix: " ]"),
        (format: "[ Kind: %-11s; %.5s ]",
         body: [ (prefix: "[ Kind: ", spec: "%-11s",  groups: [ "%-11s",  "-11s",  nil, nil, "-", "11", nil, "s", nil, ]),
                 (prefix: "; ",       spec: "%.5s",   groups: [ "%.5s",  ".5s",    nil, nil, "",  nil,  "5", "s", nil, ]) ],
         suffix: " ]"),
        (format: "[ Kind: %11s; %-.5s ]",
         body: [ (prefix: "[ Kind: ", spec: "%11s",   groups: [ "%11s",   "11s",   nil, nil, "",  "11", nil, "s", nil, ]),
                 (prefix: "; ",       spec: "%-.5s",  groups: [ "%-.5s", "-.5s",   nil, nil, "-", nil,  "5", "s", nil, ]) ],
         suffix: " ]"),
        (format: "Hello %s! %%%n",
         body: [ (prefix: "Hello ",   spec: "%s",     groups: [ "%s",     "s",     nil, nil, "",  nil,  nil, "s", nil, ]),
                 (prefix: "! ",       spec: "%%",     groups: [ "%%",     "%",     nil, nil, nil, nil,  nil, nil, nil, ]),
                 (prefix: "",         spec: "%n",     groups: [ "%n",     "n",     nil, nil, nil, nil,  nil, nil, nil, ]) ],
         suffix: "") ]

    let Tests2: [(answer: String, args: [String])] = [ ("[ Kind: Galen      ; Rhodes ]", [ "Galen", "Rhodes" ]),
                                                       ("[ Kind:       Galen; Rhodes ]", [ "Galen", "Rhodes" ]),
                                                       ("[ Kind: Galen      ; Rhode ]",  [ "Galen", "Rhodes" ]),
                                                       ("[ Kind:       Galen; Rhode ]",  [ "Galen", "Rhodes" ]),
                                                       ("Hello Galen! %\n",              [ "Galen", ]), ]
    //@f:1

    public override func setUp() {}

    public override func tearDown() {}

    func testRegex() throws {
        for x in (0 ..< TestFormats.count) {
            let fmtData = TestFormats[x]
            let fmt     = fmtData.format

            print(Bar1)
            print("Format: \"\(fmt)\"")
            var error: Error?       = nil
            var idx:   String.Index = fmt.startIndex
            guard let rx = RegularExpression(pattern: FormatPattern, error: &error) else { throw error! }

            var y: Int = 0

            rx.forEach(in: fmt) { (m: RegularExpression.Match?, f: RegularExpression.MatchingFlags, s: inout Bool) in
                guard let m = m else { return }

                let body:   T1        = fmtData.body[y++]
                let groups: [String?] = body.groups

                guard m.count == groups.count else { XCTFail("Incorrect number of groups: \(m.count) != \(groups.count)"); return }

                let prefix = String(fmt[idx ..< m.range.lowerBound])
                let spec   = String(fmt[m.range.lowerBound ..< m.range.upperBound])

                if prefix != body.prefix { XCTFail("Found: \"\(prefix)\" != Expected: \"\(body.prefix)\"") }
                if spec != body.spec { XCTFail("Found: \"\(spec)\" != Expected: \"\(body.spec)\"") }

                print(Bar2)
                print("   Prefix: \"\(prefix)\"")
                print("Specifier: \"\(spec)\"")

                for i in (0 ..< m.count) {
                    let grp = m[i].subString
                    guard grp == groups[i] else { XCTFail("Incorrect group value: Found: \(debugQuote(grp)) != Expected: \(debugQuote(groups[i]))"); continue }

                    print("  Group \(i): ", terminator: "")
                    guard let _grp = grp else { print(); continue }
                    print("\"\(_grp)\"")
                }

                idx = m.range.upperBound
            }

            let suffix = String(fmt[idx...])
            if suffix != fmtData.suffix { XCTFail("Found: \"\(suffix)\" != Expected: \"\(fmtData.suffix)\"") }

            print(Bar2)
            print("   Suffix: \"\(suffix)\"")
        }
        print(Bar1)
    }

    func testString() throws {
        for i in (0 ..< min(TestFormats.count, Tests2.count)) {
            let s1 = TestFormats[i].format
            let s2 = s1.format(arguments: Tests2[i].args)
            let s3 = Tests2[i].answer
            if s2 != s3 {
                XCTFail("Found: \"\(s2)\" != Expected: \"\(s3)\"")
                continue
            }
            print(s2.visCtrl)
        }
    }

    func testPadding() throws {
        let answers1: [String] = [ "",
                                   "",
                                   "G",
                                   "Ga",
                                   "Gal",
                                   "Gale",
                                   "Galen",
                                   "RGalen",
                                   "RhGalen",
                                   "RhoGalen",
                                   "RhodGalen",
                                   "RhodeGalen",
                                   "RhodesGalen", ]
        let answers2: [String] = [ "RhoGalen",
                                   "RhoGalen",
                                   "hodGalen",
                                   "odeGalen",
                                   "desGalen",
                                   "esRGalen",
                                   "sRhGalen",
                                   "RhoGalen", ]

        let s = "Galen"
        let p = "Rhodes"
        for i in (-1 ..< 12) {
            let ans = answers1[i + 1]
            let str = s.padding(toLength: i, withPad: p, startingAt: 0, onRight: false)
            if str != ans {
                XCTFail("\"\(str)\" != \"\(ans)\": toLength = \(i)")
            }
        }
        for i in (-1 ..< (p.count + 1)) {
            let ans = answers2[i + 1]
            let str = s.padding(toLength: 8, withPad: p, startingAt: i, onRight: false)
            if str != ans {
                XCTFail("\"\(str)\" != \"\(ans)\": startingAt = \(i)")
            }
        }
    }

    #if !(os(macOS) || os(tvOS) || os(iOS) || os(watchOS))
        public static var allTests: [(String, (StringFormatTests) -> () throws -> Void)] {
            [ ("StringFormatTests", testRegex), ]
        }
    #endif
}
