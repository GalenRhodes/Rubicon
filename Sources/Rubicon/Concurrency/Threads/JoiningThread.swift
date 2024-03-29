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

public protocol JThread {
/*@f0*/
    static var isMainThread:    Bool { get }
    static var isMultiThreaded: Bool { get }

    var isStarted:        Bool                { get }
    var isFinished:       Bool                { get }
    var isExecuting:      Bool                { get }
    var isCancelled:      Bool                { get }
    var isMainThread:     Bool                { get }
    var threadDictionary: NSMutableDictionary { get }

    var name:             String?             { get set }
    var stackSize:        Int                 { get set }
    var qualityOfService: QualityOfService    { get set }
/*@f1*/
    func start()

    func cancel()

    func main()

    func join()

    func join(until limit: Date) -> Bool
}

/*==============================================================================================================================================================================*/
open class JoiningThread: JThread, Hashable {
    public typealias ThreadBlock = () -> Void

    @inlinable public class var isMainThread:    Bool { Thread.isMainThread }
    @inlinable public class var isMultiThreaded: Bool { Thread.isMultiThreaded() }

    /*@f0=======================================================================================================================================================================*/
    @inlinable public var isStarted:        Bool { lock.withLock { status != .initialized  } }
    @inlinable public var isFinished:       Bool { lock.withLock { status == .finished     } }
    @inlinable public var isExecuting:      Bool { lock.withLock { status == .executing    } }

    @inlinable public var isCancelled:      Bool                { thread.isCancelled      }
    @inlinable public var isMainThread:     Bool                { thread.isMainThread     }
    @inlinable public var threadDictionary: NSMutableDictionary { thread.threadDictionary }

    @inlinable public var name:             String?          { get { thread.name             } set { thread.name = newValue             } }
    @inlinable public var stackSize:        Int              { get { thread.stackSize        } set { thread.stackSize = newValue        } }
    @inlinable public var qualityOfService: QualityOfService { get { thread.qualityOfService } set { thread.qualityOfService = newValue } }

    /*@f1=======================================================================================================================================================================*/
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
        guard let b = data.block else { fatalError(ErrMsgNoMain) }
        b()
    }

    /*==========================================================================================================================================================================*/
    open func join() {
        lock.wait(while: (status == .executing))
    }

    /*==========================================================================================================================================================================*/
    open func join(until limit: Date) -> Bool {
        lock.wait(while: (status == .executing), until: limit)
    }

    /*==========================================================================================================================================================================*/
    open func start() {
        lock.withLock {
            guard status == .initialized else { return }
            status = .starting
            thread.start()
        }
    }

    /*==========================================================================================================================================================================*/
    open func cancel() {
        lock.withLock {
            guard isValue(status, in: .starting, .executing) else { return }
            thread.cancel()
        }
    }

    /*@f0======================================================================================================================================================================*/
    @usableFromInline enum Status { case initialized, starting, executing, finished }

    @usableFromInline typealias ThInfo = (name: String?, qualityOfService: QualityOfService?, stackSize: Int?, block: ThreadBlock?)

    @usableFromInline      var status:    Status      = .initialized
    @usableFromInline lazy var thread:    Thread      = createThread()
    @usableFromInline      let lock:      NSCondition = NSCondition()
    @usableFromInline      let data:      ThInfo

    @inlinable func setStatusWhileLocked(newStatus st: Status) { lock.withLock { status = st } }

    /*@f1======================================================================================================================================================================*/
    private func createThread() -> Thread {
        let thd = Thread { [self] in
            defer { setStatusWhileLocked(newStatus: .finished) }
            setStatusWhileLocked(newStatus: .executing)
            main()
        }
        thd.name = data.name
        if let q = data.qualityOfService { thd.qualityOfService = q }
        if let s = data.stackSize { thd.stackSize = s }
        return thd
    }
}

extension JoiningThread {/*@f0*/
    @inlinable public        func hash(into hasher: inout Hasher)                     { hasher.combine(thread.hashValue) }
    @inlinable public static func == (lhs: JoiningThread, rhs: Thread) -> Bool        { (lhs.thread === rhs)             }
    @inlinable public static func == (lhs: Thread, rhs: JoiningThread) -> Bool        { (lhs === rhs.thread)             }
    @inlinable public static func == (lhs: JoiningThread, rhs: JoiningThread) -> Bool { (lhs === rhs)                    }
/*@f1*/
}
