/*
 *     PROJECT: Rubicon
 *    FILENAME: OnlyOneQueue.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/29/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*============================================================================================================================================================================*/

import Foundation
import CoreFoundation

open class OnlyOneQueue {
    public typealias QueueFunc = () -> Void

    private let queue: DispatchQueue
    private let sema:  DispatchSemaphore

    public init(label: String? = nil, qos: DispatchQoS = .unspecified, attributes: DispatchQueue.Attributes = [], autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit, target: DispatchQueue? = nil) {
        queue = DispatchQueue(label: (label ?? UUID().uuidString), qos: qos, attributes: attributes, autoreleaseFrequency: autoreleaseFrequency, target: target)
        sema = DispatchSemaphore(value: 1)
    }

    @discardableResult open func tryAsync(executing body: @escaping QueueFunc) -> Bool {
        nDebug(.In, "OnlyOneQueue.tryAsync(executing:)")
        defer { nDebug(.Out, "OnlyOneQueue.tryAsync(executing:)") }
        guard sema.wait(timeout: .now()) == .success else {
            nDebug(.In, "OnlyOneQueue.tryAsync(executing:) - FAILURE")
            return false
        }
        nDebug(.In, "OnlyOneQueue.tryAsync(executing:) - SUCCESS")
        forceAsync(body)
        return true
    }

    open func async(executing body: @escaping QueueFunc) {
        nDebug(.In, "OnlyOneQueue.async(executing:)")
        defer { nDebug(.Out, "OnlyOneQueue.async(executing:)") }
        sema.wait()
        forceAsync(body)
    }

    open func forceAsync(_ body: @escaping QueueFunc) {
        nDebug(.In, "OnlyOneQueue._async(_:)")
        defer { nDebug(.Out, "OnlyOneQueue._async(_:)") }
        queue.async {
            nDebug(.In, "OnlyOneQueue._async(_:) - closure")
            defer { nDebug(.Out, "OnlyOneQueue._async(_:) - closure") }
            defer {
                nDebug(.Out, "OnlyOneQueue._async(_:) - sema.signal()")
                self.sema.signal()
            }
            body()
        }
    }
}
