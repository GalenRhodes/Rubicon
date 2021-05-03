/*=============================================================================================================================================================================*//*
 *     PROJECT: Rubicon
 *    FILENAME: ThreadLocalTests.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/1/21
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

class ThreadLocalTests: XCTestCase {

    @ThreadLocal var testField: String = "Galen Rhodes"

    let queue1: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, autoreleaseFrequency: .workItem)
    let queue2: DispatchQueue = DispatchQueue(label: UUID().uuidString, qos: .utility, autoreleaseFrequency: .workItem)
    let lock:   MutexLock     = MutexLock()

    override func setUp() {}

    override func tearDown() {}

    func testThreadLocal() {
        debug(testField)
        testField.append(" is awesome!")
        debug(testField)

        queue1.async {
            self.lock.withLock {
                debug(self.testField)
                self.testField.append(" is wonderful!")
                debug(self.testField)
            }
        }
        queue2.async {
            self.lock.withLock {
                debug(self.testField)
                self.testField.append(" is fantastic!")
                debug(self.testField)
            }
        }
        lock.withLock { debug(testField) }
        queue1.async { self.lock.withLock { debug(self.testField) } }
        queue2.async { self.lock.withLock { debug(self.testField) } }
        sleep(3)
    }
}
