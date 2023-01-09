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

    /*==========================================================================================================================================================================*/
    /// Internal class to hold the data for each node of the tree.
    ///
    @usableFromInline class Node: Equatable {
        @usableFromInline enum Color { case Black, Red }

        @usableFromInline enum Side { case Left, Right, Neither }

        @usableFromInline var key:    Key
        @usableFromInline var value:  Value
        @usableFromInline var color:  Color = .Black
        @usableFromInline var count:  Int   = 1
        @usableFromInline var parent: Node? = nil

        /*@f:0==================================================================================================================================================================*/
        @inlinable var left:   Node? { _left                                                                          }
        @inlinable var right:  Node? { _right                                                                         }
        @inlinable var root:   Node  { ((parent == nil) ? self : parent!.root)                                        }
        @inlinable var isRoot: Bool  { parent == nil                                                                  }
        @inlinable var side:   Side  { whenNotNil(parent, { $0._left === self ? .Left : .Right }, else: { .Neither }) }
        @inlinable var index:  Int   { ((side == .Right) ? (pIndex + lCount + 1) : (pIndex - rCount - 1))             }
        @inlinable var pIndex: Int   { (parent?.index ?? 0)                                                           }
        @inlinable var lCount: Int   { (_left?.count ?? 0)                                                            }
        @inlinable var rCount: Int   { (_right?.count ?? 0)                                                           }

        /*@f:1==================================================================================================================================================================*/
        @inlinable init(key k: Key, value v: Value, color c: Color) {
            color = c
            key = k
            value = v
        }

        /*======================================================================================================================================================================*/
        @inlinable subscript(s: Side) -> Node? {
            get { failIfNot(predicate: (s != .Neither), message: ErrMsgIllegalAction) { ((s == .Left) ? _left : _right) } }
            set { add(newChild: newValue, toSide: s) }
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func nodeFor(key k: Key) -> Node? {
            ((key == k) ? self : self[compareKey(toOtherKey: k)]?.nodeFor(key: k))
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func insert(key k: Key, value v: Value) -> Node {
            if key == k {
                value = v
                return self
            }
            let s = compareKey(toOtherKey: k)
            guard let n = self[s] else { return addNew(key: k, value: v, side: s) }
            return n.insert(key: k, value: v)
        }

        /*======================================================================================================================================================================*/
        @inlinable func addNew(key k: Key, value v: Value, side s: Side) -> Node {
            let n = Node(key: k, value: v, color: .Red)
            self[s] = n
            return n.insertBalance().root
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func insertBalance() -> Node {
            if let p = parent {
                if p.color == .Red {
                    if let g = p.parent {
                        let ps = p.side

                        if let u = g[!ps], u.color == .Red {
                            p.color = .Black
                            u.color = .Black
                            g.color = .Red
                            return g.insertBalance()
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
            return self
        }

        /*======================================================================================================================================================================*/
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

        /*======================================================================================================================================================================*/
        @usableFromInline func deleteBalance(parent p: Node) {
            let sd = side
            if let s = p[!sd] {
                if s.color == .Red {
                    p.rotate(sd)
                    guard let s = p[!sd] else { fatalError(String(format: ErrMsgInconsistentState, StrRedBlackDictionary)) }
                    deleteBalance1(parent: p, sibling: s, side: sd)
                }
                else {
                    deleteBalance1(parent: p, sibling: s, side: sd)
                }
            }
        }

        /*======================================================================================================================================================================*/
        @inlinable func deleteBalance1(parent p: Node, sibling s: Node, side sd: Side) {
            if s.color == .Black && (s.left?.color ?? .Black) == .Black && (s.right?.color ?? .Black) == .Black {
                deleteBalance2(parent: p, sibling: s)
            }
            else {
                deleteBalance3(parent: p, sibling: s, side: sd)
            }
        }

        /*======================================================================================================================================================================*/
        @inlinable func deleteBalance2(parent p: Node, sibling s: Node) {
            s.color = .Red
            if p.color == .Red {
                p.color = .Black
            }
            else if let g = p.parent {
                p.deleteBalance(parent: g)
            }
        }

        /*======================================================================================================================================================================*/
        @inlinable func deleteBalance3(parent p: Node, sibling s: Node, side sd: Side) {
            if let c = s[sd], c.color == .Red {
                s.rotate(!sd)
                deleteBalance4(parent: p, sibling: c, side: sd)
            }
            else {
                deleteBalance4(parent: p, sibling: s, side: sd)
            }
        }

        /*======================================================================================================================================================================*/
        @inlinable func deleteBalance4(parent p: Node, sibling s: Node, side sd: Side) {
            if let d = s[!sd], d.color == .Red {
                p.rotate(sd)
                p.color = .Black
                d.color = .Black
            }
        }

        /*======================================================================================================================================================================*/
        @inlinable func rotate(_ dir: Side) {
            guard dir != .Neither else { fatalError(ErrMsgIllegalAction) }
            guard let c = self[!dir] else { fatalError(String(format: ErrMsgCannotRotate, (!dir).description, dir.description)) }
            let cc = c[dir]
            if let p = parent { p[side] = c }
            self[!dir] = cc
            c[dir] = self
            swap(&c.color, &color)
        }

        /*======================================================================================================================================================================*/
        @inlinable func add(newChild: Node?, toSide s: Side) {
            switch s {
                case .Left:
                    guard addSetup(forOldChild: _left, andNewChild: newChild) else { return }
                    _left = newChild
                case .Right:
                    guard addSetup(forOldChild: _right, andNewChild: newChild) else { return }
                    _right = newChild
                case .Neither: fatalError(ErrMsgIllegalAction)
            }

            if let n = newChild {
                if let p = n.parent { p[n.side] = nil }
                n.parent = self
            }

            reCount()
        }

        /*======================================================================================================================================================================*/
        @inlinable func addSetup(forOldChild oc: Node?, andNewChild nc: Node?) -> Bool {
            guard oc !== nc else { return false }
            oc?.parent = nil
            return true
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func reCount() {
            count = (1 + lCount + rCount)
            parent?.reCount()
        }

        /*======================================================================================================================================================================*/
        @inlinable func compareKey(toOtherKey k: Key) -> Side {
            ((key == k) ? .Right : .Left)
        }

        /*======================================================================================================================================================================*/
        @inlinable static func == (lhs: Node, rhs: Node) -> Bool { lhs === rhs }

        /*======================================================================================================================================================================*/
        @usableFromInline var _left:  Node? = nil
        @usableFromInline var _right: Node? = nil
    }
}

extension RedBlackDictionary.Node.Color {
    /*==========================================================================================================================================================================*/
    @inlinable static prefix func ! (_ c: RedBlackDictionary.Node.Color) -> RedBlackDictionary.Node.Color { ((c == .Black) ? .Red : .Black) }
}

extension RedBlackDictionary.Node.Side: CustomStringConvertible {

    /*==========================================================================================================================================================================*/
    @inlinable static prefix func ! (_ s: RedBlackDictionary.Node.Side) -> RedBlackDictionary.Node.Side { ((s == .Left) ? .Right : ((s == .Right) ? .Left : .Neither)) }

    /*==========================================================================================================================================================================*/
    @inlinable var description: String { ((self == .Left) ? StrLeft : ((self == .Right) ? StrRight : StrNeither)) }
}
