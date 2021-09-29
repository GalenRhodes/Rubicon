/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: NanoTimer.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/26/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
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
/// Nano timer errors.
///
public enum NanoTimerError: Error {
    /*==========================================================================================================*/
    /// The timer has already been started.
    ///
    case AlreadyStarted
    /*==========================================================================================================*/
    /// The timer has not yet been started.
    ///
    case NotStarted
}

/*==============================================================================================================*/
/// If running, calls the provided `block` on a separate thread every `nanos` nanoseconds.
///
open class NanoTimer {

    public typealias PGThreadBlock = () -> Void

    private var running: Bool = false
    private var gate:    UInt = 0
    private var skip:    UInt = 0

    private var worker1: PGThread?     = nil
    private var worker2: PGThread?     = nil
    private let lock:    RecursiveLock = RecursiveLock()

    /*==========================================================================================================*/
    /// The block that gets called every `nanos` nanoseconds.
    ///
    public var block: PGThreadBlock = {}

    /*==========================================================================================================*/
    /// Returns `true` if the timer is running. Returns `false` if the timer has been `stop`ped.
    ///
    public var isRunning: Bool { lock.withLock { running } }

    /*==========================================================================================================*/
    /// The number of nanoseconds between calls to the the `block`.
    ///
    public let nanos:     time_t

    /*==========================================================================================================*/
    /// Initializes the timer to call the `block` every `nanos` nanoseconds.
    /// 
    /// - Parameter nanos: the number of nanoseconds. Must be less than `OneSecondNanos`.
    ///
    public init(nanos: time_t) {
        self.nanos = nanos
    }

    /*==========================================================================================================*/
    /// Initializes the timer to call the block.
    /// 
    /// - Parameter time:
    ///
    public init(time: timespec) {
        self.nanos = time_t((time.tv_sec * OneSecondNanos) + time.tv_nsec)
    }

    deinit {
        try? stop()
    }

    /*==========================================================================================================*/
    /// Adds a number of timer cycles to skip to the existing number. The timer will skip a number of timer
    /// firings when told to.
    /// 
    /// - Parameter skip: The number of cycles to skip.
    ///
    public func add(skip: UInt = 1) {
        if skip > 0 {
            self.skip += skip
        }
    }

    /*==========================================================================================================*/
    /// Start the timer.  If the timer is already running then calling this method does nothing.
    ///
    public func start() throws {
        try lock.withLock {
            guard !running else {
                throw NanoTimerError.AlreadyStarted
            }
            _start()
        }
    }

    private func _start() {
        if nanos < OneSecondMicros {
            _startShortDelay()
        }
        else {
            _startLongDelay()
        }
    }

    private func _startLongDelay() {
        running = true
        worker1 = PGThread(startNow: true, qualityOfService: .userInteractive) {
            var next: time_t   = getSysTime(delta: self.nanos)
            let adj:  time_t   = (next - 3_000)
            var tmsp: timespec = timespec(tv_sec: 0, tv_nsec: 3_000)

            while self.running {
                let now: time_t = getSysTime()

                if now >= next {
                    if self.skip > 0 {
                        self.skip -= 1
                    }
                    else {
                        self.gate += 1
                    }
                    next += self.nanos
                }
                else if now < adj {
                    nanosleep(&tmsp, nil)
                }
            }
        }
        worker2 = PGThread(startNow: true, qualityOfService: .userInteractive) {
            while self.running {
                if self.gate > 0 {
                    self.gate -= 1
                    self.block()
                }
            }
        }
    }

    private func _startShortDelay() {
        running = true
        worker1 = PGThread(startNow: true, qualityOfService: .userInteractive) {
            var next: time_t = getSysTime(delta: self.nanos)

            while self.running {
                if getSysTime() >= next {
                    if self.skip > 0 {
                        self.skip -= 1
                    }
                    else {
                        self.gate += 1
                    }
                    next += self.nanos
                }
            }
        }
        worker2 = PGThread(startNow: true, qualityOfService: .userInteractive) {
            while self.running {
                if self.gate > 0 {
                    self.gate -= 1
                    self.block()
                }
            }
        }
    }

    /*==========================================================================================================*/
    /// Stop the timer. Waits for all the current timer calls in progress to finish executing. If the timer is
    /// already stopped then calling this method does nothing.
    ///
    public func stop() throws {
        try lock.withLock {
            guard running else {
                throw NanoTimerError.NotStarted
            }
            running = false
            if let w: PGThread = worker1 {
                w.join()
            }
            if let w: PGThread = worker2 {
                w.join()
            }
            worker1 = nil
            worker2 = nil
        }
    }
}
