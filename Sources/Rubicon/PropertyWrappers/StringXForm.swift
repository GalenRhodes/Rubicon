/*=================================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: StringXForm.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/8/20
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
 *===============================================================================================================================================================================*/

import Foundation

@propertyWrapper
public struct StringXForm {

    private var value:  String
    private let xforms: XForms

    public struct XForms: OptionSet {
        public let rawValue: UInt8

        public static let lowercased = XForms(rawValue: 1 << 0)
        public static let uppercased = XForms(rawValue: 1 << 1)
        public static let trimmed    = XForms(rawValue: 1 << 2)

        public init(rawValue: UInt8) { self.rawValue = rawValue }
    }

    public var wrappedValue: String {
        get { value }
        set {
            value = newValue
            if xforms.contains(.lowercased) { value = value.lowercased() }
            if xforms.contains(.uppercased) { value = value.uppercased() }
            if xforms.contains(.trimmed) { value = value.trimmed }
        }
    }

    public init(_ xforms: XForms) {
        self.value = ""
        self.xforms = xforms
    }

    public init(wrappedValue: String, _ xforms: XForms) {
        self.value = ""
        self.xforms = xforms
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct OStringXForm {

    private var value:  String?
    private let xforms: XForms

    public struct XForms: OptionSet {
        public let rawValue: UInt8

        public static let lowercased = XForms(rawValue: 1 << 0)
        public static let uppercased = XForms(rawValue: 1 << 1)
        public static let trimmed    = XForms(rawValue: 1 << 2)

        public init(rawValue: UInt8) { self.rawValue = rawValue }
    }

    public var wrappedValue: String? {
        get { value }
        set {
            self.value = newValue
            if var value = newValue {
                if xforms.contains(.lowercased) { value = value.lowercased() }
                if xforms.contains(.uppercased) { value = value.uppercased() }
                if xforms.contains(.trimmed) { value = value.trimmed }
                self.value = value
            }
        }
    }

    public init(_ xforms: XForms) {
        self.value = nil
        self.xforms = xforms
    }

    public init(wrappedValue: String?, _ xforms: XForms) {
        self.value = nil
        self.xforms = xforms
        self.wrappedValue = wrappedValue
    }
}
