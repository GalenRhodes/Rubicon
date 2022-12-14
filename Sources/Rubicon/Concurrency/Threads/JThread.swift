// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: JThread.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: December 12, 2022
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
import CoreFoundation

public let NoMainErrorMessage: String = "ERROR: main() not implemented and no closure provided."

open class JThread {
    public typealias ThreadBlock = () -> Void

    /*@f:0======================================================================================================================================================================*/
    @inlinable public var isStarted:   Bool { lock.withLock { executing || finished } }
    @inlinable public var isFinished:  Bool { lock.withLock { finished              } }
    @inlinable public var isExecuting: Bool { lock.withLock { executing             } }
    @inlinable public var isCancelled: Bool { lock.withLock { thread.isCancelled    } }

    /*@f:1======================================================================================================================================================================*/
    public init(name: String? = nil, qualityOfService qos: QualityOfService? = nil, stackSize ss: Int? = nil, start st: Bool = false) {
        data = (name: name, qualityOfService: qos, stackSize: ss, block: nil)
        if st { start() }
    }

    /*==========================================================================================================================================================================*/
    public init(name: String? = nil, qualityOfService qos: QualityOfService? = nil, stackSize ss: Int? = nil, start st: Bool = false, block: @escaping ThreadBlock) {
        data = (name: name, qualityOfService: qos, stackSize: ss, block: block)
        if st { start() }
    }

    /*==========================================================================================================================================================================*/
    open func main() {
        guard let b = data.block else { fatalError(NoMainErrorMessage) }
        b()
    }

    /*==========================================================================================================================================================================*/
    open func join() {
        lock.wait(while: executing)
    }

    /*==========================================================================================================================================================================*/
    open func join(until limit: Date) -> Bool {
        lock.wait(while: executing, until: limit)
    }

    /*==========================================================================================================================================================================*/
    open func start() {
        lock.withLock {
            guard !(executing || finished) else { return }
            executing = true
            thread.start()
        }
    }

    /*==========================================================================================================================================================================*/
    open func cancel() {
        lock.withLock {
            guard executing && !finished else { return }
            thread.cancel()
        }
    }

    /*@f:0======================================================================================================================================================================*/
    @usableFromInline typealias TInfo = (name: String?, qualityOfService: QualityOfService?, stackSize: Int?, block: ThreadBlock?)

    @usableFromInline      var executing: Bool        = false
    @usableFromInline      var finished:  Bool        = false
    @usableFromInline lazy var thread:    Thread      = createThread()
    @usableFromInline      let lock:      NSCondition = NSCondition()
    @usableFromInline      let data:      TInfo

    /*@f:1======================================================================================================================================================================*/
    private func createThread() -> Thread {
        let t = Thread { [self] in
            main()
            lock.withLock {
                executing = false
                finished = true
            }
        }
        t.name = data.name
        if let q = data.qualityOfService { t.qualityOfService = q }
        if let s = data.stackSize { t.stackSize = s }
        return t
    }
}
