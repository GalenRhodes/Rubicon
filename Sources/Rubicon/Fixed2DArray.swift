/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Fixed2DArray.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 12/11/20
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

open class Fixed2DArray<T> {

    public let rowCount:    Int
    public let columnCount: Int
    var matrix: [T?]

    public init(rows: Int, cols: Int) {
        guard rows > 0 else { fatalError("Number of rows must be greater than zero.") }
        guard cols > 0 else { fatalError("Number of columns must be greater than zero.") }
        self.rowCount = rows
        self.columnCount = cols
        self.matrix = Array<T?>(repeating: nil, count: rows * cols)
    }

    open subscript(row: Int, col: Int) -> T? {
        get { matrix[calcIndex(row, col)] }
        set { matrix[calcIndex(row, col)] = newValue }
    }

    @inlinable final func calcIndex(_ row: Int, _ col: Int) -> Int {
        guard row >= 0 && row < rowCount else { fatalError("Row index is out of bounds.") }
        guard col >= 0 && col < columnCount else { fatalError("Column index is out of bounds.") }
        return (columnCount * row + col)
    }
}
