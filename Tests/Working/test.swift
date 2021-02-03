/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: test.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/31/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
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

let chars: [Character] = [ "🇺🇸", "\r\n" ]

for ch in chars {
    for s: Unicode.Scalar in ch.unicodeScalars {
        if s.properties.isWhitespace { print("Character: \".\"", terminator: "")}
        else { print("Character: \"\(Character(s)) \"", terminator: "") }
        print("; isEmoji = \(s.properties.isEmoji)", terminator: "")
        print("; isEmojiModifierBase = \(s.properties.isEmojiModifierBase)", terminator: "")
        print("; isEmojiModifier = \(s.properties.isEmojiModifier)", terminator: "")
        print("; isEmojiPresentation = \(s.properties.isEmojiPresentation)", terminator: "")
        print("; isGraphemeBase = \(s.properties.isGraphemeBase)", terminator: "")
        print("; isGraphemeExtend = \(s.properties.isGraphemeExtend)", terminator: "")
        print("; isDiacritic = \(s.properties.isDiacritic)", terminator: "")
        print("; isExtender = \(s.properties.isExtender)", terminator: "")
        print("; isFullCompositionExclusion = \(s.properties.isFullCompositionExclusion)", terminator: "")
        print("")
    }
}




//
