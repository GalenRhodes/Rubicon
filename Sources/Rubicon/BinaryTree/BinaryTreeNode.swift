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

/*===============================================================================================================================================================================*/
/// Implements a single node for a classic Red/Black Binary Tree.
///
open class BinaryTreeNode<K: Comparable & Hashable, V> {

    /*===========================================================================================================================================================================*/
    /// Possible node colors.
    ///
    public enum NodeColor {
        /*=======================================================================================================================================================================*/
        /// The node is black.
        ///
        case Black
        /*=======================================================================================================================================================================*/
        /// The node is red.
        ///
        case Red
    }

    //@f:0
    /*===========================================================================================================================================================================*/
    /// The node's key. Must implement <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code>.
    ///
    public private(set) var key:        K
    /*===========================================================================================================================================================================*/
    /// The node's value.
    ///
    public              var value:      V
    /*===========================================================================================================================================================================*/
    /// The color of this node.
    ///
    public private(set) var color:      NodeColor
    /*===========================================================================================================================================================================*/
    /// The count for this node. Includes this node and all child nodes.
    ///
    public private(set) var count:      Int
    /*===========================================================================================================================================================================*/
    /// The right child node.
    ///
    public private(set) var rightNode:  BinaryTreeNode<K, V>? = nil
    /*===========================================================================================================================================================================*/
    /// The left child node.
    ///
    public private(set) var leftNode:   BinaryTreeNode<K, V>? = nil
    /*===========================================================================================================================================================================*/
    /// The parent node.
    ///
    public private(set) var parentNode: BinaryTreeNode<K, V>? = nil

    /*===========================================================================================================================================================================*/
    /// The grandparent node.
    ///
    public var grandParentNode: BinaryTreeNode<K, V>? { parentNode?.parentNode }
    /*===========================================================================================================================================================================*/
    /// The sibling node.
    ///
    public var siblingNode:     BinaryTreeNode<K, V>? { (isLeftChild ? parentNode?.rightNode : (isRightChild ? parentNode?.leftNode : nil)) }
    /*===========================================================================================================================================================================*/
    /// The uncle node.
    ///
    public var uncleNode:       BinaryTreeNode<K, V>? { parentNode?.siblingNode }
    /*===========================================================================================================================================================================*/
    /// Is this node the left child node?
    ///
    public var isLeftChild:     Bool                  { (self === parentNode?.leftNode) }
    /*===========================================================================================================================================================================*/
    /// Is this node the right child node?
    ///
    public var isRightChild:    Bool                  { (self === parentNode?.rightNode) }
    /*===========================================================================================================================================================================*/
    /// Is this node the root node?
    ///
    public var isRootNode:      Bool                  { (parentNode == nil) }
    /*===========================================================================================================================================================================*/
    /// The root node.
    ///
    public var rootNode:        BinaryTreeNode<K, V>  { (parentNode?.rootNode ?? self) }
    //@f:1

    /*===========================================================================================================================================================================*/
    /// Initializes this node.
    /// 
    /// - Parameters:
    ///   - key: the key. Must implement <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code>.
    ///   - value: the value.
    ///   - color: the node's color.
    ///
    init(key: K, value: V, color: NodeColor) {
        self.key = key
        self.value = value
        self.color = color
        self.count = 1
    }

    /*===========================================================================================================================================================================*/
    /// Initializes this node.
    /// 
    /// - Parameters:
    ///   - key: the key. Must implement <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code>.
    ///   - value: the value.
    ///
    public convenience init(key: K, value: V) {
        self.init(key: key, value: value, color: .Black)
    }

    /*===========================================================================================================================================================================*/
    /// Find the node with the given key. Searches this node and all of it's child nodes for the node with the given key.
    /// 
    /// - Parameter key: the key. Must implement <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code>.
    /// - Returns: the node with the given key or `nil` if no such node exists.
    ///
    public func find(key: K) -> BinaryTreeNode<K, V>? {
        switch key <=> self.key {
            case .LessThan:    return leftNode?.find(key: key)
            case .EqualTo:     return self
            case .GreaterThan: return rightNode?.find(key: key)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Inserts a new node with the given key and value. If an existing node has the same key then it's value is replaced with the given value and no new node is created.
    /// 
    /// - Parameters:
    ///   - key: the key. Must implement <code>[Comparable](https://developer.apple.com/documentation/swift/Comparable)</code>.
    ///   - value: the value.
    /// - Returns: the root node after insertion. Due to possible re-balancing this root node may not be the same as before the insert operation.
    ///
    public func insert(key: K, value: V) -> BinaryTreeNode<K, V> {
        switch key <=> self.key {
            case .EqualTo:
                self.value = value
            case .LessThan:
                if let n = leftNode { return n.insert(key: key, value: value) }
                leftNode = BinaryTreeNode(key: key, value: value, color: .Red)
                leftNode!.insertReBalance()
            case .GreaterThan:
                if let n = rightNode { return n.insert(key: key, value: value) }
                rightNode = BinaryTreeNode(key: key, value: value, color: .Red)
                rightNode!.insertReBalance()
        }
        return rootNode
    }

    /*===========================================================================================================================================================================*/
    /// Removes this node from the tree.
    /// 
    /// - Returns: the root node or `nil` if this node was the only node in the tree. The root node returned may not be the same root node as before the remove operation if this
    ///            node was the root node or if a re-balancing took place.
    ///
    public func remove() -> BinaryTreeNode<K, V>? {
        if let ln = leftNode, let _ = rightNode {
            //-------------------------
            // I have two child nodes.
            //-------------------------
            let n = ln.rightMost
            key = n.key
            value = n.value
            return n.remove()
        }
        else if let c = (leftNode ?? rightNode) {
            //--------------------------------------------------
            // I have one child node. Replace me with my child.
            //--------------------------------------------------
            c.color = .Black
            replace(with: c)
            return c.rootNode
        }
        else if let p = parentNode {
            //--------------------------------------------
            // I have no children but I do have a parent.
            //--------------------------------------------
            if color == .Black { removeReBalance() }
            replace(with: nil)
            return p.rootNode
        }
        else {
            //--------------------------------------
            // I'm the only node so I just go away.
            //--------------------------------------
            return nil
        }
    }

    /*===========================================================================================================================================================================*/
    /// Returns the node for which the given closure returns `true`. The tree is traversed in-order calling the closure with the key and value of each node. If the closure returns
    /// `true` then that node is returned. If all the nodes are visited without the closure returning `true` then `nil` is returned.
    /// 
    /// - Parameter body: the closure.
    /// - Returns: the node or `nil` if the closure never returns `true`.
    /// - Throws: any exception thrown by the closure.
    ///
    public func node(for body: (K, V) throws -> Bool) rethrows -> BinaryTreeNode<K, V>? { try iterate { node -> BinaryTreeNode<K, V>? in (try body(node.key, node.value) ? node : nil) } }

    /*===========================================================================================================================================================================*/
    /// Traverses the tree in-order calling the closure with the key and value of each node. If the closure returns `true` then the traversal stops and `true` is returned. If all
    /// the nodes are visited without the closure returning `true` then `false` is returned.
    /// 
    /// - Parameter body: the closure.
    /// - Returns: `true` if the closure returns `true`, otherwise returns `false` after all the nodes have been visited.
    /// - Throws: any exception thrown by the closure.
    ///
    public func forEach(do body: (K, V) throws -> Bool) rethrows -> Bool { (try iterate { node -> Bool? in try body(node.key, node.value) }) ?? false }

    /*===========================================================================================================================================================================*/
    /// Returns the node with the given index.
    /// 
    /// - Parameter index: the index.
    /// - Returns: the node with the given index or `nil` if no such node exists.
    ///
    public func node(for index: Int) -> BinaryTreeNode<K, V>? {
        switch index <=> self.index {
            case .LessThan:    return leftNode?.node(for: index)
            case .EqualTo:     return self
            case .GreaterThan: return rightNode?.node(for: index)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance after the insertion of a new node. - Step 1
    ///
    final func insertReBalance() {
        if let p = parentNode {
            if p.color == .Red {
                guard let g = grandParentNode else { fatalError("Missing grandparent.") }
                if let u = uncleNode, u.color == .Red {
                    p.color = .Black
                    u.color = .Black
                    g.color = .Red
                    g.insertReBalance()
                }
                else if isLeftChild == p.isRightChild {
                    p.rotate(left: p.isLeftChild)
                    g.rotate(left: p.isRightChild)
                }
                else {
                    g.rotate(left: isRightChild)
                }
            }
        }
        else {
            color = .Black
        }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node.
    ///
    final func removeReBalance() {
        if let p = parentNode {
            let l = (self === p.leftNode)
            removeReBalance01(isLeft: l, parent: p, parentColor: p.color, sibling: (l ? p.rightNode : p.leftNode))
        }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node. - Step 1
    /// 
    /// - Parameters:
    ///   - l: `true` if this node is the left child node.
    ///   - p: the parent node.
    ///   - pc: the parent's color.
    ///   - s: the sibling node.
    ///
    final func removeReBalance01(isLeft l: Bool, parent p: BinaryTreeNode<K, V>, parentColor pc: NodeColor, sibling s: BinaryTreeNode<K, V>?) {
        guard let s1 = s else { fatalError("Missing sibling node.") }

        if isRed(s1) {
            p.rotate(left: l)
            guard let s2 = (l ? p.rightNode : p.leftNode) else { fatalError("Missing sibling node.") }
            removeReBalance02a(isLeft: l, parent: p, parentColor: pc, sibling: s2)
        }
        else {
            removeReBalance02a(isLeft: l, parent: p, parentColor: pc, sibling: s1)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node. - Step 2a
    /// 
    /// - Parameters:
    ///   - l: `true` if this node is the left child node.
    ///   - p: the parent node.
    ///   - pc: the parent's color.
    ///   - s: the sibling node.
    ///
    final func removeReBalance02a(isLeft l: Bool, parent p: BinaryTreeNode<K, V>, parentColor pc: NodeColor, sibling s: BinaryTreeNode<K, V>) {
        removeReBalance02b(isLeft: l, parent: p, parentColor: pc, sibling: s, sBlack: isBlack(s), sRightBlack: isBlack(s.rightNode), sLeftBlack: isBlack(s.leftNode))
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node. - Step 2b
    /// 
    /// - Parameters:
    ///   - l: `true` if this node is the left child node.
    ///   - p: the parent node.
    ///   - pc: the parent's color.
    ///   - s: the sibling node.
    ///   - sb: `true` if the sibling is black.
    ///   - srb: `true` if the sibling's right child is black.
    ///   - slb: `true` if the sibling's left child is black.
    ///
    final func removeReBalance02b(isLeft l: Bool, parent p: BinaryTreeNode<K, V>, parentColor pc: NodeColor, sibling s: BinaryTreeNode<K, V>, sBlack sb: Bool, sRightBlack srb: Bool, sLeftBlack slb: Bool) {
        if sb && srb && slb { removeReBalance03(parent: p, parentColor: pc, sibling: s) }
        else { removeReBalance04(isLeft: l, parent: p, parentColor: pc, sibling: s, sBlack: sb, srBlack: srb, slBlack: slb) }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node. - Step 3
    /// 
    /// - Parameters:
    ///   - p: the parent node.
    ///   - pc: the parent's color.
    ///   - s: the sibling node.
    ///
    final func removeReBalance03(parent p: BinaryTreeNode<K, V>, parentColor pc: NodeColor, sibling s: BinaryTreeNode<K, V>) {
        s.color = .Red
        if pc == .Black { p.removeReBalance() }
        else { p.color = .Black }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node. - Step 4
    /// 
    /// - Parameters:
    ///   - l: `true` if this node is the left child node.
    ///   - p: the parent node.
    ///   - pc: the parent's color.
    ///   - s: the sibling node.
    ///   - sb: `true` if the sibling is black.
    ///   - srb: `true` if the sibling's right child is black.
    ///   - slb: `true` if the sibling's left child is black.
    ///
    final func removeReBalance04(isLeft l: Bool, parent p: BinaryTreeNode<K, V>, parentColor pc: NodeColor, sibling s: BinaryTreeNode<K, V>, sBlack sb: Bool, srBlack srb: Bool, slBlack slb: Bool) {
        if sb && (l ? srb : slb) && !(l ? slb : srb) {
            s.rotate(left: !l)
            removeReBalance05(isLeft: l, parent: p, parentColor: pc, sibling: s.parentNode!)
        }
        else {
            removeReBalance05(isLeft: l, parent: p, parentColor: pc, sibling: s)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Perform a re-balance before the removal of a node. - Step 5
    /// 
    /// - Parameters:
    ///   - l: `true` if this node is the left child node.
    ///   - p: the parent node.
    ///   - pc: the parent's color.
    ///   - s: the sibling node.
    ///
    final func removeReBalance05(isLeft l: Bool, parent p: BinaryTreeNode<K, V>, parentColor pc: NodeColor, sibling s: BinaryTreeNode<K, V>) {
        s.color = pc
        p.color = .Black
        if let n = (l ? s.rightNode : s.leftNode) { n.color = .Black }
        p.rotate(left: l, swapColors: false)
    }

    /*===========================================================================================================================================================================*/
    /// Iterate this node and all of its child nodes execute the given closure. If the closure returns a non-`nil` value then the iteration will stop.
    /// 
    /// - Parameter body: the closure.
    /// - Returns: The value returned by the closure or `nil` if no value was ever returned and all the nodes have been iterated over.
    /// - Throws: any error thrown by the closure.
    ///
    final func iterate<T>(_ body: (BinaryTreeNode<K, V>) throws -> T?) rethrows -> T? {
        if let n = leftNode, let v = try n.iterate(body) { return v }
        if let v = try body(self) { return v }
        if let n = rightNode { return try n.iterate(body) }
        return nil
    }

    /*===========================================================================================================================================================================*/
    /// Returns either the text "left" or "right" depending on the value of the `left` parameter.
    /// 
    /// - Parameter left: if `true` the text "left" is returned, otherwise the text "right" is returned.
    /// - Returns: "left" or "right"
    ///
    final func sideText(_ left: Bool) -> String { (left ? "left" : "right") }

    /*===========================================================================================================================================================================*/
    /// Rotates this node.
    /// 
    /// - Parameters:
    ///   - left: if `true` this node is rotated to the left, otherwise it is rotated to the right.
    ///   - swapColors: if `true`, this node will swap color with the node that becomes its new parent.
    ///
    final func rotate(left: Bool, swapColors: Bool = true) {
        guard let child = (left ? rightNode : leftNode) else { fatalError("No \(sideText(!left)) child. Cannot rotate \(sideText(left)).") }
        setChild(node: (left ? child.leftNode : child.rightNode), onLeft: !left)
        child.parentNode = nil
        if let p = parentNode { p.setChild(node: child, onLeft: (self === p.leftNode)) }
        child.setChild(node: self, onLeft: left)
        if swapColors { swap(&color, &child.color) }
        recount()
    }

    /*===========================================================================================================================================================================*/
    /// This method does not unlink either the existing child or the new child.  It assumes there is no existing child and the new child is already unlinked.
    /// 
    /// - Parameters:
    ///   - node: the new child.
    ///   - onLeft: if `true` then the new child becomes this nodes left child otherwise it becomes the right child.
    /// - Returns: the new child.
    ///
    @discardableResult final func setChild(node: BinaryTreeNode<K, V>?, onLeft: Bool) -> BinaryTreeNode<K, V>? {
        if onLeft { leftNode = node }
        else { rightNode = node }
        if let n = node { n.parentNode = self }
        return node
    }

    /*===========================================================================================================================================================================*/
    /// Replaces this node with the given node. This node will become an orphan node.
    /// 
    /// - Parameter node: the node that will replace this node. May be `nil`.
    ///
    final func replace(with node: BinaryTreeNode<K, V>?) {
        if let n = node {
            n.replace(with: nil)
        }
        if let p = parentNode {
            p.setChild(node: node, onLeft: (self === p.leftNode))
            parentNode = nil
            p.recount()
        }
    }

    /*===========================================================================================================================================================================*/
    /// Forces this node, it's parent, grandparent, etc. up to the root node to update it's count.
    ///
    final func recount() {
        count = (1 + leftCc + rightCc)
        if let p = parentNode { p.recount() }
    }

    /*===========================================================================================================================================================================*/
    /// Used in calculating the nodes index.
    /// 
    /// - Parameter p: this nodes parent node.
    /// - Returns: this nodes index.
    ///
    func index(_ p: BinaryTreeNode<K, V>) -> Int { ((self === p.leftNode) ? (p.index - rightCc - 1) : (p.index + leftCc + 1)) }

    //@f:0
    /*===========================================================================================================================================================================*/
    /// Returns this node's right-most child node.
    ///
    final var rightMost: BinaryTreeNode<K, V> { (rightNode?.rightMost ?? self) }
    /*===========================================================================================================================================================================*/
    /// Returns this node's left-most child node.
    ///
    final var leftMost:  BinaryTreeNode<K, V> { (leftNode?.leftMost ?? self) }
    /*===========================================================================================================================================================================*/
    /// Returns the cound of all the child nodes on this node's left side.
    ///
    final var leftCc:    Int                  { (leftNode?.count ?? 0) }
    /*===========================================================================================================================================================================*/
    /// Returns the cound of all the child nodes on this node's right side.
    ///
    final var rightCc:   Int                  { (rightNode?.count ?? 0) }
    /*===========================================================================================================================================================================*/
    /// Returns this node's index.
    ///
    final var index:     Int                  { ((parentNode == nil) ? leftCc : index(parentNode!)) }
    //@f:1
}

/*===============================================================================================================================================================================*/
/// Check a node's color to see if it's black.
/// 
/// - Parameter node: the node.
/// - Returns: `true` if the given node is black.
///
func isBlack<K: Comparable, V>(_ node: BinaryTreeNode<K, V>?) -> Bool { ((node?.color ?? .Black) == .Black) }

/*===============================================================================================================================================================================*/
/// Check a node's color to see if it's red.
/// 
/// - Parameter node: the node.
/// - Returns: `true` if the given node is red.
///
func isRed<K: Comparable, V>(_ node: BinaryTreeNode<K, V>?) -> Bool { ((node?.color ?? .Black) == .Red) }

extension BinaryTreeNode: Equatable where V: Equatable {
    public static func == (lhs: BinaryTreeNode<K, V>, rhs: BinaryTreeNode<K, V>) -> Bool { lhs.key == rhs.key && lhs.value == rhs.value }
}

extension BinaryTreeNode: Hashable where V: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(value)
    }
}
