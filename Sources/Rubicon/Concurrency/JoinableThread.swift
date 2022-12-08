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
/// This class offers a little bit more flexibility over the standard Foundation [Thread](https://developer.apple.com/documentation/foundation/thread) class. The standard
/// Thread class found in [Apple's Foundation library](https://developer.apple.com/documentation/foundation) is pretty bare bones. For starters, unlike the
/// [Process](https://developer.apple.com/documentation/foundation/process) class, it lacks any way to [join](https://www.ibm.com/docs/en/aix/7.2?topic=programming-joining-threads)
/// another thread - that is to say, put one thread to sleep until another thread finishes executing.
///
/// The other things the standard Foundation Thread class lacks is an easy way to tell if the thread threw an error during execution or to have the thread return a value from
/// it's execution.
///
/// This implementation attempts to solve all of that by behaving similar to [Java's Concurrency](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html)
/// library's [Callable](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/Callable.html)/[Future](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/Future.html)
/// interface paradigm.
///
open class JoinableThread<T> {
    /*@f:0*/
    /// The closure type for this class. Note that it can throw an error AND return a value.
    ///
    public typealias ThreadBlock = (() -> Bool) throws -> T

    public enum JoinableThreadError: Error { case ThreadNotStarted, NothingToExecute }

    /// The error, if any, thrown by the thread during it's execution. This field will always remain `nil` until after the thread has finished executing.
    ///
    public var error:            Error?              { thread.error       }
    /// This field indicates whether or not the thread is still executing.
    ///
    public var isExecuting:      Bool                { thread.isExecuting }
    /// This field indicates whether or not the thread has finished executing.
    ///
    public var isFinished:       Bool                { thread.isFinished  }
    /// This field indicates whether or not the thread was canceled.
    ///
    public var isCancelled:      Bool                { thread.isCancelled }
    /// This field indicates whether or not the thread was started. Once a thread has been started it can not be restarted. Doing so will result in a fatal error.
    ///
    public var isStarted:        Bool                { thread.isStarted   }
    /// Indicates whether or not the this thread threw an error during it's execution. This field will remain `false` until the thread has finished executing.
    ///
    public var isError:          Bool                { thread.isError     }

    public var name:             String?             { get { thread.name             } set { thread.name = newValue             } }
    public var qualityOfService: QualityOfService    { get { thread.qualityOfService } set { thread.qualityOfService = newValue } }
    public var stackSize:        Int                 { get { thread.stackSize        } set { thread.stackSize = newValue        } }
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
    open func main(isCancelled: () -> Bool) throws -> T {
        guard let b = block else { throw JoinableThreadError.NothingToExecute }
        return try b(isCancelled)
    }

    /*==========================================================================================================================================================================*/
    /// Joins the thread to wait for it's completion and then returns the value returned by the closure provided at creation or the overridden method
    /// `JoinableThread.main(isCancelled:)`
    ///
    /// - Returns: The value returned by the thread.
    /// - Throws: Any error thrown by the thread or `JoinableThreadError.ThreadNotStarted` if the thread was never started.
    ///
    @discardableResult public func get() throws -> T { try thread.get() }

    /*==========================================================================================================================================================================*/
    /// Exactly the same as `JoinableThread.get()`.
    ///
    /// - Returns: The value returned by the thread.
    /// - Throws: Any error thrown by the thread or `JoinableThreadError.ThreadNotStarted` if the thread was never started.
    ///
    @discardableResult public func join() throws -> T { try thread.get() }

    /*==========================================================================================================================================================================*/
    public func start() { thread.start() }

    /*==========================================================================================================================================================================*/
    public func cancel() { thread.cancel() }

    private var thread: XThread<T>!
    private let block:  ThreadBlock?

    /*==========================================================================================================================================================================*/
    private class XThread<T>: Thread {
        private enum PrivateThreadError: Error { case NoReturnValue }

/*@f:0*/
        override var isExecuting: Bool   { _lock.withLock { _started && !_finished                   } }
        override var isCancelled: Bool   { _lock.withLock { _started && super.isCancelled            } }
        override var isFinished:  Bool   { _lock.withLock { _finished                                } }
        var          isStarted:   Bool   { _lock.withLock { _started                                 } }
        var          isError:     Bool   { _lock.withLock { _started && _finished && (_error != nil) } }
        var          error:       Error? { _lock.withLock { _started && _finished ? _error : nil     } }
/*@f:1*/

        /*==========================================================================================================================================================================*/
        init(_ owner: JoinableThread<T>, _ name: String?, _ qualityOfService: QualityOfService?, _ stackSize: Int?) {
            self._owner = owner
            super.init()
            self.name = name
            if let q = qualityOfService { self.qualityOfService = q }
            if let s = stackSize { self.stackSize = s }
        }

        /*==========================================================================================================================================================================*/
        public func get() throws -> T {
            try _lock.withLock {
                guard _started else { throw JoinableThreadError.ThreadNotStarted }
                while !_finished { _lock.wait() }
                if let e = _error { throw e }
                guard let r = _value else { throw PrivateThreadError.NoReturnValue }
                return r
            }
        }

        /*==========================================================================================================================================================================*/
        override func start() {
            _lock.withLock {
                guard !_started else { fatalError("This thread has already been started.") }
                _started = true
                super.start()
            }
        }

        /*==========================================================================================================================================================================*/
        override func cancel() {
            _lock.withLock {
                guard _started && !_finished else { return }
                super.cancel()
            }
        }

        /*==========================================================================================================================================================================*/
        override func main() -> Void {
            do { if let o = _owner { try run(o) } }
            catch let e { finish(error: e) }
        }

        /*==========================================================================================================================================================================*/
        private func run(_ owner: JoinableThread<T>) throws {
            _value = try owner.main { super.isCancelled }
            finish(error: nil)
        }

        /*==========================================================================================================================================================================*/
        private func finish(error e: Error?) {
            _lock.withLock {
                _error = e
                _finished = true
            }
        }

        /*======================================================================================================================================================================@f:0*/
        private      let _lock:     NSCondition = NSCondition()
        private      var _value:    T?          = nil
        private      var _error:    Error?      = nil
        private      var _finished: Bool        = false
        private      var _started:  Bool        = false
        private weak var _owner:    JoinableThread<T>?
/*@f:1*/
    }
}
