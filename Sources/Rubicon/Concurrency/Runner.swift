/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: Runner.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/28/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

open class Runner<SignalType, ResultType> {
    public typealias SignalGetter = () -> SignalType?
    public typealias ClosureType = (SignalGetter) throws -> ResultType

    public enum RunnerError: Error {
        case AlreadyStarted
        case NotYetStarted
        case AlreadyFinished
        case InternalError
    }

    //@f:0
    public  var qualityOfService: QualityOfService = .default
    open    var isStarted:        Bool             { lock.withLock { started            } }
    open    var isRunning:        Bool             { lock.withLock { started && !done   } }
    open    var isDone:           Bool             { lock.withLock { done               } }
    open    var didFail:          Bool             { lock.withLock { done && err != nil } }
    open    var error:            Error?           { lock.withLock { err                } }
    open    var results:          ResultType?      { lock.withLock { res                } }
    open    var startTime:        Date?            { lock.withLock { sTime              } }
    open    var endTime:          Date?            { lock.withLock { eTime              } }

    private var started:          Bool             = false
    private var done:             Bool             = false
    private var res:              ResultType?      = nil
    private var err:              Error?           = nil
    private var sig:              SignalType?      = nil
    private var sTime:            Date?            = nil
    private var eTime:            Date?            = nil
    private let lock:             Conditional      = Conditional()
    private let closure:          ClosureType
    //@f:1

    public init(startNow: Bool = false, qualityOfService: QualityOfService = .default, execute closure: @escaping ClosureType) {
        self.closure = closure
        if startNow { _start() }
    }

    open func start() throws {
        try lock.withLock {
            guard !started else { throw RunnerError.AlreadyStarted }
            _start()
        }
    }

    open func signal(with sig: SignalType) throws {
        try lock.withLock {
            guard started else { throw RunnerError.NotYetStarted }
            guard !done else { throw RunnerError.AlreadyFinished }
            self.sig = sig
        }
    }

    open func getResults() throws -> ResultType {
        try lock.withLock {
            _ = try _wait(until: Date.distantFuture)
            if let e = err { throw e }
            if let r = res { return r }
            throw RunnerError.InternalError
        }
    }

    open func getResults(until limit: Date) throws -> ResultType? {
        try lock.withLock {
            guard try _wait(until: limit) else { return nil }
            if let e = err { throw e }
            if let r = res { return r }
            throw RunnerError.InternalError
        }
    }

    open func wait() throws { try wait(until: Date.distantFuture) }

    open func wait(until limit: Date) throws -> Bool { try lock.withLock { try _wait(until: limit) } }

    private func _start() {
        sTime = Date()
        started = true
        thread.qualityOfService = qualityOfService
        thread.start()
    }

    private func _wait(until limit: Date) throws -> Bool {
        guard started else { throw RunnerError.NotYetStarted }
        while !done && lock.broadcastWait(until: limit) {}
        return done
    }

    private lazy var thread: Thread = Thread { [weak self] in
        if let s = self {
            var r: ResultType? = nil
            var e: Error?      = nil

            do { r = try s.closure { s.lock.withLock { s.sig } } }
            catch let _e { e = _e }

            s.lock.withLock {
                s.eTime = Date()
                s.res = r
                s.err = e
                s.done = true
            }
        }
    }
}
