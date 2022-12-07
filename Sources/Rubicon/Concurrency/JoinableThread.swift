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

/*==============================================================================================================================================================================*/
open class JoinableThread<T> {
    /*@f:0*/
    public typealias ThreadBlock = () throws -> T

    public var error:            Error?              { thread.lock.withLock { (thread.xFinished ? thread.xError : nil)   } }
    public var isExecuting:      Bool                { thread.lock.withLock { thread.xExecuting                          } }
    public var isFinished:       Bool                { thread.lock.withLock { thread.xFinished                           } }
    public var isCancelled:      Bool                { thread.lock.withLock { thread.xCancelled                          } }
    public var isError:          Bool                { thread.lock.withLock { thread.xFinished && (thread.xError != nil) } }

    public var threadDictionary: NSMutableDictionary { thread.threadDictionary }
    public var isMainThread:     Bool                { thread.isMainThread     }

    public var name:             String?             { get { thread.name             } set { thread.name = newValue             } }
    public var qualityOfService: QualityOfService    { get { thread.qualityOfService } set { thread.qualityOfService = newValue } }
    public var stackSize:        Int                 { get { thread.stackSize        } set { thread.stackSize = newValue        } }

    private var thread: XThread<T>!
    private let block:  ThreadBlock?
    /*@f:1*/
    /*==========================================================================================================================================================================*/
    public init(name: String? = nil, qualityOfService: QualityOfService? = nil, stackSize: Int? = nil) {
        self.block = nil
        self.thread = XThread<T>(self, name, qualityOfService, stackSize)
    }

    /*==========================================================================================================================================================================*/
    public init(name: String? = nil, qualityOfService: QualityOfService? = nil, stackSize: Int? = nil, _ block: @escaping ThreadBlock) {
        self.block = block
        self.thread = XThread<T>(self, name, qualityOfService, stackSize)
    }

    /*==========================================================================================================================================================================*/
    open func main() throws -> T {
        guard let b = block else { throw JoinableThreadError.NothingToExecute }
        return try b()
    }

    /*==========================================================================================================================================================================*/
    @discardableResult public func get() throws -> T { try thread.get() }

    /*==========================================================================================================================================================================*/
    @discardableResult public func join() throws -> T { try thread.get() }

    /*==========================================================================================================================================================================*/
    public func start() { thread.start() }

    /*==========================================================================================================================================================================*/
    public func cancel() { thread.cancel() }

    public enum JoinableThreadError: Error {
        case ThreadNotStarted
        case NoReturnValue
        case NothingToExecute
    }

    /*==========================================================================================================================================================================*/
    private class XThread<T>: Thread {
        weak var owner: JoinableThread<T>?
        let lock:         NSCondition = NSCondition()
        var xCancelled:   Bool        = false
        var xExecuting:   Bool        = false
        var xFinished:    Bool        = false
        var xError:       Error?      = nil
        var xReturnValue: T?          = nil
        var xStarted:     Bool { (xCancelled || xExecuting || xFinished) }

        init(_ owner: JoinableThread<T>, _ name: String?, _ qualityOfService: QualityOfService?, _ stackSize: Int?) {
            self.owner = owner
            super.init()
            self.name = name
            if let q = qualityOfService { self.qualityOfService = q }
            if let s = stackSize { self.stackSize = s }
        }

        public func get() throws -> T {
            try lock.withLock {
                guard xStarted else { throw JoinableThreadError.ThreadNotStarted }
                while xExecuting { lock.wait() }
                if let e = xError { throw e }
                guard let r = xReturnValue else { throw JoinableThreadError.NoReturnValue }
                return r
            }
        }

        override func cancel() {
            lock.withLock {
                guard xExecuting else { return }
                xCancelled = true
                super.cancel()
            }
        }

        override func start() {
            lock.withLock {
                guard !xStarted else { return }
                xExecuting = true
                super.start()
            }
        }

        override func main() -> Void {
            do {
                guard let o = owner else { return }
                xReturnValue = try o.main()
                finish(error: nil)
            }
            catch let e { finish(error: e) }
        }

        /*==========================================================================================================================================================================*/
        private func finish(error e: Error?) {
            lock.withLock {
                xError = e
                xExecuting = false
                xFinished = true
            }
        }
    }
}
