/*
 *     PROJECT: Rubicon
 *    FILENAME: ShadowInt.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/4/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//*============================================================================================================================================================================*/

import Foundation
import CoreFoundation

infix operator <-: AssignmentPrecedence

/*==============================================================================================================*/
/// This structure solves a very unique and interesting dilemma. Suppose you have a
/// <code>[Dictionary&lt;Key,Value&gt;](https://developer.apple.com/documentation/swift/dictionary)</code> in your
/// code like so:
/// 
/// ```
///     var dict: [Int: Any] = [:]
/// 
///     let someval = dict[3]
/// ```
/// 
/// In this case the `Dictionary.Index` is the same type as the generic type `Key`. So there is no way for the
/// compiler to differentiate between the subscript that takes a value of type `Key` and the subscript that takes
/// a value of type `Dictionary.Index`.
/// 
/// So, for your key you can simply use this `Int` _holder_. It will even allow comparisons (`==`, `!=`, `<`, `>`,
/// etc.) and basic arithmetic (`+`, `-`, `*`, `/`, etc.) between itself and values of type `Int`. The type of the
/// results for arithmetic is always a `ShadowInt`. For example:
/// 
/// ```
///     let anInt:   Int       = 7 let aShadow: ShadowInt = `ShadowInt(5)`
/// 
///     let anotherShadow: ShadowInt = (aShadow + anInt) // The same as `ShadowInt(aShadow.value + anInt)` let
///     yetAnotherShadow: ShadowInt = (anInt + aShadow) // The same as `ShadowInt(anInt + aShadow.value)`
/// ```
/// 
/// However, operator+assignment functions (`+=`, `-=`, `*=`, `/=`, etc.) will behave as one might expect them to.
/// So, for example:
/// 
/// ```
///     var anInt:   Int       = 7 var aShadow: ShadowInt = `ShadowInt(5)`
/// 
///     anInt += aShadow // the type of anInt is still Int
/// 
///     aShadow += anInt // the type of aShadow is still ShadowInt
/// ```
/// 
/// And, as an added bonus, you can even directly assign between an `Int` and a `ShadowInt` using the `<-`
/// operator.
/// 
/// ```
///     var anInt  : Int       = 0 let aShadow: ShadowInt = `ShadowInt(42)`
/// 
///     anInt <- aShadow // anInt is now 42
/// ```
///
@frozen public struct ShadowInt: Comparable, Hashable, Equatable, BinaryInteger, Numeric, AdditiveArithmetic {
    //@f:0
    public typealias Magnitude          = Int.Magnitude
    public typealias Words              = Int.Words
    public typealias IntegerLiteralType = Int.IntegerLiteralType

    public static let zero:     ShadowInt = ShadowInt(0)
    public static let isSigned: Bool      = Int.isSigned

    @inlinable public var magnitude:            Magnitude { value.magnitude            }
    @inlinable public var words:                Words     { value.words                }
    @inlinable public var bitWidth:             Int       { value.bitWidth             }
    @inlinable public var trailingZeroBitCount: Int       { value.trailingZeroBitCount }
    @inlinable public var hashValue:            Int       { value.hashValue            }

    public let value: Int

    @inlinable public init(_ nodeIndex: Int)                                       { self.value = nodeIndex                                               }

    @inlinable public init<T>(_ source: T) where T: BinaryFloatingPoint            { self.init(Int(source))                                               }

    @inlinable public init<T>(_ source: T) where T: BinaryInteger                  { self.init(Int(source))                                               }

    @inlinable public init<T>(truncatingIfNeeded source: T) where T: BinaryInteger { self.init(Int(truncatingIfNeeded: source))                           }

    @inlinable public init<T>(clamping source: T) where T: BinaryInteger           { self.init(Int(clamping: source))                                     }

    @inlinable public init(integerLiteral value: IntegerLiteralType)               { self.init(Int(integerLiteral: value))                                }

    @inlinable public init?<T>(exactly source: T) where T: BinaryFloatingPoint     { guard let i = Int(exactly: source) else { return nil }; self.init(i) }

    @inlinable public init?<T>(exactly source: T) where T: BinaryInteger           { guard let i = Int(exactly: source) else { return nil }; self.init(i) }

    @inlinable public static        func <- (lhs: inout ShadowInt, rhs: Int)                                             { lhs = ShadowInt(rhs)             }

    @inlinable public static        func <- (lhs: inout Int, rhs: ShadowInt)                                             { lhs = rhs.value                  }

    @inlinable public static        func < (lhs: ShadowInt, rhs: ShadowInt)        -> Bool                               { (lhs.value < rhs.value)          }

    @inlinable public static        func < (lhs: ShadowInt, rhs: Int)              -> Bool                               { (lhs.value < rhs)                }

    @inlinable public static        func < (lhs: Int, rhs: ShadowInt)              -> Bool                               { (lhs < rhs.value)                }

    @inlinable public static        func == (lhs: ShadowInt, rhs: ShadowInt)       -> Bool                               { (lhs.value == rhs.value)         }

    @inlinable public static        func == (lhs: ShadowInt, rhs: Int)             -> Bool                               { (lhs.value == rhs)               }

    @inlinable public static        func == (lhs: Int, rhs: ShadowInt)             -> Bool                               { (lhs == rhs.value)               }

    @inlinable public static        func <= (lhs: ShadowInt, rhs: Int)             -> Bool                               { (lhs.value <= rhs)               }

    @inlinable public static        func <= (lhs: Int, rhs: ShadowInt)             -> Bool                               { (lhs <= rhs.value)               }

    @inlinable public static        func > (lhs: ShadowInt, rhs: Int)              -> Bool                               { (lhs.value > rhs)                }

    @inlinable public static        func > (lhs: Int, rhs: ShadowInt)              -> Bool                               { (lhs > rhs.value)                }

    @inlinable public static        func >= (lhs: ShadowInt, rhs: Int)             -> Bool                               { (lhs.value >= rhs)               }

    @inlinable public static        func >= (lhs: Int, rhs: ShadowInt)             -> Bool                               { (lhs >= rhs.value)               }

    @inlinable public static        func != (lhs: ShadowInt, rhs: Int)             -> Bool                               { (lhs.value != rhs)               }

    @inlinable public static        func != (lhs: Int, rhs: ShadowInt)             -> Bool                               { (lhs != rhs.value)               }

    @inlinable public static prefix func ~ (x: ShadowInt)                          -> ShadowInt                          { ShadowInt(~x.value)              }

    @inlinable public static        func + (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value + rhs.value) }

    @inlinable public static        func + (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value + rhs)       }

    @inlinable public static        func + (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs + rhs.value)       }

    @inlinable public static        func - (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value - rhs.value) }

    @inlinable public static        func - (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value - rhs)       }

    @inlinable public static        func - (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs - rhs.value)       }

    @inlinable public static        func * (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value * rhs.value) }

    @inlinable public static        func * (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value * rhs)       }

    @inlinable public static        func * (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs * rhs.value)       }

    @inlinable public static        func / (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value / rhs.value) }

    @inlinable public static        func / (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value / rhs)       }

    @inlinable public static        func / (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs / rhs.value)       }

    @inlinable public static        func % (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value % rhs.value) }

    @inlinable public static        func % (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value % rhs)       }

    @inlinable public static        func % (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs % rhs.value)       }

    @inlinable public static        func & (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value & rhs.value) }

    @inlinable public static        func & (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value & rhs)       }

    @inlinable public static        func & (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs & rhs.value)       }

    @inlinable public static        func | (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value | rhs.value) }

    @inlinable public static        func | (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value | rhs)       }

    @inlinable public static        func | (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs | rhs.value)       }

    @inlinable public static        func ^ (lhs: ShadowInt, rhs: ShadowInt)        -> ShadowInt                          { ShadowInt(lhs.value ^ rhs.value) }

    @inlinable public static        func ^ (lhs: ShadowInt, rhs: Int)              -> ShadowInt                          { ShadowInt(lhs.value ^ rhs)       }

    @inlinable public static        func ^ (lhs: Int, rhs: ShadowInt)              -> ShadowInt                          { ShadowInt(lhs ^ rhs.value)       }

    @inlinable public static        func >> <RHS>(lhs: ShadowInt, rhs: RHS)        -> ShadowInt where RHS: BinaryInteger { ShadowInt(lhs.value >> rhs)      }

    @inlinable public static        func << <RHS>(lhs: ShadowInt, rhs: RHS)        -> ShadowInt where RHS: BinaryInteger { ShadowInt(lhs.value << rhs)      }

    @inlinable public               func isMultiple(of other: ShadowInt)           -> Bool                               { value.isMultiple(of: other.value) }

    @inlinable public               func isMultiple(of other: Int)                 -> Bool                               { value.isMultiple(of: other)       }

    @inlinable public               func signum()                                  -> ShadowInt                          { ShadowInt(value.signum())         }

    @inlinable public static        func += (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs + rhs)                 }

    @inlinable public static        func -= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs - rhs)                 }

    @inlinable public static        func *= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs * rhs)                 }

    @inlinable public static        func /= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs / rhs)                 }

    @inlinable public static        func %= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs % rhs)                 }

    @inlinable public static        func &= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs & rhs)                 }

    @inlinable public static        func |= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs | rhs)                 }

    @inlinable public static        func ^= (lhs: inout ShadowInt, rhs: ShadowInt)                                       { lhs = (lhs ^ rhs)                 }

    @inlinable public static        func += (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs + rhs).value           }

    @inlinable public static        func -= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs - rhs).value           }

    @inlinable public static        func *= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs * rhs).value           }

    @inlinable public static        func /= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs / rhs).value           }

    @inlinable public static        func %= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs % rhs).value           }

    @inlinable public static        func &= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs & rhs).value           }

    @inlinable public static        func |= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs | rhs).value           }

    @inlinable public static        func ^= (lhs: inout Int, rhs: ShadowInt)                                             { lhs = (lhs ^ rhs).value           }

    @inlinable public static        func += (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs + rhs)                 }

    @inlinable public static        func -= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs - rhs)                 }

    @inlinable public static        func *= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs * rhs)                 }

    @inlinable public static        func /= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs / rhs)                 }

    @inlinable public static        func %= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs % rhs)                 }

    @inlinable public static        func &= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs & rhs)                 }

    @inlinable public static        func |= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs | rhs)                 }

    @inlinable public static        func ^= (lhs: inout ShadowInt, rhs: Int)                                             { lhs = (lhs ^ rhs)                 }

    @inlinable public static        func >>= <RHS>(lhs: inout ShadowInt, rhs: RHS) where RHS: BinaryInteger              { lhs = (lhs >> rhs)                }

    @inlinable public static        func <<= <RHS>(lhs: inout ShadowInt, rhs: RHS) where RHS: BinaryInteger              { lhs = (lhs << rhs)                }

    @inlinable public func quotientAndRemainder(dividingBy rhs: ShadowInt) -> (quotient: ShadowInt, remainder: ShadowInt) {
        let qr = value.quotientAndRemainder(dividingBy: rhs.value)
        return (ShadowInt(qr.quotient), ShadowInt(qr.remainder))
    }

    @inlinable public func quotientAndRemainder(dividingBy rhs: Int) -> (quotient: ShadowInt, remainder: ShadowInt) {
        let qr = value.quotientAndRemainder(dividingBy: rhs)
        return (ShadowInt(qr.quotient), ShadowInt(qr.remainder))
    }

    @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(value) }
}
