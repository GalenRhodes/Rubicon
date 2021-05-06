/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: PGThread.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/27/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation

/*==============================================================================================================*/
/// The closure type for `PGThread` and `NanoTimer`
///
public typealias PGThreadBlock = () -> Void

/*==============================================================================================================*/
/// A subclass of `Thread` that allows the closure to be set after it has been created.
///
open class PGThread: Thread {

    private let cond: Conditional = Conditional()

    public private(set) var isDone:    Bool = true
    public private(set) var isStarted: Bool = false

    /*==========================================================================================================*/
    /// The `block` for the thread to execute. This can only be set before the thread is executed. Attempting to
    /// set the `block` after the thread has been executed has no affect. If the thread is executed before the
    /// `block` is set then it simply terminates without doing anything.
    ///
    public var block: PGThreadBlock

    /*==========================================================================================================*/
    /// Default initializer
    ///
    public override init() {
        block = {}
        super.init()
    }

    /*==========================================================================================================*/
    /// Initializes the thread with the given `closure` and if `startNow` is set to `true`, starts it right away.
    /// 
    /// - Parameters:
    ///   - startNow: if set to `true` the thread is created in a running state.
    ///   - qualityOfService:  the quality of service.
    ///   - block: the `block` for the thread to execute.
    ///
    public convenience init(startNow: Bool = false, qualityOfService: QualityOfService = .default, block: @escaping PGThreadBlock) {
        self.init()
        self.block = block
        self.qualityOfService = qualityOfService
        if startNow { start() }
    }

    /*==========================================================================================================*/
    /// <a href="https://developer.apple.com/documentation/foundation/thread/1418166-start">See Apple Developer
    /// Documentation</a>
    ///
    open override func start() {
        cond.withLock {
            isStarted = true
            isDone = false
            super.start()
        }
    }

    /*==========================================================================================================*/
    /// The main function.
    ///
    public override func main() {
        block()
        cond.withLock { isDone = true }
    }

    /*==========================================================================================================*/
    /// Waits for the thread to finish executing.
    ///
    public func join() {
        cond.withLock {
            if isStarted {
                while !isDone { cond.wait() }
            }
        }
    }

    /*==========================================================================================================*/
    /// Waits until the given date for the thread to finish executing.
    /// 
    /// - Parameter limit: the point in time to wait until for the thread to execute. If the time is in the past
    ///                    then the method will return immediately.
    /// - Returns: `true` if the thread finished executing before the given time or `false` if the time was
    ///            reached or the thread has not been started yet.
    ///
    public func join(until limit: Date) -> Bool {
        cond.withLock {
            guard isStarted else { return false }
            while !isDone { guard cond.wait(until: limit) else { return false } }
            return true
        }
    }
}
