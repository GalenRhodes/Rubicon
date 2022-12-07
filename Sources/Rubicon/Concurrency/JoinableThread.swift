// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: JoinableThread.swift
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
import CoreFoundation

open class JoinableThread {
    /*@f:0*/
    public typealias ThreadBlock = () throws -> Void

    public var error: Error? = nil

    private enum State { case NotStarted, Starting, Executing, Cancelled, Error, Finished, FinishedCancelled, FinishedError }

    private var block:  ThreadBlock
    private var thread: Thread!
    private var state:  State         = .NotStarted
    private let lock:   NSCondition   = NSCondition()

    public var threadDictionary: NSMutableDictionary { thread.threadDictionary }
    public var isMainThread:     Bool                { thread.isMainThread     }

    public var isExecuting:      Bool                { lock.withLock { isValue(state, in: .Executing, .Cancelled)                        } }
    public var isFinished:       Bool                { lock.withLock { isValue(state, in: .Finished, .FinishedCancelled, .FinishedError) } }
    public var isCancelled:      Bool                { lock.withLock { isValue(state, in: .Cancelled, .FinishedCancelled)                } }
    public var isError:          Bool                { lock.withLock { (error != nil) || isValue(state, in: .Error, .FinishedError)      } }

    public var name:             String?             { get { thread.name             } set { thread.name = newValue             } }
    public var qualityOfService: QualityOfService    { get { thread.qualityOfService } set { thread.qualityOfService = newValue } }
    public var stackSize:        Int                 { get { thread.stackSize        } set { thread.stackSize = newValue        } }
    /*@f:1*/

    public init(name: String? = nil, qualityOfService: QualityOfService? = nil, _ block: @escaping ThreadBlock = {}) {
        self.block = block
        self.thread = Thread { self._main() }
        self.thread.name = name
        if let q = qualityOfService { self.thread.qualityOfService = q }
    }

    open func main() throws { try block() }

    public func start() {
        lock.withLock {
            guard state == .NotStarted else { return }
            state = .Starting
            thread.start()
        }
    }

    public func cancel() {
        lock.withLock {
            guard state == .Executing else { return }
            state = .Cancelled
            thread.cancel()
        }
    }

    public func join() throws {
        lock.withLockWait(while: !isValue(state, in: .Finished, .FinishedCancelled, .FinishedError))
        if let e = error { throw e }
    }

    private func _main() {
        lock.withLock {
            guard state == .Starting else { return }
            state = .Executing
        }
        do {
            try main()
            lock.withLock { state = ((state == .Cancelled) ? .FinishedCancelled : .Finished) }
        }
        catch let e {
            lock.withLock {
                error = e
                state = .FinishedError
            }
        }
    }
}
