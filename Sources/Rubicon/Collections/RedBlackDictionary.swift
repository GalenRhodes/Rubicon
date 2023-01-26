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

open class RedBlackDictionary<Key: Comparable, Value>: RandomAccessCollection {
    public typealias Element = (key: Key, value: Value)

/*@f0*/
    @usableFromInline var root: Node?  = nil
    @usableFromInline let lock: NSLock = NSLock()

    public let startIndex: Index = Index(0)

    @inlinable public var endIndex: Index { Index(count)       }
    @inlinable public var count:    Int   { (root?.count ?? 0) }
/*@f1*/

    @inlinable public subscript(position: Index) -> Element {
        guard (startIndex ..< endIndex).contains(position) else { fatalError(ErrMsgIndexOutOfBounds) }
        guard let node: Node = root else { fatalError(ErrMsgIndexOutOfBounds) }
        let n = node[position]
        return (key: n.key, value: n.value)
    }

    @inlinable public subscript(k: Key) -> Value? {
        get { ifVal(root, notNil: { (r: Node) in ifVal(r[k], notNil: { (n: Node) in n.value }) }) }
        set { root = ifVal(newValue, notNil: { addValue(k, $0) }, else: { deleteValue(k) }) }
    }

    @inlinable public func enumerate(using action: (Index, Element, inout Bool) throws -> Void) rethrows {
        var stop: Bool = false
        _ = try root?.enumerate(stop: &stop) { n, f in try action(Index(n.index), (key: n.key, value: n.value), &f) }
    }

    @inlinable func addValue(_ key: Key, _ value: Value) -> Node {
        ifVal(root, notNil: { $0.insert(key: key, value: value) }, else: { Node(key: key, value: value, color: .Black) })
    }

    @inlinable func deleteValue(_ key: Key) -> Node? {
        ifVal(ifVal(root, notNil: { $0[key] }), notNil: { $0.delete() }, else: { root })
    }

    /*==========================================================================================================================================================================*/
    /// Internal class to hold the data for each node of the tree.
    ///
    @usableFromInline class Node {
        @usableFromInline enum Color { case Black, Red }

        @usableFromInline enum Side { case Left, Right, Neither }

        @usableFromInline var key:    Key
        @usableFromInline var value:  Value
        @usableFromInline var color:  Color
        @usableFromInline var count:  Int   = 1
        @usableFromInline var parent: Node? = nil
        @usableFromInline var left:   Node? = nil
        @usableFromInline var right:  Node? = nil

        /*@f:0==================================================================================================================================================================*/
        @usableFromInline var root:    Node  { withParent(do: { $0.root }, else: self)                                                        }
        @usableFromInline var farLeft: Node  { withChild(onSide: .Left, do: { $0.farLeft }, else: self)                                       }
        @inlinable        var sibling: Node? { withParent(do: { ((self === $0.left) ? $0.right : $0.left) }, else: nil)                       }
        @inlinable        var side:    Side  { withParent(do: { (self === $0.left) ? .Left : .Right }, else: .Neither)                        }
        @inlinable        var index:   Int   { withParent(do: { ((self === $0.left) ? ($0.index - rc - 1) : ($0.index + lc + 1)) }, else: lc) }
        @inlinable        var lc:      Int   { withChild(onSide: .Left, do: { $0.count }, else: 0)                                            }
        @inlinable        var rc:      Int   { withChild(onSide: .Right, do: { $0.count }, else: 0)                                           }

        /*@f:1==================================================================================================================================================================*/
        @inlinable init(key k: Key, value v: Value, color c: Color) {
            color = c
            key = k
            value = v
        }

        /*======================================================================================================================================================================*/
        @usableFromInline subscript(idx: Index) -> Node {
            switch idx {
                case let i where i < index: if let n = left { return n[i] }
                case let i where i > index: if let n = right { return n[i] }
                default: return self
            }
            fatalError(ErrMsgIndexOutOfBounds)
        }

        /*======================================================================================================================================================================*/
        @usableFromInline subscript(k: Key) -> Node? {
            switch compareKey(to: k) {
                case .Neither: return self
                case let s:    return self[s]?[k]
            }
        }

        /*======================================================================================================================================================================*/
        @inlinable subscript(s: Side) -> Node? {
            get { fatal(if: (s == .Neither), message: ErrMsgIllegalAction, else: ((s == .Left) ? left : right)) }
            set { set(node: newValue, onSide: s) }
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func insert(key k: Key, value v: Value) -> Node {
            switch compareKey(to: k) {
                case .Neither:
                    value = v
                    return root
                case let s:
                    if let n = self[s] { return n.insert(key: k, value: v) }
                    let n = Node(key: k, value: v, color: .Red)
                    self[s] = n
                    return n.insertBalance().root
            }
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func enumerate(stop f: inout Bool, using action: (Node, inout Bool) throws -> Void) rethrows -> Bool {
            if try (f || (left?.enumerate(stop: &f, using: action) ?? f)) { return true }
            try action(self, &f)
            return try (f || (right?.enumerate(stop: &f, using: action) ?? f))
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func insertBalance() -> Node {
            if let p = parent { return insertBalance01(p) }
            color = .Black
            return self
        }

        @inlinable func insertBalance01(_ p: Node) -> Node {
            if Node.isRed(p) {
                if let g = p.parent { return insertBalance02(g, p, p.side) }
                p.color = .Black
            }
            return self
        }

        @inlinable func insertBalance02(_ g: Node, _ p: Node, _ ps: Side) -> Node {
            guard let u = g[!ps], Node.isRed(u) else { return insertBalance03(g, p, ps) }
            return insertBalance04(g, u, p)
        }

        @inlinable func insertBalance03(_ g: Node, _ p: Node, _ ps: Side) -> Node {
            if ps == !side { p.rotate(ps) }
            g.rotate(!ps)
            return self
        }

        @inlinable func insertBalance04(_ g: Node, _ u: Node, _ p: Node) -> Node {
            g.color = .Red
            u.color = .Black
            p.color = .Black
            return g.insertBalance()
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func delete() -> Node? {
            if let r = right, left != nil {
                return delete1(r.farLeft)
            }
            else if let c = (left ?? right) {
                return delete2(c)
            }
            else if let p = parent {
                return delete3(p)
            }
            else {
                return nil
            }
        }

        @inlinable func delete1(_ l: Node) -> Node? {
            key = l.key
            value = l.value
            return l.delete()
        }

        @inlinable func delete2(_ c: Node) -> Node {
            c.color = .Black
            if let p = parent { p[side] = c }
            return c.root
        }

        @inlinable func delete3(_ p: Node) -> Node {
            guard Node.isRed(self) else { return deleteBalance(parent: p, side: side).root }
            p[side] = nil
            return p.root
        }

        @usableFromInline func deleteBalance(parent p: Node, side s: Side) -> Node {
            guard let sib = p[!s] else { return p }
            guard Node.isRed(sib) else { return deleteBalance1(parent: p, sibling: sib, side: s) }
            p.rotate(s)
            return deleteBalance1(parent: p, sibling: fatal(ifNil: p[!s], message: String(format: ErrMsgInconsistentState, StrRedBlackDictionary)), side: s)
        }

        @inlinable func deleteBalance1(parent p: Node, sibling sib: Node, side s: Side) -> Node {
            guard Node.isBlack(sib) && Node.isBlack(sib.left) && Node.isBlack(sib.right) else { return deleteBalance4(parent: p, sibling: sib, side: s) }
            return deleteBalance2(parent: p, sibling: sib)
        }

        @inlinable func deleteBalance2(parent p: Node, sibling sib: Node) -> Node {
            sib.color = .Red
            guard Node.isBlack(p) else { return deleteBalance3(parent: p) }
            guard let g = p.parent else { return p }
            return p.deleteBalance(parent: g, side: p.side)
        }

        @inlinable func deleteBalance3(parent p: Node) -> Node {
            p.color = .Black
            return p
        }

        @inlinable func deleteBalance4(parent p: Node, sibling sib: Node, side s: Side) -> Node {
            guard let c = sib[s], Node.isRed(c) else { return deleteBalance5(parent: p, sibling: sib, side: s) }
            sib.rotate(!s)
            return deleteBalance5(parent: p, sibling: c, side: s)
        }

        @inlinable func deleteBalance5(parent p: Node, sibling sib: Node, side s: Side) -> Node {
            if let d = sib[!s], Node.isRed(d) {
                p.rotate(s)
                p.color = .Black
                d.color = .Black
            }
            return p
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
        @inlinable func set(node nc: Node?, onSide s: Side) {
            guard s != .Neither else { fatalError(ErrMsgIllegalAction) }
            let oc = self[s]
            guard oc !== nc else { return }
            oc?.parent = nil
            nc?.makeOrphan().parent = self
            if s == .Left { left = nc } else { right = nc } /*@f:0*/
            reCount() /*@f:1*/
        }

        /*======================================================================================================================================================================*/
        @inlinable func makeOrphan() -> Node {
            if let p = parent {
                if self === p.left { p.left = nil }
                else if self === p.right { p.right = nil }
                parent = nil
                p.reCount()
            }
            return self
        }

        /*======================================================================================================================================================================*/
        @usableFromInline func reCount() {
            count = (1 + lc + rc)
            if let p = parent { p.reCount() }
        }

        /*======================================================================================================================================================================*/
        @inlinable func compareKey(to k: Key) -> Side {
            ((key == k) ? .Neither : ((k < key) ? .Left : .Right))
        }

        @inlinable func withChild<R>(onSide s: Side, do a: (Node) -> R, else b: @autoclosure () -> R) -> R {
            guard let c = self[s] else { return b() }
            return a(c)
        }

        @inlinable func withParent<R>(do a: (Node) -> R, else b: @autoclosure () -> R) -> R {
            guard let p = parent else { return b() }
            return a(p)
        }

        /*======================================================================================================================================================================*/
        @inlinable class func isBlack(_ n: Node?) -> Bool { ((n == nil) || (n!.color == .Black)) }

        /*======================================================================================================================================================================*/
        @inlinable class func isRed(_ n: Node?) -> Bool { ((n != nil) && (n!.color == .Red)) }
    }

    /*==========================================================================================================================================================================*/
    /// Internal structure for the numeric index of this dictionary.
    ///
    public struct Index: Hashable, Comparable, Strideable {
        public typealias Stride = Int.Stride

        @inlinable var intValue: Int { index }

        @usableFromInline let index: Int

        @usableFromInline init(_ index: Int) { self.index = index }

        @inlinable public func distance(to other: Index) -> Stride { index.distance(to: other.index) }

        @inlinable public func advanced(by n: Stride) -> Index { Index(index.advanced(by: n)) }

        @inlinable public static func <(lhs: Index, rhs: Index) -> Bool { lhs.index < rhs.index }

        @inlinable public static func ==(lhs: Index, rhs: Index) -> Bool { lhs.index == rhs.index }

        @inlinable public static func <(lhs: Index, rhs: Int) -> Bool { lhs.index < rhs }

        @inlinable public static func >(lhs: Index, rhs: Int) -> Bool { lhs.index > rhs }
    }
}

extension RedBlackDictionary.Node.Color {
    /*==========================================================================================================================================================================*/
    @inlinable static prefix func !(_ c: RedBlackDictionary.Node.Color) -> RedBlackDictionary.Node.Color { ((c == .Black) ? .Red : .Black) }
}

extension RedBlackDictionary.Node.Side: CustomStringConvertible {
    /*==========================================================================================================================================================================*/
    @inlinable static prefix func !(_ s: RedBlackDictionary.Node.Side) -> RedBlackDictionary.Node.Side { ((s == .Left) ? .Right : ((s == .Right) ? .Left : .Neither)) }

    /*==========================================================================================================================================================================*/
    @inlinable var description: String { ((self == .Left) ? StrLeft : ((self == .Right) ? StrRight : StrNeither)) }

    @inlinable static var randomSide: RedBlackDictionary.Node.Side { ((Int.random(in: 0 ... 1) == 0) ? .Left : .Right) }
}

extension RedBlackDictionary: Equatable where Value: Equatable {
    public static func ==(lhs: RedBlackDictionary<Key, Value>, rhs: RedBlackDictionary<Key, Value>) -> Bool {
        guard lhs.startIndex == rhs.startIndex && lhs.endIndex == lhs.endIndex else { return false }
        for i in (lhs.startIndex ..< lhs.endIndex) { guard lhs[i] == rhs[i] else { return false } }
        return true
    }
}

extension RedBlackDictionary: Hashable where Value: Hashable, Key: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) { root?.hash(into: &hasher) }
}

extension RedBlackDictionary.Node: Equatable where Value: Equatable {
    @inlinable static func ==(lhs: RedBlackDictionary<Key, Value>.Node, rhs: RedBlackDictionary<Key, Value>.Node) -> Bool { ((lhs.key == rhs.key) && (lhs.value == rhs.value)) }
}

extension RedBlackDictionary.Node: Hashable where Value: Hashable, Key: Hashable {
    @usableFromInline func hash(into hasher: inout Hasher) {
        key.hash(into: &hasher)
        value.hash(into: &hasher)
        left?.hash(into: &hasher)
        right?.hash(into: &hasher)
    }
}
