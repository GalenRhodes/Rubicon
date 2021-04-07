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

open class BinaryTreeDictionary<K: Comparable & Hashable, V>: Sequence, ExpressibleByDictionaryLiteral, Collection {

    public typealias Element = (key: K, value: V)
    public typealias Index = Int

    //@f:0
    public var isEmpty:    Bool  { (rootNode == nil)                         }
    public var count:      Int   { ((rootNode == nil) ? 0 : rootNode!.count) }
    public var startIndex: Index { 0                                         }
    public var endIndex:   Index { count                                     }
    //@f:1

    var rootNode: BinaryTreeNode<K, V>? = nil

    public init() {}

    required public init(dictionaryLiteral elements: (K, V)...) {
        for e in elements { self[e.0] = e.1 }
    }

    open subscript(position: Index) -> Element {
        let n = nodeAtIndex(position: position)
        return (n.key, n.value)
    }

    func nodeAtIndex(position: Index) -> BinaryTreeNode<K, V> {
        guard position >= startIndex && position < endIndex else { fatalError("Index out of bounds.") }
        guard let n = rootNode?.node(for: position) else { fatalError("Index out of bounds.") }
        return n
    }

    open subscript(key: K) -> V? {
        set {
            if let value = newValue {
                if let r = rootNode { rootNode = r.insert(key: key, value: value) }
                else { rootNode = BinaryTreeNode(key: key, value: value, color: .Black) }
            }
            else if let r = rootNode, let n = r.find(key: key) {
                rootNode = n.remove()
            }
        }
        get { rootNode?.find(key: key)?.value }
    }

    open func index(after i: Int) -> Int {
        guard i >= 0 && i < endIndex else { fatalError("Index out of bounds.") }
        return (i + 1)
    }

    @frozen public struct Iterator: IteratorProtocol {

        public typealias Element = (key: K, value: V)

        var stack: [BinaryTreeNode<K, V>] = []

        init(_ rootNode: BinaryTreeNode<K, V>?) {
            pushStack(node: rootNode)
        }

        mutating func pushStack(node: BinaryTreeNode<K, V>?) {
            if var r = node {
                stack.append(r)
                while let c = r.leftNode {
                    stack.append(c)
                    r = c
                }
            }
        }

        public mutating func next() -> Element? {
            guard let nextNode = stack.popLast() else { return nil }
            pushStack(node: nextNode.rightNode)
            return (nextNode.key, nextNode.value)
        }
    }

    public func makeIterator() -> BinaryTreeDictionary<K, V>.Iterator { Iterator(rootNode) }
}

extension BinaryTreeDictionary {

    public func popFirst() -> BinaryTreeDictionary<K, V>.Element? {
        if var n = rootNode {
            while let c = n.leftNode { n = c }
            rootNode = n.remove()
            return (n.key, n.value)
        }
        return nil
    }

    public func popLast() -> BinaryTreeDictionary<K, V>.Element? {
        if var n = rootNode {
            while let c = n.rightNode { n = c }
            rootNode = n.remove()
            return (n.key, n.value)
        }
        return nil
    }

    public var capacity: Int { Int.max }

    public func reserveCapacity(_ minimumCapacity: Int) {}
}

extension BinaryTreeDictionary {

    public var keys:   BinaryTreeDictionary<K, V>.Keys { Keys(binaryTree: self) }
    public var values: BinaryTreeDictionary<K, V>.Values { Values(binaryTree: self) }

    @frozen public struct Keys: Collection, Equatable, CustomStringConvertible, CustomDebugStringConvertible {

        public typealias Element = K
        public typealias SubSequence = Slice<BinaryTreeDictionary<K, V>.Keys>
        public typealias Index = BinaryTreeDictionary<K, V>.Index
        public typealias Indices = DefaultIndices<BinaryTreeDictionary<K, V>.Keys>

        let tree: BinaryTreeDictionary<K, V>

        public var description:      String { "" }
        public var debugDescription: String { "" }

        public var startIndex: BinaryTreeDictionary<K, V>.Index { tree.startIndex }
        public var endIndex:   BinaryTreeDictionary<K, V>.Index { tree.endIndex }
        public var count:      Int { tree.count }
        public var isEmpty:    Bool { tree.isEmpty }

        init(binaryTree: BinaryTreeDictionary<K, V>) { tree = binaryTree }

        public func index(after i: BinaryTreeDictionary<K, V>.Index) -> BinaryTreeDictionary<K, V>.Index { tree.index(after: i) }

        public func formIndex(after i: inout BinaryTreeDictionary<K, V>.Index) { tree.formIndex(after: &i) }

        public subscript(position: BinaryTreeDictionary<K, V>.Index) -> BinaryTreeDictionary<K, V>.Keys.Element { tree.nodeAtIndex(position: position).key }

        public static func == (lhs: BinaryTreeDictionary<K, V>.Keys, rhs: BinaryTreeDictionary<K, V>.Keys) -> Bool {
            guard !(lhs.isEmpty && rhs.isEmpty) else { return true }
            guard lhs.count == rhs.count else { return false }

            var iLhs = lhs.startIndex
            var iRhs = rhs.startIndex

            while iLhs < lhs.endIndex {
                if lhs[iLhs] != rhs[iRhs] { return false }
                iLhs = lhs.index(after: iLhs)
                iRhs = rhs.index(after: iRhs)
            }

            return true
        }
    }

    @frozen public struct Values: MutableCollection, CustomStringConvertible, CustomDebugStringConvertible {

        public typealias Element = V
        public typealias Index = BinaryTreeDictionary<K, V>.Index
        public typealias SubSequence = Slice<BinaryTreeDictionary<K, V>.Values>
        public typealias Indices = DefaultIndices<BinaryTreeDictionary<K, V>.Values>

        let tree: BinaryTreeDictionary<K, V>

        public var description:      String { "" }
        public var debugDescription: String { "" }

        public var startIndex: BinaryTreeDictionary<K, V>.Index { tree.startIndex }
        public var endIndex:   BinaryTreeDictionary<K, V>.Index { tree.endIndex }
        public var count:      Int { tree.count }
        public var isEmpty:    Bool { tree.isEmpty }

        init(binaryTree: BinaryTreeDictionary<K, V>) { tree = binaryTree }

        public func index(after i: BinaryTreeDictionary<K, V>.Index) -> BinaryTreeDictionary<K, V>.Index { tree.index(after: i) }

        public func formIndex(after i: inout BinaryTreeDictionary<K, V>.Index) { tree.formIndex(after: &i) }

        public mutating func swapAt(_ i: BinaryTreeDictionary<K, V>.Index, _ j: BinaryTreeDictionary<K, V>.Index) {
            let n1 = tree.nodeAtIndex(position: i)
            let n2 = tree.nodeAtIndex(position: j)
            swap(&n1.value, &n2.value)
        }

        public subscript(position: BinaryTreeDictionary<K, V>.Index) -> BinaryTreeDictionary<K, V>.Values.Element {
            get { tree.nodeAtIndex(position: position).value }
            set { tree.nodeAtIndex(position: position).value = newValue }
        }
    }
}

extension BinaryTreeDictionary: Equatable where V: Equatable {

    public static func == (lhs: BinaryTreeDictionary<K, V>, rhs: BinaryTreeDictionary<K, V>) -> Bool {
        guard !(lhs.isEmpty && rhs.isEmpty) else { return true }
        guard lhs.count == rhs.count else { return false }
        var itLhs = lhs.makeIterator()
        var itRhs = rhs.makeIterator()

        while let e1 = itLhs.next(), let e2 = itRhs.next() {
            if e1.key != e2.key || e1.value != e2.value { return false }
        }

        return true
    }
}

extension BinaryTreeDictionary: Hashable where V: Hashable {

    public func hash(into hasher: inout Hasher) {
        if let r = rootNode {
            var cc = 0
            _ = r.iterate { (n: BinaryTreeNode<K, V>) -> Bool? in
                guard cc < 1000 else { return true }
                hasher.combine(n)
                cc++
                return nil
            }
        }
    }
}
