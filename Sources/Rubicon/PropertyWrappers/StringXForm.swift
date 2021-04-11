/************************************************************************//**
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
 *//************************************************************************/

import Foundation

@propertyWrapper
public struct StringXForm {

    private var value: String
    private let xform: [XForms]

    public enum XForms {
        case lowercased
        case uppercased
        case trimmed
    }

    public var wrappedValue: String {
        get { value }
        set {
            value = newValue
            for xf in xform {
                switch xf {
                    case .lowercased:
                        value = value.lowercased()
                    case .uppercased:
                        value = value.uppercased()
                    case .trimmed:
                        value = value.trimmed
                }
            }
        }
    }

    public init(_ xform: [XForms]) {
        self.value = ""
        self.xform = xform
    }

    public init(wrappedValue: String, _ xform: [XForms]) {
        self.value = ""
        self.xform = xform
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
public struct OStringXForm {

    private var value: String?
    private let xform: [XForms]

    public enum XForms {
        case lowercased
        case uppercased
        case trimmed
    }

    public var wrappedValue: String? {
        get { value }
        set {
            value = newValue
            if var v = newValue {
                for xf in xform {
                    switch xf {
                        case .lowercased:
                            v = v.lowercased()
                        case .uppercased:
                            v = v.uppercased()
                        case .trimmed:
                            v = v.trimmed
                    }
                }
                value = v
            }
        }
    }

    public init(_ xform: [XForms]) {
        self.value = nil
        self.xform = xform
    }

    public init(wrappedValue: String?, _ xform: [XForms]) {
        self.value = nil
        self.xform = xform
        self.wrappedValue = wrappedValue
    }
}
