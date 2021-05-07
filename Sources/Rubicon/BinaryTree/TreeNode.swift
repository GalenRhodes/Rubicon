/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: TreeNode.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/11/21
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
import CoreFoundation

fileprivate let ErrorInconsistentState: String = "Binary tree is in an inconsistent state:"
fileprivate let ErrorMustHaveSibling:   String = "A black non-root node must have a sibling."
fileprivate let ErrorCannotRotateLeft:  String = "Cannot rotate node to the left. Right child node is missing."
fileprivate let ErrorCannotRotateRight: String = "Cannot rotate node to the right. Left child node is missing."

/*==============================================================================================================*/
/// Implements a single node for a classic Red/Black Binary Tree.
///
open class TreeNode<K: Comparable & Hashable, V> {
    //@f:0
    public enum Color { case Black, Red }
    public enum Side  { case Orphan, Left, Right }

    public fileprivate(set)      var count:      Int             = 1
    public fileprivate(set)      var color:      Color           = .Red
    public fileprivate(set) weak var parent:     TreeNode<K, V>? = nil
    public fileprivate(set)      var leftChild:  TreeNode<K, V>? = nil
    public fileprivate(set)      var rightChild: TreeNode<K, V>? = nil
    public fileprivate(set)      var key:        K
    public                       var value:      V

    @inlinable public var sibling:     TreeNode<K, V>? { parent?.getChild(fromThe: !side)                    }
    @inlinable public var grandfather: TreeNode<K, V>? { parent?.parent                                      }
    @inlinable public var uncle:       TreeNode<K, V>? { parent?.sibling                                     }
    @inlinable public var rootNode:    TreeNode<K, V>  { (parent?.rootNode ?? self)                          }
    @inlinable public var first:       TreeNode<K, V>  { (leftChild?.first ?? self)                          }
    @inlinable public var last:        TreeNode<K, V>  { (rightChild?.last ?? self)                          }
    @inlinable public var isRoot:      Bool            { (parent == nil)                                     }
    @inlinable public var index:       Int             { (isRoot ? ccLeft : (side.isLeft ? lIndex : rIndex)) }
    @inlinable public var side:        Side            { Side.side(self)                                     }

    @inlinable var ccLeft:  Int { (leftChild?.count ?? 0)  }
    @inlinable var ccRight: Int { (rightChild?.count ?? 0) }
    @inlinable var pIndex:  Int { (parent?.index ?? 0)     }
    @inlinable var lIndex:  Int { (pIndex - ccRight - 1)   }
    @inlinable var rIndex:  Int { (pIndex + ccLeft + 1)    }
    //@f:1

    public init(key: K, value: V) {
        self.key = key
        self.value = value
        self.color = .Black
    }

    private init(key: K, value: V, parent: TreeNode<K, V>) {
        self.key = key
        self.value = value
        self.color = .Red
        self.parent = parent
    }

    deinit {
        nDebug(.None, "Node \"\(key)\" going away.")
    }

    public subscript(key: K) -> TreeNode<K, V>? {
        switch self.key <=> key {
            case .EqualTo:     return self
            case .LessThan:    return rightChild?[key]
            case .GreaterThan: return leftChild?[key]
        }
    }

    public subscript(position: BinaryTreeDictionary<K, V>.Index) -> TreeNode<K, V>? {
        getBy(index: position.value)
    }

    public func getBy(index: Int) -> TreeNode<K, V>? {
        switch self.index <=> index {
            case .EqualTo:     return self
            case .LessThan:    return rightChild?.getBy(index: index)
            case .GreaterThan: return leftChild?.getBy(index: index)
        }
    }

    public func forEach(execute body: (TreeNode<K, V>) throws -> Void) rethrows {
        if let c = leftChild { try c.forEach(execute: body) }
        try body(self)
        if let c = rightChild { try c.forEach(execute: body) }
    }

    public func forEachReversed(execute body: (TreeNode<K, V>) throws -> Void) rethrows {
        if let c = rightChild { try c.forEach(execute: body) }
        try body(self)
        if let c = leftChild { try c.forEach(execute: body) }
    }

    public func add(key: K, value: V) -> TreeNode<K, V> {
        switch self.key <=> key {
            case .EqualTo:
                self.value = value
                return rootNode
            case .LessThan:
                if let r = rightChild { return r.add(key: key, value: value) }
                rightChild = TreeNode<K, V>(key: key, value: value, parent: self)
                recount()
                return rightChild!.addRebalance()
            case .GreaterThan:
                if let l = leftChild { return l.add(key: key, value: value) }
                leftChild = TreeNode<K, V>(key: key, value: value, parent: self)
                recount()
                return leftChild!.addRebalance()
        }
    }

    private func addRebalance() -> TreeNode<K, V> {
        guard let p = parent else { setBlack(nodes: self); return self }
        guard areRed(nodes: p) else { return rootNode }
        guard let g = p.parent else { setBlack(nodes: p); return p }
        guard let u = uncle, areRed(nodes: u) else { return addRebalance2(parent: p, grandparent: g) }
        setBlack(nodes: p, u)
        setRed(nodes: g)
        return g.addRebalance()
    }

    private func addRebalance2(parent p: TreeNode<K, V>, grandparent g: TreeNode<K, V>) -> TreeNode<K, V> {
        let pSide = p.side
        if (side == !pSide) { p.rotate(toThe: pSide); g.rotate(toThe: !pSide) }
        else { g.rotate(toThe: !pSide) }
        return rootNode
    }

    public func remove() -> TreeNode<K, V>? {
        if let _ = leftChild, let r = rightChild?.first {
            key = r.key
            value = r.value
            return r.remove()
        }
        else if let c = (leftChild ?? rightChild) {
            ifNil(parent, then: { c.makeOrphan() }, elseThen: { $0.set(child: c, on: side) })
            setBlack(nodes: c)
            c.recount()
            return c.rootNode
        }
        else if let p = parent {
            if areBlack(nodes: self) { removeRebalance(parent: p) }
            makeOrphan()
            p.recount()
            return p.rootNode
        }
        return nil
    }

    private func removeRebalance(parent p: TreeNode<K, V>) {
        guard var s = sibling else { fail(errorMessage: ErrorMustHaveSibling) }
        let nSide = side
        if areRed(nodes: s) {
            p.rotate(toThe: nSide)
            s = p.getChild(fromThe: nSide, errorMessage: ErrorMustHaveSibling)
        }
        if areBlack(nodes: s, s.leftChild, s.rightChild) {
            setRed(nodes: s)
            if areBlack(nodes: p) { if let g = p.parent { p.removeRebalance(parent: g) } }
            else { setBlack(nodes: p) }
        }
        else {
            if areRed(nodes: s.getChild(fromThe: nSide)) {
                s.rotate(toThe: !nSide)
                s = p.getChild(fromThe: nSide, errorMessage: ErrorMustHaveSibling)
            }
            setBlack(nodes: s.getChild(fromThe: !nSide))
            p.rotate(toThe: nSide)
        }
    }

    private func makeOrphan() { parent?.foo(nil, on: side) }

    private func set(child: TreeNode<K, V>?, on side: Side) {
        guard !side.isOrphan else { return }
        getChild(fromThe: side)?.makeOrphan()
        child?.makeOrphan()
        foo(child, on: side)
    }

    private func foo(_ node: TreeNode<K, V>?, on side: Side) {
        if side.isLeft { leftChild = node }
        else { rightChild = node }
        node?.parent = self
    }

    @usableFromInline func getChild(fromThe side: Side) -> TreeNode<K, V>? { (side.isLeft ? leftChild : (side.isRight ? rightChild : nil)) }

    private func getChild(fromThe side: Side, errorMessage msg: String) -> TreeNode<K, V> {
        if let c = getChild(fromThe: side) { return c }
        fail(errorMessage: msg)
    }

    private func fail(errorMessage msg: String) -> Never {
        fatalError("\(ErrorInconsistentState) \(msg)")
    }

    /*==========================================================================================================*/
    /// Rotate this node to either the left or the right according to the boolean value given for `toTheLeft`.
    /// 
    /// NOTE: This method will automatically adjust the counts for all involved nodes so there is no need to do a
    /// recount after calling this method.
    /// 
    /// - Parameter l: If `true` then this node will be rotated to the left. If `false` it will be rotated to the
    ///                right.
    ///
    private func rotate(toThe side: Side) {
        let nSide = side
        guard let c = getChild(fromThe: !nSide) else { fail(errorMessage: nSide.isLeft ? ErrorCannotRotateLeft : ErrorCannotRotateRight) }
        c.makeOrphan()
        parent?.set(child: c, on: nSide)
        set(child: c.getChild(fromThe: nSide), on: !nSide)
        c.set(child: self, on: nSide)
        localRecount()
        c.localRecount()
        swap(&color, &c.color)
    }

    private func recount() {
        localRecount()
        if let p = parent { p.recount() }
    }

    private func localRecount() {
        count = (1 + ccLeft + ccRight)
    }

    @discardableResult func hardRecount() -> Int {
        count = 1
        if let l = leftChild { count += l.hardRecount() }
        if let r = rightChild { count += r.hardRecount() }
        return count
    }
}

extension TreeNode: Equatable where V: Equatable {
    public static func == (lhs: TreeNode<K, V>, rhs: TreeNode<K, V>) -> Bool { (lhs === rhs) }
}

extension TreeNode: Hashable where V: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }

    public var hashValue: Int {
        var hasher: Hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension TreeNode: Encodable where K: Encodable, V: Encodable {

    public func encode(to encoder: Encoder) throws {
        try key.encode(to: encoder)
        try value.encode(to: encoder)
    }
}

fileprivate func areRed<K, V>(nodes: TreeNode<K, V>?...) -> Bool {
    for nn in nodes { if (nn !== nil) && (nn!.color == .Red) { return false } }
    return true
}

fileprivate func areBlack<K, V>(nodes: TreeNode<K, V>?...) -> Bool {
    for nn in nodes { if let n = nn, n.color == .Red { return false } }
    return true
}

fileprivate func setBlack<K, V>(nodes: TreeNode<K, V>?...) { nodes.forEach { if let n = $0 { n.color = .Black } } }

fileprivate func setRed<K, V>(nodes: TreeNode<K, V>?...) { nodes.forEach { if let n = $0 { n.color = .Red } } }

extension TreeNode.Side {
    @inlinable public var isLeft:   Bool { (self == .Left) }
    @inlinable public var isRight:  Bool { (self == .Right) }
    @inlinable public var isOrphan: Bool { (self == .Orphan) }

    @inlinable public static prefix func ! (side: TreeNode.Side) -> TreeNode.Side { (side.isLeft ? .Right : (side.isRight ? .Left : .Orphan)) }

    @inlinable static func side(_ node: TreeNode) -> TreeNode.Side {
        guard let p = node.parent else { return .Orphan }
        if node === p.leftChild { return .Left }
        return .Right
    }
}
