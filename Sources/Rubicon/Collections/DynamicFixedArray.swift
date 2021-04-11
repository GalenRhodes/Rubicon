/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: DynamicFixedArray.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 2/27/21
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

open class DynamicFixedArray<T> {

    public let count:      Int
    public let dimensions: [Int]

    open var lastArray:  ArraySlice<T?> { matrix[(count - dimensions[count - 1]) ..< count] }
    open var firstArray: ArraySlice<T?> { matrix[0 ..< dimensions[count - 1]] }
    open var last:       T? { matrix[count - 1] }
    open var first:      T? { matrix[0] }

    private lazy var matrix: [T?] = Array<T?>(repeating: nil, count: count)

    public init(dimensions dim: Int...) {
        guard dim.count > 0 else { fatalError("DynamicFixedArray: Must have at least 1 dimensions: \(dim.count)") }
        dimensions = dim
        var size = 1
        for d in dimensions {
            guard d > 0 else { fatalError("DynamicFixedArray: None of the dimensions can be zero.") }
            size = (size * d)
        }
        count = size
    }

    open func lastArray(at indexes: Int...) -> ArraySlice<T?> {
        guard indexes.count == (dimensions.count - 1) else { fatalError(msg02(indexes)) }
        let x1 = index(indexes: indexes)
        let x2 = (x1 + dimensions[count - 1])
        return matrix[x1 ..< x2]
    }

    open subscript(indexes: Int...) -> T? {
        get {
            guard indexes.count == dimensions.count else { fatalError(msg01(indexes)) }
            return matrix[index(indexes: indexes)]
        }
        set {
            guard indexes.count == dimensions.count else { fatalError(msg01(indexes)) }
            matrix[index(indexes: indexes)] = newValue
        }
    }

    private func index(indexes: [Int]) -> Int {
        let cc = indexes.count
        let cx = (cc - 1)

        guard cc <= dimensions.count else { fatalError(msg06(cc)) }
        guard cc > 0 else { fatalError(msg05()) }

        var idx = indexes[cx]
        guard idx >= 0 else { fatalError(msg04(cc, idx)) }
        let idxe = dimensions[cx]
        guard idx < idxe else { fatalError(msg03(cc, idx, idxe)) }

        if cx > 0 {
            for i in stride(from: (cx - 1), through: 0, by: -1) {
                let e:  Int = indexes[i]
                let de: Int = dimensions[i]

                let x = (i + 1)
                guard e >= 0 else { fatalError(msg04(x, e)) }
                guard e < de else { fatalError(msg03(x, e, de)) }

                idx = ((idx * de) + e)
            }
        }

        return idx
    }

    private func msg01(_ indexes: [Int]) -> String {
        "DynamicFixedArray: Number of indexes must equal number of dimensions: \(indexes.count) != \(dimensions.count)"
    }

    private func msg02(_ indexes: [Int]) -> String {
        "DynamicFixedArray: Number of indexes must be one less than the number of dimensions: \(indexes.count) != \(dimensions.count - 1)"
    }

    private func msg03(_ idx: Int, _ value: Int, _ limit: Int) -> String {
        "DynamicFixedArray: Index \(idx) is out of bounds: \(value) >= \(limit)"
    }

    private func msg04(_ idx: Int, _ value: Int) -> String {
        "DynamicFixedArray: Index \(idx) is out of bounds: \(value) < 0"
    }

    private func msg05() -> String {
        "DynamicFixedArray: Must have at least 1 dimension."
    }

    private func msg06(_ dims: Int) -> String {
        "DynamicFixedArray: Too many dimensions: \(dims) > \(dimensions.count)"
    }
}
