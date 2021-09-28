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
/// A subclass of `Thread` that allows the closure to be set after it has been created.
///
open class PGThread: Thread {

    /*==============================================================================================================*/
    /// The closure type for `PGThread` and `NanoTimer`
    ///
    public typealias PGThreadBlock = () throws -> Void

    //@f:0
    private let _lock:      Conditional = Conditional()
    private var _isDone:    Bool        = false
    private var _isStarted: Bool        = false
    private var _error:     Error?      = nil

    public  var isDone:     Bool        { _lock.withLock { _isDone    } }
    public  var isStarted:  Bool        { _lock.withLock { _isStarted } }
    public  var error:      Error?      { _lock.withLock { _error     } }
    //@f:1

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
    ///   - startNow: If set to `true` the thread is created in a running state.
    ///   - qualityOfService:  The quality of service.
    ///   - block: The `block` for the thread to execute.
    ///
    public init(startNow: Bool = false, qualityOfService: QualityOfService = .default, block: @escaping PGThreadBlock) {
        self.block = block
        super.init()
        self.qualityOfService = qualityOfService
        if startNow { start() }
    }

    /*==========================================================================================================*/
    /// <a href="https://developer.apple.com/documentation/foundation/thread/1418166-start">See Apple Developer
    /// Documentation</a>
    ///
    open override func start() {
        _lock.withLock {
            guard !_isStarted else { return }
            _error = nil
            _isStarted = true
            _isDone = false
            super.start()
        }
    }

    /*==========================================================================================================*/
    /// The main function. We're making this final because we don't want it overridden.
    ///
    public override final func main() {
        do {
            try run()
            _lock.withLock { _isDone = true }
        }
        catch let e {
            _lock.withLock {
                _error = e
                _isDone = true
            }
        }
    }

    /*==========================================================================================================*/
    /// The new main function. Subclasses can override this method.
    ///
    open func run() throws -> Void {
        try block()
    }

    /*==========================================================================================================*/
    /// Waits for the thread to finish executing.
    ///
    open func join() {
        _lock.withLock {
            guard _isStarted else { return }
            while !_isDone { _lock.broadcastWait() }
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
    open func join(until limit: Date) -> Bool {
        _lock.withLock {
            guard _isStarted else { return false }
            while !_isDone || _lock.broadcastWait(until: limit) {}
            return _isDone
        }
    }
}
