/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Test1.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/28/20
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

do {
    var nogo:       Bool     = true
    var run:        Bool     = true
    var ts:         timespec = timespec()
    var iterations: UInt64   = 0
    var elapsed:    UInt64   = 0

    func getTime() -> UInt64 {
        while clock_gettime(CLOCK_MONOTONIC_RAW, &ts) != 0 { /* wait */ }
        return (UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec))
    }

    do {
        let cond:      UnsafeMutablePointer<pthread_cond_t>      = UnsafeMutablePointer<pthread_cond_t>.allocate(capacity: 1)
        let mutex:     UnsafeMutablePointer<pthread_mutex_t>     = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        let condAttr:  UnsafeMutablePointer<pthread_condattr_t>  = UnsafeMutablePointer<pthread_condattr_t>.allocate(capacity: 1)
        let mutexAttr: UnsafeMutablePointer<pthread_mutexattr_t> = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)

        pthread_mutexattr_init(mutexAttr)
        pthread_condattr_init(condAttr)

        pthread_mutexattr_settype(mutexAttr, PTHREAD_MUTEX_ERRORCHECK)
        pthread_mutexattr_setpshared(mutexAttr, PTHREAD_PROCESS_PRIVATE)
        pthread_mutexattr_setpolicy_np(mutexAttr, _PTHREAD_MUTEX_POLICY_FIRSTFIT)
        pthread_condattr_setpshared(condAttr, PTHREAD_PROCESS_PRIVATE)

        pthread_mutex_init(mutex, mutexAttr)
        pthread_cond_init(cond, condAttr)

        // According to this: https://pubs.opengroup.org/onlinepubs/009695399/functions/pthread_mutexattr_destroy.html
        // I'm safe to destroy the attributes now.
        pthread_mutexattr_destroy(mutexAttr)
        pthread_condattr_destroy(condAttr)
        mutexAttr.deinitialize(count: 1)
        mutexAttr.deallocate()
        condAttr.deinitialize(count: 1)
        condAttr.deallocate()

        defer {
            pthread_mutex_destroy(mutex)
            pthread_cond_destroy(cond)
            mutex.deinitialize(count: 1)
            cond.deinitialize(count: 1)
            mutex.deallocate()
            cond.deallocate()
        }

        let thread: Thread = Thread {
            pthread_mutex_lock(mutex)
            let startTime = getTime()

            while run {
                while run && nogo {
                    pthread_cond_wait(cond, mutex)
                }
                if run {
                    iterations += 1
                    nogo = true
                }
            }

            elapsed = (getTime() - startTime)
            pthread_mutex_unlock(mutex)
            print("Thread Done.")
        }
        thread.qualityOfService = .userInteractive
        thread.start()

        let loopStartTime:  UInt64 = getTime()
        let loopIterations: UInt64 = 100_000_000

        for _ in (0 ..< loopIterations) {
            pthread_mutex_lock(mutex)
            nogo = false
            pthread_cond_broadcast(cond)
            pthread_mutex_unlock(mutex)
        }

        let loopElapsedTime: UInt64 = (getTime() - loopStartTime)

        pthread_mutex_lock(mutex)
        nogo = false
        run = false
        pthread_cond_signal(cond)
        pthread_mutex_unlock(mutex)

        while thread.isExecuting {}

        print("Done.")
        print("Loop Elapsed Time: \(loopElapsedTime) ns")
        print("  Loop Iterations: \(loopIterations)")
        print("Loop Average Time: \(loopElapsedTime / loopIterations) ns")
        print("")
    }

    print("Elapsed Time: \(elapsed) ns")
    print("  Iterations: \(iterations)")
    print("Average Time: \(elapsed / iterations) ns")
}
