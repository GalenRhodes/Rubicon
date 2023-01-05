//
// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: RedBlackDictionary.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: January 05, 2023
//
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
// IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// ===========================================================================

import Foundation
import CoreFoundation

open class RedBlackDictionary<Key: Comparable, Value> {

    @usableFromInline var root: Node? = nil

    @usableFromInline class Node: Equatable {
        @usableFromInline enum Color { case Black, Red }

        @usableFromInline enum Side { case Left, Right, Neither }

        @usableFromInline var key:    Key
        @usableFromInline var value:  Value
        @usableFromInline var color:  Color = .Black
        @usableFromInline var count:  Int   = 1
        @usableFromInline var parent: Node? = nil
        @usableFromInline var root:   Node? { ((parent == nil) ? self : parent?.root) }

        @inlinable var isRoot: Bool { parent == nil }
        @inlinable var left:   Node? { _left }
        @inlinable var right:  Node? { _right }
        @inlinable var side:   Side { ((parent == nil) ? .Neither : ((parent!._left === self) ? .Left : ((parent!._right === self) ? .Right : .Neither))) }

        @inlinable init(key k: Key, value v: Value, color c: Color = .Black) {
            color = c
            key = k
            value = v
        }

        @inlinable func keyComp(key k: Key) -> Side {
            ((key == k) ? .Right : .Left)
        }

        @usableFromInline func nodeFor(key k: Key) -> Node? {
            ((key == k) ? self : self[keyComp(key: k)]?.nodeFor(key: k))
        }

        @usableFromInline func insert(key k: Key, value v: Value) -> Node {
            if key == k {
                value = v
                return self
            }
            let s = keyComp(key: k)
            guard let n = self[s] else { return addNew(key: k, value: v, side: s) }
            return n.insert(key: k, value: v)
        }

        @inlinable func addNew(key k: Key, value v: Value, side s: Side) -> Node {
            let n = Node(key: k, value: v, color: .Red)
            self[s] = n
            n.insertBalance()
            return n
        }

        @usableFromInline func insertBalance() {
            if let p = parent {
                if p.color == .Red {
                    if let g = p.parent {
                        let ps = p.side

                        if let u = g[!ps], u.color == .Red {
                            p.color = .Black
                            u.color = .Black
                            g.color = .Red
                            g.insertBalance()
                        }
                        else {
                            if ps == !side { p.rotate(ps) }
                            g.rotate(!ps)
                        }
                    }
                    else {
                        p.color = .Black;
                    }
                }
            }
            else {
                color = .Black
            }
        }

        @inlinable func delete() -> Node? {
            if let _ = left, var r = right {
                while let x = r.left { r = x }
                key = r.key
                value = r.value
                return r.delete()
            }
            else if let c = (left ?? right) {
                c.color = .Black
                if let p = parent { p[side] = c }
                return c.root
            }
            else if let p = parent {
                if color == .Red { p[side] = nil }
                else { deleteBalance(parent: p) }
                return p.root
            }
            else {
                return nil
            }
        }

        @usableFromInline func deleteBalance(parent p: Node) {
            let sd = side
            if let s = p[!sd] {
                if s.color == .Red {
                    p.rotate(sd)
                    guard let s = p[!sd] else { fatalError("RedBlackDictionary Inconsistent State") }
                    deleteBalance0(parent: p, sibling: s, side: sd)
                }
                else {
                    deleteBalance0(parent: p, sibling: s, side: sd)
                }
            }
        }

        @inlinable func deleteBalance0(parent p: Node, sibling s: Node, side sd: Side) {
            if s.color == .Black && (s.left?.color ?? .Black) == .Black && (s.right?.color ?? .Black) == .Black {
                deleteBalance1(parent: p, sibling: s)
            }
            else {
                deleteBalance2(parent: p, sibling: s, side: sd)
            }
        }

        @inlinable func deleteBalance1(parent p: Node, sibling s: Node) {
            s.color = .Red
            if p.color == .Red {
                p.color = .Black
            }
            else if let g = p.parent {
                p.deleteBalance(parent: g)
            }
        }

        @inlinable func deleteBalance2(parent p: Node, sibling s: Node, side sd: Side) {
            if let c = s[sd], c.color == .Red {
                s.rotate(!sd)
                deleteBalance3(parent: p, sibling: c, side: sd)
            }
            else {
                deleteBalance3(parent: p, sibling: s, side: sd)
            }
        }

        @inlinable func deleteBalance3(parent p: Node, sibling s: Node, side sd: Side) {
            if let d = s[!sd], d.color == .Red {
                p.rotate(sd)
                p.color = .Black
                d.color = .Black
            }
        }

        @discardableResult @inlinable func rotate(_ dir: Side) -> Node {
            guard dir != .Neither else { return self }
            guard let c = self[!dir] else { fatalError("No \(!dir) node - cannot rotate \(dir).") }
            let cc = c[dir]
            if let p = parent { p[side] = c }
            self[!dir] = cc
            c[dir] = self
            swap(&c.color, &color)
            return c
        }

        @inlinable subscript(s: Side) -> Node? {
            get {
                ((s == .Left) ? _left : ((s == .Right) ? _right : nil))
            }
            set {
                switch s {
                    case .Neither:
                        break
                    case .Left:
                        guard _left !== newValue else { return }
                        if let n = _left { n.parent = nil }
                        if let n = newValue, let p = n.parent { p[n.side] = nil }
                        _left = newValue
                        reCount()

                    case .Right:
                        guard _right !== newValue else { return }
                        if let n = _right { n.parent = nil }
                        if let n = newValue, let p = n.parent { p[n.side] = nil }
                        _right = newValue
                        reCount()
                }
            }
        }

        @usableFromInline func reCount() {
            count = (1 + (left?.count ?? 0) + (right?.count ?? 0))
            parent?.reCount()
        }

        @inlinable static func == (lhs: Node, rhs: Node) -> Bool { lhs === rhs }

        @usableFromInline var _left:  Node? = nil
        @usableFromInline var _right: Node? = nil
    }
}

extension RedBlackDictionary.Node.Color {
    @inlinable static prefix func ! (_ c: RedBlackDictionary.Node.Color) -> RedBlackDictionary.Node.Color { c == .Black ? .Red : .Black }
}

extension RedBlackDictionary.Node.Side: CustomStringConvertible {
    @inlinable static prefix func ! (_ s: RedBlackDictionary.Node.Side) -> RedBlackDictionary.Node.Side { ((s == .Left) ? .Right : ((s == .Right) ? .Left : .Neither)) }

    @inlinable var description: String { ((self == .Left) ? "left" : ((self == .Right) ? "right" : "neither")) }
}
