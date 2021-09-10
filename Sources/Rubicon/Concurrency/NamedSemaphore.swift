/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Rubicon
 *    FILENAME: NamedSemaphore.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/4/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif
#if os(Windows)
    import WinSDK
#endif

#if !os(Android)
    /*==========================================================================================================*/
    /// This class implements an named (intra-process) semaphore. This type of semaphore is visible to multiple
    /// processes. If you need a semaphore that is visible to multiple processes then use a `NamedSemaphore`.
    ///
    open class NamedSemaphore: PGSemaphore {
        #if os(Windows)
            public static let OSMaximumNameLength: Int = Int.max
        #else
            #if _POSIX_NO_TRUNC
                public static let OSMaximumNameLength: Int = Int(truncatingIfNeeded: ((_POSIX_NO_TRUNC == -1) ? NAME_MAX : PATH_MAX))
            #else
                public static let OSMaximumNameLength: Int = Int(truncatingIfNeeded: NAME_MAX)
            #endif
        #endif
        /*======================================================================================================*/
        /// The maximum value of the semaphore - 2,147,483,647. The current value will never go above this value.
        ///
        #if os(Windows)
            public static let OSMaximumValue: Int = Int(Int32.max)
        #else
            public static let OSMaximumValue: Int = Int(truncatingIfNeeded: SEM_VALUE_MAX)
        #endif
        /*======================================================================================================*/
        /// `true` if the semaphore is open.  `false` if it has been closed.
        ///
        public private(set) var isOpen: Bool = false
        public let name: String
        /*======================================================================================================*/
        /// The maximum value of the semaphore - 2,147,483,647. The current value will never go above this value.
        ///
        #if os(Windows)
            public let maxValue: Int
        #else
            public let maxValue: Int = NamedSemaphore.OSMaximumValue
        #endif
        /*======================================================================================================*/
        /// The current value of the semaphore. If this value is less than or equal to
        /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> then any call to `acquire()`, `tryAcquire()`, or
        /// `tryAcquire(until:)` will respectively either block, fail, or potentially timeout until this value
        /// becomes greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code>. Currently, only Linux
        /// allows for reading the current value of the semaphore.
        ///
        public var value: Int {
            #if os(macOS) || os(tvOS) || os(iOS) || os(watchOS) || os(Windows)
                return 0
            #else
                let _zz: UnsafeMutablePointer<Int32> = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
                _zz.initialize(to: 0)
                sem_getvalue(_sem, _zz)
                return Int(_zz.pointee)
            #endif
        }

        #if os(Windows)
            private var _sem: HANDLE! = nil
        #else
            private let _owns: Bool
            private var _sem:  Semaphore
        #endif

        #if os(Windows)
            /*==================================================================================================*/
            /// Create a new named semaphore.
            /// 
            /// - Parameters:
            ///   - name: The name of the semaphore.
            ///   - initialValue: The initial value of the semaphore. Must be between
            ///                   <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) and `maxValue`.
            ///   - maxValue: The maximum value the semaphore is allowed.
            ///   - error: Set to any error that occurs.
            ///
            public init?(name: String, initialValue: Int, maxValue: Int = Int.max, error: inout Error?) {
                var nm = name
                let rx = RegularExpression(pattern: "\\\\(\\w+)\\\\([^\\\\]+)")
                if let m = rx?.firstMatch(in: nm), let n = m[2].subString { nm = "\\Global\\\(n)" }
                self.name = nm
                self.maxValue = maxValue
                error = CErrors.NOTSUP()
                return nil
            }

            /*==================================================================================================*/
            /// Create a new named semaphore.
            /// 
            /// - Parameters:
            ///   - name: The name of the semaphore.
            ///   - initialValue: The initial value of the semaphore. The maximum value is OS dependent. On macOS
            ///                   it is 32,767.
            ///   - maxValue: The maximum value the semaphore is allowed.
            ///
            public convenience init?(name: String, initialValue: Int, maxValue: Int = Int.max) {
                var error: Error? = nil
                self.init(name: name, initialValue: initialValue, error: &error)
            }
        #else
            /*==================================================================================================*/
            /// Create a new named semaphore.
            /// 
            /// - Parameters:
            ///   - name: The name of the semaphore.
            ///   - initialValue: The initial value of the semaphore. Must be between
            ///                   <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) and `OSMaximumValue`.
            ///                   The maximum value is OS dependent. On macOS it is 32,767.
            ///   - error: Set to any error that occurs.
            ///
            public init?(name: String, initialValue: Int, error: inout Error?) {
                self.name = (name.hasPrefix("/") ? name : "/\(name)")
                let s = sem_open(self.name, O_CREAT | O_EXCL, 0o777, CUnsignedInt(truncatingIfNeeded: initialValue))
                if s == SEM_FAILED {
                    if errno == EEXIST {
                        let s = sem_open(self.name, 0)
                        if s == SEM_FAILED {
                            error = CErrors.getErrorFor(code: errno)
                            return nil
                        }
                        _owns = false
                        _sem = s!
                    }
                    else {
                        error = CErrors.getErrorFor(code: errno)
                        return nil
                    }
                }
                else {
                    _owns = true
                    _sem = s!
                }
            }

            /*==================================================================================================*/
            /// Create a new named semaphore.
            /// 
            /// - Parameters:
            ///   - name: The name of the semaphore.
            ///   - initialValue: The initial value of the semaphore. The maximum value is OS dependent. On macOS
            ///                   it is 32,767.
            ///
            public convenience init?(name: String, initialValue: Int) {
                var error: Error? = nil
                self.init(name: name, initialValue: initialValue, error: &error)
            }
        #endif

        /*======================================================================================================*/
        /// Release the semaphore. Increments the value by one (1). If the value was previously less than or equal
        /// to <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then a waiting thread will be woken up and
        /// allowed to acquire the semaphore.
        /// 
        /// - Returns: `true` if successful. If the value before calling `release()` is already equal to the
        ///            maximum value then it is left unchanged and `false` is returned.
        ///
        public func release() -> Bool {
            #if os(Windows)
                return false
            #else
                (sem_post(_sem) == 0)
            #endif
        }

        /*======================================================================================================*/
        /// Acquire the semaphore. If the value before calling is less than or equal to
        /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then the calling thread is blocked until it
        /// is greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
        ///
        public func acquire() {
            #if os(Windows)
            #else
                guard sem_wait(_sem) == 0 else { fatalError(CErrors.getErrorFor(code: errno).description) }
            #endif
        }

        /*======================================================================================================*/
        /// Attempt to acquire the semaphore. If the value before calling is less than or equal to
        /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then this method fails by returning `false`.
        /// 
        /// - Returns: `true` if successful. `false` if value is less than or equal to
        ///            <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0).
        ///
        public func tryAcquire() -> Bool {
            #if os(Windows)
                return false
            #else
                let ret: Int32 = sem_trywait(_sem)
                guard (ret == 0) || (errno == EAGAIN) else { fatalError(CErrors.getErrorFor(code: errno).description) }
                return (ret == 0)
            #endif
        }

        /*======================================================================================================*/
        /// Attempt to acquire the semaphore. If the value before calling is less than or equal to
        /// <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) then the calling thread is blocked until
        /// either the value is greater than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (0) or until the
        /// amount of time specified by `until` has elapsed.
        /// 
        /// - Parameter until: the absolute time that this method will wait trying to acquire the semaphore.
        /// - Returns: `true` if successful or `false` if the specified time has elapsed.
        ///
        public func tryAcquire(until: Date) -> Bool {
            #if os(macOS) || os(tvOS) || os(watchOS) || os(iOS)
                return false
            #elseif os(Windows)
                return false
            #else
                guard var time: timespec = until.absoluteTimeSpec() else { return false }
                let ret: Int32 = sem_timedwait(_sem, &time)
                guard (ret == 0) || (errno == ETIMEDOUT) else { fatalError(CErrors.getErrorFor(code: errno).description) }
                return (ret == 0)
            #endif
        }
    }
#endif
