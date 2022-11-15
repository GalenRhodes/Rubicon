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

let cond:          NSCondition = NSCondition()
let threadCount:   Int         = 100
var activeThreads: Int         = 0
var flag:          Bool        = false
var threads:       [Thread]    = []

func doIt() {
    print("Launching \(threadCount) threads...")

    for _ in (1 ... threadCount) {
        let aThread = Thread(block: {
            cond.withLock {
                activeThreads += 1
                print("Thread \(activeThreads) started.")
            }
            cond.withLockWait(while: !flag) {
                print("Thread \(activeThreads) finished.")
                activeThreads -= 1
            }
        })

        threads.append(aThread)
        aThread.qualityOfService = Thread.main.qualityOfService
        aThread.start()
    }

    cond.withLockWait(while: activeThreads < threadCount) {
        print("Setting flag to true...")
        flag = true
    }
    cond.withLockWait(while: activeThreads > 0) {
        print("Done")
    }
}

DispatchQueue.main.async {
    doIt()
    exit(0)
}
dispatchMain()
