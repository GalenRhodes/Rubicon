// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: VThread.swift
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

public typealias ThreadPredicate = () -> Bool

public protocol VThread {
    associatedtype T

    var isFinished:  Bool { get }
    var isExecuting: Bool { get }
    var isCancelled: Bool { get }
    var isStarted:   Bool { get }
    var error:       Error? { get }

    func main(isCancelled: ThreadPredicate) throws -> T

    func start()

    func cancel()

    func get() throws -> T

    func get(until limit: Date) throws -> T?
}

/*==============================================================================================================================================================================*/
/// This class offers a little bit more flexibility over the standard Foundation [Thread](https://developer.apple.com/documentation/foundation/thread) class.
///
/// The standard Thread class found in [Apple's Foundation library](https://developer.apple.com/documentation/foundation) is pretty bare bones. For starters, unlike the
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
open class ValueThread<T>: VThread, Hashable {
    /*==========================================================================================================================================================================*/
    /// The closure type for this class. Note that it can throw an error AND return a value. The closure accepts a single parameter which, itself, is a closure
    /// that can be called to check to see if the thread has been cancelled.
    ///
    public typealias ThreadBlock = (ThreadPredicate) throws -> T

    /*@f0======================================================================================================================================================================*/
    @inlinable public    var isFinished:  Bool   { lock.withLock { thread.isFinished  } }
    @inlinable public    var isExecuting: Bool   { lock.withLock { thread.isExecuting } }
    @inlinable public    var isCancelled: Bool   { lock.withLock { thread.isCancelled } }
    @inlinable public    var isStarted:   Bool   { lock.withLock { thread.isStarted   } }
    @inlinable public    var error:       Error? { lock.withLock { err                } }

    /*@f1======================================================================================================================================================================*/
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
    /// The main entry point routine for the thread.
    ///
    /// The default implementation of this method takes the target and selector used to initialize the receiver and invokes the selector on the specified target. If you subclass
    /// NSThread, you can override this method and use it to implement the main body of your thread instead. If you do so, you do not need to invoke super.
    ///
    /// You should never invoke this method directly. You should always start your thread by invoking the start() method.
    ///
    /// - Parameter isCancelled:
    /// - Returns:
    /// - Throws:
    open func main(isCancelled: ThreadPredicate) throws -> T {
        guard let b = data.block else { fatalError(ErrMsgNoMain) }
        return try b(isCancelled)
    }

    /*==========================================================================================================================================================================*/
    /// Start the receiver.
    ///
    /// This method asynchronously spawns the new thread and invokes the receiver’s main() method on the new thread. The isExecuting property returns true once the thread
    /// starts executing, which may occur after the start() method returns.
    ///
    /// If you initialized the receiver with a target and selector, the default main() method invokes that selector automatically.
    ///
    /// If this thread is the first thread detached in the application, this method posts the NSWillBecomeMultiThreaded with object nil to the default notification center.
    ///
    open func start() { thread.start() }

    /*==========================================================================================================================================================================*/
    open func cancel() { thread.cancel() }

    /*==========================================================================================================================================================================*/
    open func get() throws -> T {
        thread.join()
        return try getValue()
    }

    /*==========================================================================================================================================================================*/
    open func get(until limit: Date) throws -> T? {
        guard thread.join(until: limit) else { return nil }
        return try getValue()
    }

    /*==========================================================================================================================================================================*/
    private func getValue() throws -> T {
        try lock.withLock {
            if let e = err { throw e }
            if let v = value { return v }
            fatalError(ErrMsgNoValue)
        }
    }

    /*@f0======================================================================================================================================================================*/
    @usableFromInline typealias ThInfo = (name: String?, qualityOfService: QualityOfService?, stackSize: Int?, block: ThreadBlock?)

    @usableFromInline      let data:   ThInfo
    @usableFromInline      var value:  T?            = nil
    @usableFromInline lazy var thread: JoiningThread = JoiningThread(name: data.name, qualityOfService: data.qualityOfService, stackSize: data.stackSize) { self.main() }
    @usableFromInline      let lock:   NSLock        = NSLock()
    @usableFromInline      var err:    Error?        = nil

    /*==========================================================================================================================================================================*/
    private func main() {
        do {
            let v = try main(isCancelled: { thread.isCancelled })
            lock.withLock { value = v }
        }
        catch let e {
            lock.withLock { err = e }
        }
    }
}/*@f1*/

extension ValueThread {/*@f0*/
    @inlinable public        func hash(into hasher: inout Hasher)                   { thread.hash(into: &hasher) }
    @inlinable public static func == (lhs: ValueThread, rhs: JoiningThread) -> Bool { (lhs.thread === rhs)       }
    @inlinable public static func == (lhs: JoiningThread, rhs: ValueThread) -> Bool { (lhs === rhs.thread)       }
    @inlinable public static func == (lhs: ValueThread, rhs: Thread) -> Bool        { (lhs.thread === rhs)       }
    @inlinable public static func == (lhs: Thread, rhs: ValueThread) -> Bool        { (lhs === rhs.thread)       }
    @inlinable public static func == (lhs: ValueThread, rhs: ValueThread) -> Bool   { (lhs === rhs)              }
/*@f1*/
}
