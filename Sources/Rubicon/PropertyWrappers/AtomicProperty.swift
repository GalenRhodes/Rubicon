/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: AtomicProperty.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/16/21
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

/*==============================================================================================================*/
/// A property wrapper to ensure that read/write access to a resource is atomic with respect to writes. Encloses
/// access to the property with a read/write mutex (lock) so that any writes to the property completely finish
/// before any reads are allowed.
///
@propertyWrapper
public struct Atomic<T> {
    @usableFromInline var value: T
    @usableFromInline let lock:  MutexLock = MutexLock()

    @inlinable public var wrappedValue: T {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }

    public init(wrappedValue: T) {
        value = wrappedValue
    }
}
