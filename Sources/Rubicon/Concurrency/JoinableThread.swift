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

    enum State { case NotStarted, Starting, Executing, Finished, Canceled, FinishedCanceled }

    @LockedValue var state: State = .NotStarted

    lazy var thread: Thread = Thread { [self] in self._main() }
    let block: () -> Void

    public var isExecuting: Bool { _state.isValue { $0 == .Executing } }
    public var isFinished: Bool { _state.isValue { $0 == .Finished || $0 == .FinishedCanceled } }
    public var isCanceled: Bool { _state.isValue { $0 == .FinishedCanceled } }
    public var isMainThread:     Bool { thread.isMainThread }
    public var name:             String? {
        get { thread.name }
        set { thread.name = newValue }
    }
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(OSX)
        public var threadPriority: Double {
            get { thread.threadPriority }
            set { thread.threadPriority = newValue }
        }
    #endif
    public var qualityOfService: QualityOfService {
        get { thread.qualityOfService }
        set { thread.qualityOfService = newValue }
    }
    public var stackSize:        Int {
        get { thread.stackSize }
        set { thread.stackSize = newValue }
    }

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(OSX)
        public init(name: String? = nil, threadPriority: Double? = nil, qualityOfService: QualityOfService? = nil) {
            block = {}
            thread.name = name
            if let p = threadPriority { thread.threadPriority = p }
            if let q = qualityOfService { thread.qualityOfService = q }
        }

        public init(name: String? = nil, threadPriority: Double? = nil, qualityOfService: QualityOfService? = nil, _ block: @escaping () -> Void) {
            self.block = block
            thread.name = name
            if let p = threadPriority { thread.threadPriority = p }
            if let q = qualityOfService { thread.qualityOfService = q }
        }
    #else
        public init(name: String? = nil, qualityOfService: QualityOfService? = nil) {
            block = {}
            thread.name = name
            if let q = qualityOfService { thread.qualityOfService = q }
        }

        public init(name: String? = nil, qualityOfService: QualityOfService? = nil, _ block: @escaping () -> Void) {
            self.block = block
            thread.name = name
            if let q = qualityOfService { thread.qualityOfService = q }
        }
    #endif

    public func start() {
        _state.withLock {
            if $0 == .NotStarted {
                $0 = .Starting
                thread.start()
            }
        }
    }

    public func cancel() {
        _state.withLock {
            if $0 == .Executing {
                $0 = .Canceled
                thread.cancel()
            }
        }
    }

    func _main() {
        let flag = _state.withLock {
            guard $0 == .Starting else { return false }
            $0 = .Executing
            return true
        }
        if flag {
            main()
            _state.withLock {
                switch $0 {
                    case .Executing: $0 = .Finished
                    case .Canceled: $0 = .FinishedCanceled
                    default: break
                }
            }
        }
    }

    open func main() {
        block()
    }

    public func join() {
        _state.waitForCondition { $0 != .Executing }
    }
}
