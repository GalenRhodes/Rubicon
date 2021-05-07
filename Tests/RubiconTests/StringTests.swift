/*=============================================================================================================================================================================*//*
 *     PROJECT: Rubicon
 *    FILENAME: StringTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/6/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*============================================================================================================================================================================*/

import XCTest
import Foundation
import CoreFoundation
@testable import Rubicon

class StringTests: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    func testFormat() {
        //print("Galen Rhodes was%nhere for %1$-05.2d days!  Wow!  %<-05.2d days!".format(15.43))
        print("Galen Rhodes was here for \"%d\" days!".format(1234))
        print("Galen Rhodes was here for \"%d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% d\" days!".format(1234))
        print("Galen Rhodes was here for \"% d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%(,d\" days!".format(1234))
        print("Galen Rhodes was here for \"%(,d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% (,d\" days!".format(1234))
        print("Galen Rhodes was here for \"% (,d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+(,d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+(,d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% 10d\" days!".format(1234))
        print("Galen Rhodes was here for \"% 10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- 10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- 10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%(10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%(10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% (10d\" days!".format(1234))
        print("Galen Rhodes was here for \"% (10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+(10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+(10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-(10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-(10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- (10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- (10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+(10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+(10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% 010d\" days!".format(1234))
        print("Galen Rhodes was here for \"% 010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- 010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- 010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%(010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%(010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% (010d\" days!".format(1234))
        print("Galen Rhodes was here for \"% (010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+(010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+(010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-(010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-(010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- (010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- (010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+(010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+(010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% ,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"% ,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+,10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- ,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- ,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+,10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%(,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%(,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% (,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"% (,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+(,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+(,10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-(,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-(,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- (,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- (,10d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+(,10d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+(,10d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% ,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"% ,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+,010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- ,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- ,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+,010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%(,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%(,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"% (,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"% (,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%+(,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%+(,010d\" days!".format(-1234))

        print("Galen Rhodes was here for \"%-(,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-(,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%- (,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%- (,010d\" days!".format(-1234))
        print("Galen Rhodes was here for \"%-+(,010d\" days!".format(1234))
        print("Galen Rhodes was here for \"%-+(,010d\" days!".format(-1234))
    }
}
