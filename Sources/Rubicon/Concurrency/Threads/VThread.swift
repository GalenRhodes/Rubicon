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

public typealias Predicate = () -> Bool
public let NoValueErrorMessage: String = "ERROR: No value."

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
open class VThread<T> {

    /*==========================================================================================================================================================================*/
    /// The closure type for this class. Note that it can throw an error AND return a value. The closure accepts a single parameter which, itself, is a closure
    /// that can be called to check to see if the thread has been cancelled.
    ///
    public typealias ThreadBlock = (Predicate) throws -> T

    /*@f:0======================================================================================================================================================================*/
    @inlinable public    var isFinished:  Bool   { thread.isFinished  }
    @inlinable public    var isExecuting: Bool   { thread.isExecuting }
    @inlinable public    var isCancelled: Bool   { thread.isCancelled }
    @inlinable public    var isStarted:   Bool   { thread.isStarted   }
    public internal(set) var error:       Error? = nil

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
    open func main(isCancelled: Predicate) throws -> T {
        guard let b = data.block else { fatalError(NoMainErrorMessage) }
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
    @inlinable func getValue() throws -> T {
        if let e = error { throw e }
        if let v = value { return v }
        fatalError(NoValueErrorMessage)
    }

    /*@f:0======================================================================================================================================================================*/
    @usableFromInline typealias TInfo = (name: String?, qualityOfService: QualityOfService?, stackSize: Int?, block: ThreadBlock?)

    @usableFromInline      let data:   TInfo
    @usableFromInline      var value:  T?      = nil
    @usableFromInline lazy var thread: JThread = JThread(name: data.name, qualityOfService: data.qualityOfService, stackSize: data.stackSize) { self.main() }

    /*==========================================================================================================================================================================*/
    private func main() { do { value = try main { thread.isCancelled } } catch let e { error = e } }
    /*@f:1*/
}

extension VThread {

    @inlinable public func hash(into hasher: inout Hasher) { thread.hash(into: &hasher) }

    @inlinable public static func == (lhs: VThread, rhs: JThread) -> Bool { lhs.thread === rhs }

    @inlinable public static func == (lhs: JThread, rhs: VThread) -> Bool { lhs === rhs.thread }

    @inlinable public static func == (lhs: VThread, rhs: Thread) -> Bool { lhs.thread === rhs }

    @inlinable public static func == (lhs: Thread, rhs: VThread) -> Bool { lhs === rhs.thread }

    @inlinable public static func == (lhs: VThread, rhs: VThread) -> Bool { lhs === rhs }
}
