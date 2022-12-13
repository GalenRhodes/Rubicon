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

open class JThread {
    public typealias Block = () -> Void
/*@f:0*/
    @inlinable public var isFinished:  Bool { _lock.withLock { _finished  } }
    @inlinable public var isExecuting: Bool { _lock.withLock { _executing } }
    @inlinable public var isCancelled: Bool { _lock.withLock { _cancelled } }
    @inlinable public var isStarted:   Bool { _lock.withLock { _started   } }
/*@f:1*/
    public init(name: String? = nil, qualityOfService qos: QualityOfService? = nil, stackSize ss: Int? = nil, start st: Bool = false) {
        _iData = (name, qos, ss, nil)
        if st { start() }
    }

    public init(name: String? = nil, qualityOfService qos: QualityOfService? = nil, stackSize ss: Int? = nil, start st: Bool = false, _ block: @escaping () -> Void) {
        _iData = (name, qos, ss, block)
        if st { start() }
    }

    open func main() {
        guard let b = _iData.3 else { fatalError("ERROR: main() not implemented and no closure provided.") }
        b()
    }

    public func join() { _lock.wait(while: _executing) }

    public func join(until limit: Date) -> Bool { _lock.wait(while: _executing, until: limit) }

    public func start() { _lock.withLock { _start() } }

    public func startAndJoin() {
        _lock.withLock {
            _start()
            while _executing { _lock.wait() }
        }
    }

    public func startAndJoin(until limit: Date) -> Bool {
        _lock.withLock {
            _start()
            while _executing { guard _lock.wait(until: limit) else { return false } }
            return true
        }
    }

    public func cancel() { _lock.withLock { _cancel() } }

    public func cancelAndJoin() {
        _lock.withLock {
            guard _cancel() else { return }
            while _executing { _lock.wait() }
        }
    }

    public func cancelAndJoin(until limit: Date) -> Bool {
        _lock.withLock {
            guard _cancel() else { return true }
            while _executing { guard _lock.wait(until: limit) else { return false } }
            return true
        }
    }

    private func _main() {
        main()
        _lock.withLock {
            _executing = false
            _finished = true
        }
    }

    private func _start() {
        guard !_started else { return }
        _executing = true
        _thread.start()
    }

    private func _cancel() -> Bool {
        guard (_executing && !(_finished || _cancelled)) else { return false }
        _cancelled = true
        _thread.cancel()
        return true
    }

    @usableFromInline let _lock:      NSCondition = NSCondition()
    @usableFromInline var _executing: Bool        = false
    @usableFromInline var _finished:  Bool        = false
    @usableFromInline var _cancelled: Bool        = false
    @usableFromInline let _iData:     (String?, QualityOfService?, Int?, Block?)

    @inlinable var _started: Bool { (_executing || _finished) }

    @usableFromInline lazy var _thread: Thread = {
        let t = Thread(block: { self._main() })
        t.name = _iData.0
        if let q = _iData.1 { t.qualityOfService = q }
        if let s = _iData.2 { t.stackSize = s }
        return t
    }()
}
