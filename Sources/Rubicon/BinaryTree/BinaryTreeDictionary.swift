/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: BinaryTreeDictionary.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/13/21
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

open class BinaryTreeDictionary<Key: Comparable & Hashable & Equatable, Value>: ExpressibleByDictionaryLiteral, BidirectionalCollection {
    //@f:0
    public typealias Index       = ShadowInt
    public typealias Element     = (key: Key, value: Value)
    public typealias SubSequence = Slice<BinaryTreeDictionary<Key, Value>>
    public typealias Indices     = DefaultIndices<BinaryTreeDictionary<Key, Value>>

    public                       let capacity:   Int    = Int.max
    public                       let startIndex: Index  = Index(0)
    public fileprivate(set) lazy var keys:       Keys   = Keys(self)
    public fileprivate(set) lazy var values:     Values = Values(self)
    public                       var endIndex:   Index  { Index(count)         }
    public                       var isEmpty:    Bool   { rootNode == nil      }
    public                       var count:      Int    { rootNode?.count ?? 0 }

    @usableFromInline var _hashValue: Int?                  = nil
    @usableFromInline var rootNode:   TreeNode<Key, Value>? = nil
    //@f:1

    /*==========================================================================================================*/
    /// Default constructor.
    ///
    public required init() {}

    public required init(repeating repeatedValue: Element, count: Int) { if count > 0 { self[repeatedValue.key] = repeatedValue.value } }

    public required init<S>(_ elements: S) where S: Sequence, Element == S.Element { elements.forEach { e in self[e.key] = e.value } }

    public required init(from decoder: Decoder) throws where Key: Decodable, Value: Decodable {
        let cc = try Int(from: decoder)
        for _ in (0 ..< cc) {
            let key:   Key   = try Key.init(from: decoder)
            let value: Value = try Value.init(from: decoder)
            self[key] = value
        }
    }

    /*==========================================================================================================*/
    /// Only for compatibility with Dictionary. The minimum capacity of a BinaryTreeDictionary is always 0.
    /// 
    /// - Parameter minimumCapacity: ignored.
    ///
    public init(minimumCapacity: Int) {}

    public required init(dictionaryLiteral elements: (Key, Value)...) { elements.forEach { self[$0.0] = $0.1 } }

    public init(_ dictionary: [Key: Value]) { dictionary.forEach { self[$0.key] = $0.value } }

    public init(_ tree: BinaryTreeDictionary<Key, Value>) { tree.forEach { self[$0.key] = $0.value } }

    open subscript(bounds: Range<Index>) -> SubSequence { SubSequence(base: self, bounds: bounds) }

    open func distance(from start: Index, to end: Index) -> Int { (end.value - start.value) }

    open subscript(key: Key) -> Value? {
        get {
            guard let r = rootNode, let n = r[key] else { return nil }
            return n.value
        }
        set {
            if let v = newValue {
                if let r = rootNode {
                    if let n = r[key] { n.value = v }
                    else { rootNode = r.add(key: key, value: v) }
                }
                else {
                    rootNode = TreeNode<Key, Value>(key: key, value: v)
                }
            }
            else {
                removeValue(forKey: key)
            }
        }
    }

    @discardableResult open func remove(at index: Index) -> Element {
        let n = nodeAt(position: index)
        let e = (n.key, n.value)
        rootNode = n.remove()
        return e
    }

    @discardableResult open func removeValue(forKey key: Key) -> Value? {
        guard let r = rootNode, let n = r[key] else { return nil }
        let v = n.value
        rootNode = n.remove()
        return v
    }

    open func removeAll(keepingCapacity keepCapacity: Bool = false) { rootNode = nil }

    open func index(after i: Index) -> Index { i + 1 }

    open func index(before i: Index) -> Index { i - 1 }

    open func index(_ i: Index, offsetBy distance: Int) -> Index { (i + distance) }

    open func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
        let _i = (i + distance)
        guard _i >= 0 && _i <= limit else { return nil }
        return _i
    }

    open subscript(position: Index) -> (key: Key, value: Value) {
        get {
            let node = nodeAt(position: position)
            return (node.key, node.value)
        }
        set(newValue) {
            let node = nodeAt(position: position)
            if node.key == newValue.key {
                node.value = newValue.value
            }
            else {
                remove(at: position)
                self[newValue.key] = newValue.value
            }
        }
    }

    open func forEach(_ body: (Element) throws -> Void) rethrows { if let r = rootNode { try r.forEach { node in try body((node.key, node.value)) } } }

    @usableFromInline func nodeAt(position: Index) -> TreeNode<Key, Value> {
        guard position >= startIndex, let r = rootNode else { fatalError("Index out of bounds.") }
        if let n = r[position] { return n }
        r.hardRecount()
        guard position >= startIndex && position < endIndex else { fatalError("Index out of bounds.") }
        guard let n = r[position] else { fatalError("Internal Inconsistency Error.") }
        return n
    }
}

extension BinaryTreeDictionary {
    @inlinable public static func <+ (lhs: BinaryTreeDictionary<Key, Value>, rhs: (key: Key, value: Value)) { lhs[rhs.key] = rhs.value }

    @inlinable public static func <+ (lhs: BinaryTreeDictionary<Key, Value>, rhs: [Key: Value]) { rhs.forEach { key, value in lhs[key] = value } }

    @inlinable public static func >- (lhs: BinaryTreeDictionary<Key, Value>, rhs: Key) { lhs.removeValue(forKey: rhs) }

    @inlinable public static func >- (lhs: BinaryTreeDictionary<Key, Value>, rhs: [Key]) { rhs.forEach { lhs.removeValue(forKey: $0) } }
}

extension BinaryTreeDictionary: Equatable where Value: Equatable {

    @inlinable public static func == (lhs: BinaryTreeDictionary<Key, Value>, rhs: BinaryTreeDictionary<Key, Value>) -> Bool {
        guard lhs !== rhs else { return true }
        guard lhs.count == rhs.count else { return false }
        for e: (key: Key, value: Value) in lhs { guard e.value == rhs[e.key] else { return false } }
        return true
    }
}

extension BinaryTreeDictionary: Hashable where Value: Hashable {

    @inlinable public func hash(into hasher: inout Hasher) { if let r = rootNode { r.forEach { $0.hash(into: &hasher) } } }

    @inlinable public var hashValue: Int {
        if let h = _hashValue { return h }
        var hasher: Hasher = Hasher()
        hash(into: &hasher)
        _hashValue = hasher.finalize()
        return _hashValue!
    }
}

extension BinaryTreeDictionary: Sequence {
    @inlinable public func makeIterator() -> Iterator {
        Iterator(tree: rootNode)
    }

    public var underestimatedCount: Int { count }

    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<(key: Key, value: Value)>) throws -> R) rethrows -> R? { nil }

    @frozen public struct Iterator: IteratorProtocol {
        @usableFromInline var stack: [TreeNode<Key, Value>] = []

        @inlinable public init(tree: TreeNode<Key, Value>?) {
            descendBranch(tree)
        }

        @usableFromInline mutating func descendBranch(_ node: TreeNode<Key, Value>?) {
            var _n = node
            while let n = _n {
                stack <+ n
                _n = n.leftChild
            }
        }

        @inlinable public mutating func next() -> Element? {
            guard let n = stack.popLast() else { return nil }
            descendBranch(n.rightChild)
            return (n.key, n.value)
        }
    }
}

extension BinaryTreeDictionary {

    @inlinable public var first: Element? {
        guard let r = rootNode else { return nil }
        let n = r.first
        return (n.key, n.value)
    }

    @inlinable public var last: Element? {
        guard let r = rootNode else { return nil }
        let n = r.last
        return (n.key, n.value)
    }

    @inlinable public func popFirst() -> Element? {
        guard let r = rootNode else { return nil }
        let n = r.first
        let e = (n.key, n.value)
        rootNode = n.remove()
        return e
    }

    @inlinable public func popLast() -> Element? {
        guard let r = rootNode else { return nil }
        let n = r.last
        let e = (n.key, n.value)
        rootNode = n.remove()
        return e
    }

    @inlinable public func reserveCapacity(_ minimumCapacity: Int) {}
}

extension BinaryTreeDictionary: Encodable where Key: Encodable, Value: Encodable {

    public func encode(to encoder: Encoder) throws {
        try count.encode(to: encoder)
        try forEach {
            try $0.key.encode(to: encoder)
            try $0.value.encode(to: encoder)
        }
    }
}

extension BinaryTreeDictionary: Decodable where Key: Decodable, Value: Decodable {}

extension BinaryTreeDictionary {

    @frozen public struct Keys: Collection, Equatable, Hashable {
        public typealias Element = Key
        public typealias SubSequence = Slice<Keys>
        public typealias Indices = DefaultIndices<Keys>

        @inlinable public var startIndex: Index { tree.startIndex }
        @inlinable public var endIndex:   Index { tree.endIndex }
        @inlinable public var count:      Int { tree.count }
        @inlinable public var isEmpty:    Bool { tree.isEmpty }

        @usableFromInline let tree: BinaryTreeDictionary<Key, Value>

        init(_ tree: BinaryTreeDictionary<Key, Value>) { self.tree = tree }

        @inlinable public func index(after i: Index) -> Index { tree.index(after: i) }

        @inlinable public func formIndex(after i: inout Index) { tree.formIndex(after: &i) }

        @inlinable public subscript(position: Index) -> Element { tree[position].key }

        @inlinable public static func == (lhs: Keys, rhs: Keys) -> Bool {
            guard lhs.count == rhs.count else { return false }
            for key: Key in lhs { guard rhs.contains(key) else { return false } }
            return true
        }

        @inlinable public func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }
    }

    @frozen public struct Values: MutableCollection {
        public typealias Element = Value
        public typealias Indices = DefaultIndices<Values>
        public typealias SubSequence = Slice<Values>

        @inlinable public var startIndex: Index { tree.startIndex }
        @inlinable public var endIndex:   Index { tree.endIndex }
        @inlinable public var count:      Int { tree.count }
        @inlinable public var isEmpty:    Bool { tree.isEmpty }

        @usableFromInline let tree: BinaryTreeDictionary<Key, Value>

        init(_ tree: BinaryTreeDictionary<Key, Value>) { self.tree = tree }

        @inlinable public func index(after i: Index) -> Index { tree.index(after: i) }

        @inlinable public func formIndex(after i: inout Index) { tree.formIndex(after: &i) }

        @inlinable public subscript(position: Index) -> Values.Element {
            get { tree[position].value }
            set { tree.nodeAt(position: position).value = newValue; tree._hashValue = nil }
        }

        @inlinable public mutating func swapAt(_ i: Index, _ j: Index) {
            let nodeI = tree.nodeAt(position: i)
            let nodeJ = tree.nodeAt(position: j)
            swap(&nodeI.value, &nodeJ.value)
            tree._hashValue = nil
        }
    }
}

extension BinaryTreeDictionary.Values: Equatable where Value: Equatable {
    public static func == (lhs: BinaryTreeDictionary.Values, rhs: BinaryTreeDictionary.Values) -> Bool {
        guard lhs.count == rhs.count else { return false }
        for lhsV: Value in lhs { guard rhs.contains(where: { rhsV in lhsV == rhsV }) else { return false } }
        return true
    }
}

extension BinaryTreeDictionary.Values: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) { forEach { hasher.combine($0) } }
}

extension BinaryTreeDictionary: RandomAccessCollection {
    public func formIndex(before i: inout Index) { i = index(after: i) }
}
