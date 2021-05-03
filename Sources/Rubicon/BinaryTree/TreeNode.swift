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

/*==============================================================================================================*/
/// Implements a single node for a classic Red/Black Binary Tree.
///
open class TreeNode<K: Comparable & Hashable, V> {
    public enum Color { case Black, Red }

    //@f:0
    public private(set)      var count:      Int             = 1
    public private(set)      var color:      Color           = .Red
    public private(set) weak var parent:     TreeNode<K, V>? = nil
    public private(set)      var leftChild:  TreeNode<K, V>? = nil
    public private(set)      var rightChild: TreeNode<K, V>? = nil
    public private(set)      var key:        K
    public                   var value:      V

    public var grandFather: TreeNode<K, V>? { parent?.parent }
    public var sibling:     TreeNode<K, V>? { ((self === parent?.leftChild) ? parent?.rightChild : ((self === parent?.rightChild) ? parent?.leftChild : nil)) }
    public var uncle:       TreeNode<K, V>? { parent?.sibling }
    public var rootNode:    TreeNode<K, V>  { (parent?.rootNode ?? self) }

    private var foo: TreeNode<K, V> { (leftChild?.foo ?? self) }
    //@f:1

    public init(key: K, value: V, color: Color = .Red) {
        self.key = key
        self.value = value
        self.color = color
    }

    public subscript(key: K) -> TreeNode<K, V>? {
        switch self.key <=> key {
            case .EqualTo:     return self
            case .LessThan:    return rightChild?[key]
            case .GreaterThan: return leftChild?[key]
        }
    }

    public func add(key: K, value: V) -> TreeNode<K, V> {
        switch self.key <=> key {
            case .EqualTo:
                self.value = value
                return rootNode
            case .LessThan:
                if let r = rightChild { return r.add(key: key, value: value) }
                rightChild = TreeNode<K, V>(key: key, value: value)
                rightChild!.parent = self
                recount()
                return rightChild!.add01()
            case .GreaterThan:
                if let l = leftChild { return l.add(key: key, value: value) }
                leftChild = TreeNode<K, V>(key: key, value: value)
                leftChild!.parent = self
                recount()
                return leftChild!.add01()
        }
    }

    public func remove() -> TreeNode<K, V>? {
        if let _ = leftChild, let r = rightChild { return rem01(node: r.foo) }
        else if let p = parent { return rem02(parent: p) }
        else if let c = (leftChild ?? rightChild) { return rem05(child: c) }
        else { return nil }
    }

    private func add01() -> TreeNode<K, V> {
        guard let p = parent else { return add02() }
        guard isRed(node: p) else { return rootNode }
        guard let g = p.parent else { return p.add02() }

        let nRight = (self === p.rightChild)
        let pLeft  = (p === g.leftChild)

        if let u = (pLeft ? g.rightChild : g.leftChild), isRed(node: u) {
            p.color = .Black
            u.color = .Black
            g.color = .Red
            return g.add01()
        }

        if (nRight == pLeft) {
            p.rotate(left: nRight)
            g.rotate(left: !nRight)
        }
        else {
            g.rotate(left: nRight)
        }

        return rootNode
    }

    private func add02() -> TreeNode<K, V> {
        color = .Black
        return self
    }

    private func rem01(node: TreeNode<K, V>) -> TreeNode<K, V>? {
        key = node.key
        value = node.value
        return node.remove()
    }

    private func rem02(parent p: TreeNode<K, V>) -> TreeNode<K, V> {
        if let c = (leftChild ?? rightChild) { rem03(parent: p, child: c) }
        else { rem04(parent: p) }
        p.recount()
        return p.rootNode
    }

    private func rem03(parent p: TreeNode<K, V>, child c: TreeNode<K, V>) {
        leftChild = nil
        rightChild = nil
        rem07(parent: p, child: c)
    }

    private func rem04(parent p: TreeNode<K, V>) {
        if isBlack(node: self) { rem09(parent: p) }
        rem08(parent: p, child: nil)
    }

    private func rem05(child c: TreeNode<K, V>) -> TreeNode<K, V>? {
        leftChild = nil
        rightChild = nil
        return rem06(child: c)
    }

    private func rem06(child c: TreeNode<K, V>) -> TreeNode<K, V> {
        c.parent = nil
        c.quickRecount()
        return add02()
    }

    private func rem07(parent p: TreeNode<K, V>, child c: TreeNode<K, V>) {
        rem08(parent: p, child: c)
        c.parent = p
        c.color = .Black
    }

    private func rem08(parent p: TreeNode<K, V>, child c: TreeNode<K, V>?) {
        if self === p.leftChild { p.leftChild = c }
        else { p.rightChild = c }
        parent = nil
    }

    private func rem09(parent p: TreeNode<K, V>) {
        let l = (self === p.leftChild)
        guard let s = (l ? p.rightChild : p.leftChild) else { return }
        if isRed(node: s) { rem10(parent: p, isLeft: l) }
        else { rem11(parent: p, sibling: s, isLeft: l) }
    }

    private func rem10(parent p: TreeNode<K, V>, isLeft l: Bool) {
        p.rotate(left: l)
        if let s = (l ? p.rightChild : p.leftChild) { rem11(parent: p, sibling: s, isLeft: l) }
    }

    private func rem11(parent p: TreeNode<K, V>, sibling s: TreeNode<K, V>, isLeft l: Bool) {
        if isBlack(node: s) && isBlack(node: s.leftChild) && isBlack(node: s.rightChild) { rem12(parent: p, sibling: s) }
        else if isRed(node: (l ? s.leftChild : s.rightChild)) { rem13(parent: p, sibling: s, isLeft: l) }
        else { rem14(parent: p, sibling: s, isLeft: l) }
    }

    private func rem12(parent p: TreeNode<K, V>, sibling s: TreeNode<K, V>) {
        s.color = .Red
        if isBlack(node: p) { if let g = p.parent { p.rem09(parent: g) } }
        else { p.color = .Black }
    }

    private func rem13(parent p: TreeNode<K, V>, sibling s: TreeNode<K, V>, isLeft l: Bool) {
        s.rotate(left: !l)
        if let s = (l ? p.rightChild : p.leftChild) { rem14(parent: p, sibling: s, isLeft: l) }
    }

    private func rem14(parent p: TreeNode<K, V>, sibling s: TreeNode<K, V>, isLeft l: Bool) {
        setBlack(node: (l ? s.rightChild : s.leftChild))
        p.rotate(left: l)
    }

    private func rotate(left: Bool) {
        guard let c = (left ? rightChild : leftChild) else { fatalError("Cannot rotate \(left ? "left" : "right"). No \(left ? "right" : "left") child node.") }
        c.parent = nil
        if left { rightChild = nil }
        else { leftChild = nil }
        count -= c.count
        // c is now an orphan.

        if let p = parent {
            if self === p.leftChild { p.leftChild = c }
            else { p.rightChild = c }
            c.parent = p
            parent = nil
            // I am now an orphan.
        }

        // If c has a left child, put it on my right side.
        if let cc = (left ? c.leftChild : c.rightChild) {
            if left { rightChild = cc }
            else { leftChild = cc }
            cc.parent = self
            c.count -= cc.count
            count += cc.count
        }

        // Make me c's left child.
        if left { c.leftChild = self }
        else { c.rightChild = self }
        parent = c
        c.count += count

        // Finally swap our colors.
        swap(&color, &c.color)
    }

    private func recount() {
        quickRecount()
        parent?.recount()
    }

    private func quickRecount() { count = (1 + (leftChild?.count ?? 0) + (rightChild?.count ?? 0)) }

    private func isRed(node: TreeNode<K, V>?) -> Bool { ((node != nil) && (node!.color == .Red)) }

    private func isBlack(node: TreeNode<K, V>?) -> Bool { ((node == nil) || (node!.color == .Black)) }

    private func setBlack(node: TreeNode<K, V>?) { node?.color = .Black }
}
