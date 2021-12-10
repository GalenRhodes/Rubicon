/*=================================================================================================================================================================================
 *     PROJECT: Rubicon
 *    FILENAME: ThreadLocalProperty.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/19/21
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
/// Thread Local Property Wrapper. A property marked with this wrapper will reserve storage for each thread so
/// that the values gotten and set will only be seen by that thread.
/// 
/// NOTE: DispatchQueues reuse threads. This means that multiple items put onto a dispatch queue may see and
/// manipulate each other's data.
///
@propertyWrapper
public struct ThreadLocal<T> {
    @usableFromInline let initialValue: T
    @usableFromInline let key:          String = UUID().uuidString

    @inlinable public var wrappedValue: T {
        get {
            if Thread.current.threadDictionary.allKeys.contains(where: { ($0 as? String) == key }), let v = Thread.current.threadDictionary[key] as? T { return v }
            Thread.current.threadDictionary[key] = initialValue
            return initialValue
        }
        set {
            Thread.current.threadDictionary[key] = newValue
        }
    }

    public init(wrappedValue: T) {
        initialValue = wrappedValue
    }
}
