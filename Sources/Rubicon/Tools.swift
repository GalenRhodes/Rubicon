/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: Tools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 4/30/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
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
#if os(Windows)
    import WinSDK
#endif

public typealias CFByteOrderEnum = __CFByteOrder

/*===============================================================================================================================================================================*/
/// A good size for a basic buffer.
///
public let BasicBufferSize: Int    = 4096

/*===============================================================================================================================================================================*/
/// The number of nanoseconds in one second.
///
public let OneSecondNanos:  UInt64 = 1_000_000_000

/*===============================================================================================================================================================================*/
/// The number of microseconds in one second.
///
public let OneSecondMicros: UInt64 = 1_000_000

/*===============================================================================================================================================================================*/
/// The number of milliseconds in one second.
///
public let OneSecondMillis: UInt64 = 1_000

/*===============================================================================================================================================================================*/
/// Get the system time in nanoseconds.
/// 
/// - Parameter delta: The number of nanoseconds to add to the system time.
/// - Returns: the system time plus the value of `delta`.
///
public func getSysTime(delta: UInt64 = 0) -> UInt64 {
    var ts: timespec = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return (((UInt64(ts.tv_sec) * OneSecondNanos) + UInt64(ts.tv_nsec)) + delta)
}

/*===============================================================================================================================================================================*/
/// Takes a date at some point in the future and converts it to a timespec struct relative to the epoch.
/// 
/// - Parameter when: the date.
/// - Returns: a timespec structure or `nil` if the date is in the past.
///
public func absoluteTimeSpecFrom(date when: Date) -> timespec? {
    guard when.timeIntervalSinceNow > 0 else {
        return nil
    }
    let absNanos: Int64 = Int64(when.timeIntervalSince1970 * Double(OneSecondNanos))
    let seconds:  Int64 = (absNanos / Int64(truncatingIfNeeded: OneSecondNanos))
    let nanos:    Int64 = (absNanos % Int64(truncatingIfNeeded: OneSecondNanos))
    return timespec(tv_sec: time_t(seconds), tv_nsec: Int(nanos))
}

#if os(Windows)
    public func timeIntervalFrom(date when: Date) -> DWORD? {
        let ti: TimeInterval = when.timeIntervalSinceNow
        guard ti > 0 else {
            return nil
        }
        return DWORD(ti * OneSecondMillis)
    }
#endif

/*===============================================================================================================================================================================*/
/// Cover function for the C standard library function `strerror(int)`. Returns a Swift <code>[String](https://developer.apple.com/documentation/swift/string/)</code>.
/// 
/// - Parameter code: the OS error code.
/// - Returns: A Swift <code>[String](https://developer.apple.com/documentation/swift/string/)</code> with the OS error message.
///
public func StrError(_ code: Int32) -> String {
    (CString.newCCharBufferOf(length: 1000) {
        ((strerror_r(code, $0, $1) == 0) ? strlen($0) : -1)
    })?.string ?? "Unknown Error: \(code)"
}

/*===============================================================================================================================================================================*/
/// Test the result of a C standard library function call to see if an error has occurred. If so then throw a fatal error with the message of the error. Usually any
/// non-<code>[zero](https://en.wikipedia.org/wiki/0)</code> value is considered an error. In some cases though a non-<code>[zero](https://en.wikipedia.org/wiki/0)</code> error is
/// just informational and in those cases you can tell this function to ignore those as well.
/// 
/// For example, in a call to `pthread_mutex_trylock(...)`, an return code of `EBUSY` simply means that the lock is already held by another thread while a code of `EINVAL` means
/// that the mutex passed to the function was not properly initialized. So you could call this function like so:
/// 
/// <pre>
///     let locked: Bool = (testOSFatalError(pthread_mutex_trylock(mutex), EBUSY) == 0)
/// </pre>
/// 
/// In this case the constant `locked` will be `true` if the thread successfully obtained ownership of the lock or `false` if another thread still owns the lock. If the return
/// code was any other value beside 0 (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) or EBUSY then a fatal error occurs.
/// 
/// - Parameters:
///   - results: The results of the call.
///   - otherOk: Other values besides 0 (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) that should be considered OK and not cause a fatal error.
/// - Returns: the value of results.
///
@discardableResult public func testOSFatalError(_ results: Int32, _ otherOk: Int32...) -> Int32 {
    if results == 0 {
        return results
    }
    for other: Int32 in otherOk {
        if results == other {
            return results
        }
    }
    fatalError(StrError(results))
}

/*===============================================================================================================================================================================*/
/// Get the length of a `nil`-terminated C string of type 'signed char' (Int8).
/// 
/// - Parameters:
///   - cStringPtr: the C string.
///   - length: the maximum possible length of the string. If less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (the default) then there is no maximum. This is
///             dangerous - only use this is you are sure there is a `nil`-terminator.
/// - Returns: the length of the string.
///
public func cStrLen(cStringPtr: UnsafePointer<Int8>, length: Int = -1) -> Int {
    if length < 0 {
        return strlen(cStringPtr)
    }
    if length > 0 {
        for i: Int in (0 ..< length) {
            if cStringPtr[i] == 0 {
                return i
            }
        }
    }
    return length
}

/*===============================================================================================================================================================================*/
/// Get the length of a `nil`-terminated C string of type 'unsigned char' (UInt8).
/// 
/// - Parameters:
///   - cStringPtr: the C string.
///   - length: the maximum possible length of the string. If less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> (the default) then there is no maximum. This is
///             dangerous - only use this is you are sure there is a `nil`-terminator.
/// - Returns: the length of the string.
///
public func cStrLen(cStringPtr: ByteROPointer, length: Int = -1) -> Int {
    cStringPtr.withMemoryRebound(to: CChar.self, capacity: fixLength(length)) {
        cStrLen(cStringPtr: $0, length: length)
    }
}

/*===============================================================================================================================================================================*/
/// The `NanoSleep(seconds:nanos:)` function causes the calling thread to sleep for the amount of time specified in the `seconds` and `nanos` parameters (the actual time slept may
/// be longer, due to system latencies and possible limitations in the timer resolution of the hardware). An unmasked signal will cause `NanoSleep(seconds:nanos:)` to terminate
/// the sleep early, regardless of the `SA_RESTART` value on the interrupting signal.
/// 
/// - Parameters:
///   - seconds: the number of seconds to sleep.
///   - nanos: the number of additional nanoseconds to sleep.
/// - Throws: `CErrors.EINTER(description:)` if `NanoSleep(seconds:nanos:)` was interrupted by an unmasked signal.
/// - Throws: `CErrors.EINVAL(description:)` if `nanos` was greater than or equal to 1,000,000,000.
///
public func NanoSleep(seconds: UInt32 = 0, nanos: UInt32 = 0) throws {
    guard nanos >= 0 && nanos < OneSecondNanos else {
        throw CErrors.INVAL(description: "Nanosecond value is invalid: \(nanos)")
    }
    var t1 = timespec(tv_sec: Int(seconds), tv_nsec: Int(nanos))
    if nanosleep(&t1, nil) < 0 {
        throw CErrors.INTR(description: "NanoSleep interrupted by OS signal.")
    }
}

/*===============================================================================================================================================================================*/
/// The `NanoSleep(seconds:nanos:)` function causes the calling thread to sleep for the amount of time specified in the `seconds` and `nanos` parameters (the actual time slept may
/// be longer, due to system latencies and possible limitations in the timer resolution of the hardware). An unmasked signal will cause `NanoSleep(seconds:nanos:)` to terminate
/// the sleep early, regardless of the `SA_RESTART` value on the interrupting signal.
/// 
/// - Parameters:
///   - seconds: the number of seconds to sleep.
///   - nanos: the number of additional nanoseconds to sleep.
/// - Throws: `CErrors.EINTER(description:)` if `NanoSleep(seconds:nanos:)` was interrupted by an unmasked signal.
/// - Throws: `CErrors.EINVAL(description:)` if `nanos` was greater than or equal to 1,000,000,000.
///
public func NanoSleep2(seconds: UInt32 = 0, nanos: UInt32 = 0) {
    guard nanos >= 0 && nanos < OneSecondNanos else {
        fatalError("Nanosecond value is invalid: \(nanos)")
    }
    var t1 = timespec(tv_sec: Int(seconds), tv_nsec: Int(nanos))
    var t2 = timespec(tv_sec: 0, tv_nsec: 0)

    repeat {
        if nanosleep(&t1, &t2) == 0 { break }
        if errno != EINTR { fatalError("Nanosleep error") }
        t1 = t2
        t2.tv_sec = 0
        t2.tv_nsec = 0
    }
    while true
}

/*===============================================================================================================================================================================*/
/// Values that indicate should be sorted against another object.
///
public enum SortOrdering: Int {
    /*===========================================================================================================================================================================*/
    /// One object comes before another object.
    ///
    case LessThan    = -1
    /*===========================================================================================================================================================================*/
    /// One object holds the same place as another object.
    ///
    case EqualTo     = 0
    /*===========================================================================================================================================================================*/
    /// One object comes after another object.
    ///
    case GreaterThan = 1
}

/*===============================================================================================================================================================================*/
/// Operator for appending new elements to an <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator <+: AssignmentPrecedence
infix operator <?: ComparisonPrecedence

/*===============================================================================================================================================================================*/
/// Append a new element to an <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// 
/// - Parameters:
///   - lhs: the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>
///   - rhs: the new element
///
public func <+ <T>(lhs: inout [T], rhs: T) {
    lhs.append(rhs)
}

/*===============================================================================================================================================================================*/
/// Append the contents of the right-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> oprand to the left-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> oprand.
/// 
/// - Parameters:
///   - lhs: the receiving <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: the source <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
public func <+ <T>(lhs: inout [T], rhs: [T]) {
    lhs.append(contentsOf: rhs)
}

/*===============================================================================================================================================================================*/
/// Checks to see if the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> (left-hand operand) contains the right-hand operand.
/// 
/// - Parameters:
///   - lhs: the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: the object to search for in the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// - Returns: `true` if the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains the object.
///
public func <? <T: Equatable>(lhs: [T], rhs: T) -> Bool {
    lhs.contains { (obj: T) in
        rhs == obj
    }
}

/*===============================================================================================================================================================================*/
/// Checks to see if the left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains all of the elements in the right-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// 
/// - Parameters:
///   - lhs: the left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: the right-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// - Returns: `true` if the left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains all of the elements in the right-hand
///            <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
public func <? <T: Equatable>(lhs: [T], rhs: [T]) -> Bool {
    for o: T in rhs {
        if !(lhs <? o) {
            return false
        }
    }
    return true
}

/*===============================================================================================================================================================================*/
/// A new operator for comparing two objects.
///
infix operator <=>: ComparisonPrecedence

/*===============================================================================================================================================================================*/
/// Compares two objects to see what their `SortOrdering` is. Both objects have to conform to the [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol.
/// 
/// Usage:
/// ```
///     func foo(str1: String, str2: String) {
///         switch str1 <=> str2 {
///             case .LessThan:    print("'\(str1)' comes before '\(str2)'")
///             case .EqualTo:     print("'\(str1)' is the same as '\(str2)'")
///             case .GreaterThan: print("'\(str1)' comes after '\(str2)'")
///         }
///     }
/// ```
/// 
/// - Parameters:
///   - l: The left hand operand
///   - r: The right hand operand
/// 
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand operand should be sorted before, at the same place as, or after the
///            right-hand operand.
///
public func <=> <T: Comparable>(l: T?, r: T?) -> SortOrdering {
    (l == nil ? (r == nil ? .EqualTo : .LessThan) : (r == nil ? .GreaterThan : (l! < r! ? .LessThan : (l! > r! ? .GreaterThan : .EqualTo))))
}

/*===============================================================================================================================================================================*/
/// Compares two arrays to see what their `SortOrdering` is. The objects of both arrays have to conform to the [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/)
/// protocol. This method first compares the number of objects in each array. If they are not the same then the function will return `SortOrdering.Before` or `SortOrdering.After`
/// as the left-hand array has fewer or more objects than the right-hand array. If the both hold the same number of objects then the function compares each object in the left-hand
/// array to the object in the same position in the right-hand array. In other words it compares `leftArray[0]` to `rightArray[0]`, `leftArray[1]` to `rightArray[1]` and so on
/// until it finds the first pair of objects that do not of the same sort ordering and returns ordering. If all the objects in the same positions in both arrays are
/// `SortOrdering.Same` then this function returns `SortOrdering.Same`.
/// 
/// Example:
/// ```
///     let array1: [Int] = [ 1, 2, 3, 4 ]
///     let array2: [Int] = [ 1, 2, 3, 4 ]
///     let array3: [Int] = [ 1, 2, 3 ]
///     let array4: [Int] = [ 1, 2, 5, 6 ]
/// 
///     let result1: SortOrdering = array1 <=> array2 // result1 is set to `SortOrdering.EqualTo`
///     let result2: SortOrdering = array1 <=> array3 // result2 is set to `SortOrdering.GreaterThan`
///     let result3: SortOrdering = array1 <=> array4 // result3 is set to `SortOrdering.LessThan`
/// ```
/// 
/// - Parameters:
///   - l: The left hand array operand
///   - r: The right hand array operand
/// 
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand array comes before, in the same place as, or after the right-hand array.
///
public func <=> <T: Comparable>(l: [T?], r: [T?]) -> SortOrdering {
    var cc: SortOrdering = (l.count <=> r.count)

    if cc == .EqualTo {
        for i: Int in (0 ..< l.count) {
            cc = (l[i] <=> r[i])
            if cc != .EqualTo {
                return cc
            }
        }
    }

    return cc
}

/*===============================================================================================================================================================================*/
/// Returns a <code>[String](https://developer.apple.com/documentation/swift/string/)</code> that represents the given integer in hexadecimal format.
/// 
/// - Parameters:
///   - n: the integer number.
///   - pad: 0 means no padding. negative number means the number is padded with spaces to that many places. Positive number means the number is padded with zeros to that many
///          places.
/// - Returns: the <code>[String](https://developer.apple.com/documentation/swift/string/)</code>
///
public func toHex<T: BinaryInteger>(_ n: T, pad: Int = 0) -> String {
    var str: String   = ""
    var spd: String   = ""
    var n:   T        = n
    let w:   Int      = n.bitWidth
    let bw:  Int      = ((pad == 0) ? w : max(w, abs(pad)))
    let pc:  String   = ((pad < 0) ? " " : "0")
    let hx:  [String] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ]

    for i: Int in stride(from: 0, to: bw, by: 4) {
        if i < w {
            str = "\(hx[Int(n & 0x0f)])\(str)"
            n = (n >> 4)
        }
        else {
            spd = "\(pc)\(spd)"
        }
    }

    return "\(spd)0x\(str)"
}

/*===============================================================================================================================================================================*/
/// Simple function to convert an integer number into a string represented as a series of ones - "1" - or zeros - "0" starting with the high bits first and the low bits to the
/// right.
/// 
/// - Parameters:
///   - n: the integer number.
///   - sep: the string will be grouped into octets separated by a space unless you provide a separator string in this field.
///   - pad: the number of places to left pad the string with zeros.
/// - Returns: the string.
///
public func toBinary<T: BinaryInteger>(_ n: T, sep: String? = nil, pad: Int = 0) -> String {
    var str: String = ""
    var n:   T      = n
    let w:   Int    = n.bitWidth
    let bw:  Int    = ((pad == 0) ? w : max(w, abs(pad)))
    let pc0: String = ((sep == nil) ? "" : sep!)
    let pc1: String = ((pad < 0) ? " " : "0")
    let pc2: String = ((sep == nil) ? pc1 : ((pad < 0) ? "  " : "0\(sep!)"))

    for i: Int in (0 ..< bw) {
        if i < w {
            str = "\(n & 1)\((i > 0 && (i % 4) == 0) ? pc0 : "")\(str)"
            n = (n >> 1)
        }
        else {
            str = "\((i > 0 && (i % 4) == 0) ? pc2 : pc1)\(str)"
        }
    }

    return str
}

/*===============================================================================================================================================================================*/
/// <code>[Optional](https://developer.apple.com/documentation/swift/optional/)</code> conditional. To test an optional for `nil` you can use an `if` statement like this:
/// ```
///     if let v = possiblyNil {
///         /* do something with v */
///     }
///     else {
///         /* do something when possiblyNil is nil */
///     }
/// ```
/// 
/// This is fine but I wanted to do the same thing with a conditional expression like this:
/// ```
///     let x = (let v = possiblyNil ? v.name : "no name") // This will not compile. 😩
/// ```
/// 
/// I know I could always do this:
/// ```
///     let x = ((possiblyNil == nil) ? "no name" : v!.name) // This will compile.
/// ```
/// But the OCD side of me really dislikes that '!' being there even though I know it will never cause a fatal error. It just rubs up against that nerve seeing it there. 🤢
/// 
/// So I created this function to simulate the functionality of the above using closures.
/// 
/// ```
///     let x = nilCheck(possiblyNil) { $0.name }, whenNilDo: { "no name" } // This will compile. 😁
/// ```
/// 
/// - Parameters:
///   - obj: the expression to test for `nil`.
///   - b1: the closure to execute if `obj` is NOT `nil`. The unwrapped value of `obj` is passed to the closure.
///   - b2: the closure to execute if `obj` IS `nil`.
/// - Returns: the value returned from whichever closure is executed.
/// - Throws: any exception thrown by whichever closure is executed.
///
public func nilCheck<S, T>(_ obj: S?, _ b1: (S) throws -> T, whenNilDo b2: () throws -> T) rethrows -> T { try ((obj == nil) ? b2() : b1(obj!)) }

/*===============================================================================================================================================================================*/
/// If the `maxLength` is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then return the largest integer possible
/// (<code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>) otherwise returns the value of `maxLength`.
/// 
/// - Parameter maxLength: the length to fix.
/// - Returns: either the value of `maxLength` or <code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>.
///
public func fixLength(_ maxLength: Int) -> Int { ((maxLength < 0) ? Int.max : maxLength) }

/*===============================================================================================================================================================================*/
/// Tests one value to see if it is one of the listed values. Instead of doing this:
/// ```
///     if number == 1 || number == 5 || number == 99 { /* do something */ }
/// ```
/// 
/// You can now do this:
/// ```
///     if value(number, isOneOf: 1, 5, 99) { /* do something */ }
/// ```
/// 
/// - Parameters:
///   - value: the value to be tested.
///   - isOneOf: the desired values.
/// - Returns: `true` of the value is one of the desired values.
///
public func value<T: Equatable>(_ value: T, isOneOf: T...) -> Bool { isOneOf.isAny { value == $0 } }

public func value<T: Equatable>(_ value: T, isOneOf: [T]) -> Bool { isOneOf.isAny { value == $0 } }

/*===============================================================================================================================================================================*/
/// Calculate the number of instances of a given datatype will occupy a given number of bytes. For example, if given a type of `Int64.self` and a byte count of 16 then this
/// function will return a value of 2.
/// 
/// - Parameters:
///   - type: the target datatype.
///   - value: the number of bytes.
/// - Returns: the number of instances of the datatype that can occupy the given number of bytes.
///
@inlinable public func fromBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<UInt8>.stride) / MemoryLayout<T>.stride) }

/*===============================================================================================================================================================================*/
/// Calculate the number of bytes that make up a given number of instances of the given datatype. For example if given a datatype of `Int64.self` and a count of 2 then this
/// function will return 16.
/// 
/// - Parameters:
///   - type: the target datatype.
///   - value: the number of instances of the datatype.
/// - Returns: the number of bytes that make up that many instances of that datatype.
///
@inlinable public func toBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<T>.stride) / MemoryLayout<UInt8>.stride) }
