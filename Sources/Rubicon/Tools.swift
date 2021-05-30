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
public typealias PGTimeT = time_t

/*==============================================================================================================*/
/// A good size for a basic buffer.
///
public let BasicBufferSize: Int     = 4096

/*==============================================================================================================*/
/// The number of nanoseconds in one second.
///
public let OneSecondNanos:  PGTimeT = 1_000_000_000

/*==============================================================================================================*/
/// The number of microseconds in one second.
///
public let OneSecondMicros: PGTimeT = 1_000_000

/*==============================================================================================================*/
/// The number of milliseconds in one second.
///
public let OneSecondMillis: PGTimeT = 1_000

/*==============================================================================================================*/
/// Get the system time in nanoseconds.
/// 
/// - Parameter delta: The number of nanoseconds to add to the system time.
/// - Returns: The system time plus the value of `delta`.
///
@inlinable public func getSysTime(delta: PGTimeT = 0) -> PGTimeT {
    var ts: timespec = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return ((ts.tv_sec * OneSecondNanos) + ts.tv_nsec + delta)
}

/*==============================================================================================================*/
/// Takes a date at some point in the future and converts it to a timespec struct relative to the epoch.
/// 
/// - Parameter when: the date.
/// - Returns: A timespec structure or `nil` if the date is in the past.
///
@inlinable public func absoluteTimeSpecFrom(date when: Date) -> timespec? {
    guard when.timeIntervalSinceNow > 0 else { return nil }
    let dNanos:   Double = Double(OneSecondNanos)
    let dTotal:   Double = (when.timeIntervalSince1970 * dNanos)
    let dSeconds: Double = (dTotal / dNanos)
    return timespec(tv_sec: Int(dSeconds), tv_nsec: Int(dTotal - (dSeconds * dNanos)))
}

#if os(Windows)
    @inlinable public func timeIntervalFrom(date when: Date) -> DWORD? {
        let ti: TimeInterval = when.timeIntervalSinceNow
        guard ti > 0 else { return nil }
        return DWORD(ti * OneSecondMillis)
    }
#endif

/*==============================================================================================================*/
/// Cover function for the C standard library function `strerror(int)`. Returns a Swift
/// <code>[String](https://developer.apple.com/documentation/swift/string/)</code>.
/// 
/// - Parameter code: the OS error code.
/// - Returns: A Swift <code>[String](https://developer.apple.com/documentation/swift/string/)</code> with the OS
///            error message.
///
@inlinable public func StrError(_ code: Int32) -> String {
    (CString.newCCharBufferOf(length: 1000) {
        ((strerror_r(code, $0, $1) == 0) ? strlen($0) : -1)
    })?.string ?? "Unknown Error: \(code)"
}

/*==============================================================================================================*/
/// Test the result of a C standard library function call to see if an error has occurred. If so then throw a
/// fatal error with the message of the error. Usually any
/// non-<code>[zero](https://en.wikipedia.org/wiki/0)</code> value is considered an error. In some cases though a
/// non-<code>[zero](https://en.wikipedia.org/wiki/0)</code> error is just informational and in those cases you
/// can tell this function to ignore those as well.
/// 
/// For example, in a call to `pthread_mutex_trylock(...)`, an return code of `EBUSY` simply means that the lock
/// is already held by another thread while a code of `EINVAL` means that the mutex passed to the function was not
/// properly initialized. So you could call this function like so:
/// 
/// <pre>
///     let locked: Bool = (testOSFatalError(pthread_mutex_trylock(mutex), EBUSY) == 0)
/// </pre>
/// 
/// In this case the constant `locked` will be `true` if the thread successfully obtained ownership of the lock or
/// `false` if another thread still owns the lock. If the return code was any other value beside 0
/// (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) or EBUSY then a fatal error occurs.
/// 
/// - Parameters:
///   - results: The results of the call.
///   - otherOk: Other values besides 0 (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) that should be
///              considered OK and not cause a fatal error.
/// - Returns: The value of results.
///
@inlinable @discardableResult public func testOSFatalError(_ results: Int32, _ otherOk: Int32...) -> Int32 {
    if results == 0 { return results }
    for other: Int32 in otherOk { if results == other { return results } }
    fatalError(StrError(results))
}

/*==============================================================================================================*/
/// Get the length of a `nil`-terminated C string of type 'signed char' (Int8).
/// 
/// - Parameters:
///   - cStringPtr: The C string.
///   - length: The maximum possible length of the string. If less than
///             <code>[zero](https://en.wikipedia.org/wiki/0)</code> (the default) then there is no maximum. This
///             is dangerous - only use this is you are sure there is a `nil`-terminator.
/// - Returns: The length of the string.
///
@inlinable public func cStrLen(cStringPtr: UnsafePointer<Int8>, length: Int = -1) -> Int {
    if length < 0 { return strlen(cStringPtr) }
    if length > 0 { for i: Int in (0 ..< length) { if cStringPtr[i] == 0 { return i } } }
    return length
}

/*==============================================================================================================*/
/// Get the length of a `nil`-terminated C string of type 'unsigned char' (UInt8).
/// 
/// - Parameters:
///   - cStringPtr: The C string.
///   - length: The maximum possible length of the string. If less than
///             <code>[zero](https://en.wikipedia.org/wiki/0)</code> (the default) then there is no maximum. This
///             is dangerous - only use this is you are sure there is a `nil`-terminator.
/// - Returns: The length of the string.
///
@inlinable public func cStrLen(cStringPtr: ByteROPointer, length: Int = -1) -> Int {
    cStringPtr.withMemoryRebound(to: CChar.self, capacity: fixLength(length)) { cStrLen(cStringPtr: $0, length: length) }
}

/*==============================================================================================================*/
/// The `NanoSleep(seconds:nanos:)` function causes the calling thread to sleep for the amount of time specified
/// in the `seconds` and `nanos` parameters (the actual time slept may be longer, due to system latencies and
/// possible limitations in the timer resolution of the hardware). An unmasked signal will cause
/// `NanoSleep(seconds:nanos:)` to terminate the sleep early, regardless of the `SA_RESTART` value on the
/// interrupting signal.
/// 
/// - Parameters:
///   - seconds: The number of seconds to sleep.
///   - nanos: The number of additional nanoseconds to sleep.
/// - Throws: `CErrors.EINTER(description:)` if `NanoSleep(seconds:nanos:)` was interrupted by an unmasked signal.
/// - Throws: `CErrors.EINVAL(description:)` if `nanos` was greater than or equal to 1,000,000,000.
///
public func NanoSleep(seconds: PGTimeT = 0, nanos: Int = 0) -> Int {
    guard nanos >= 0 && nanos < OneSecondNanos else { fatalError("Nanosecond value is invalid: \(nanos)") }
    var t1 = timespec(tv_sec: seconds, tv_nsec: nanos)
    var t2 = timespec(tv_sec: 0, tv_nsec: 0)
    guard nanosleep(&t1, &t2) != 0 else { return 0 }
    return ((t2.tv_sec * OneSecondNanos) + t2.tv_nsec)
}

/*==============================================================================================================*/
/// The `NanoSleep(seconds:nanos:)` function causes the calling thread to sleep for the amount of time specified
/// in the `seconds` and `nanos` parameters (the actual time slept may be longer, due to system latencies and
/// possible limitations in the timer resolution of the hardware). An unmasked signal will cause
/// `NanoSleep(seconds:nanos:)` to terminate the sleep early, regardless of the `SA_RESTART` value on the
/// interrupting signal.
/// 
/// - Parameters:
///   - seconds: The number of seconds to sleep.
///   - nanos: The number of additional nanoseconds to sleep.
///
public func NanoSleep2(seconds: PGTimeT = 0, nanos: Int = 0) {
    guard nanos >= 0 && nanos < OneSecondNanos else { fatalError("Nanosecond value is invalid: \(nanos)") }
    var t1 = timespec(tv_sec: seconds, tv_nsec: nanos)
    var t2 = timespec(tv_sec: 0, tv_nsec: 0)

    repeat {
        guard nanosleep(&t1, &t2) != 0 else { break }
        guard errno == EINTR else { fatalError("Nanosleep error") }
        t1 = t2
        t2.tv_sec = 0
        t2.tv_nsec = 0
    } while true
}

/*==============================================================================================================*/
/// Values that indicate should be sorted against another object.
///
public enum SortOrdering: Int {
    /*==========================================================================================================*/
    /// One object comes before another object.
    ///
    case LessThan    = -1
    /*==========================================================================================================*/
    /// One object holds the same place as another object.
    ///
    case EqualTo     = 0
    /*==========================================================================================================*/
    /// One object comes after another object.
    ///
    case GreaterThan = 1
}

/*==============================================================================================================*/
/// Operator for appending new elements to an
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator <+: AssignmentPrecedence
/*==============================================================================================================*/
/// Operator for removing elements from an
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator >-: AssignmentPrecedence
/*==============================================================================================================*/
/// Operator for finding elements in an
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> container.
///
infix operator <?: ComparisonPrecedence

/*==============================================================================================================*/
/// Append a new element to an <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// 
/// - Parameters:
///   - lhs: The <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>
///   - rhs: The new element
///
@inlinable public func <+ <T>(lhs: inout [T], rhs: T) { lhs.append(rhs) }

/*==============================================================================================================*/
/// Append the contents of the right-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> oprand to the left-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> oprand.
/// 
/// - Parameters:
///   - lhs: The receiving <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: The source <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
@inlinable public func <+ <T>(lhs: inout [T], rhs: [T]) { lhs.append(contentsOf: rhs) }

/*==============================================================================================================*/
/// Checks to see if the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> (left-hand
/// operand) contains the right-hand operand.
/// 
/// - Parameters:
///   - lhs: The <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: The object to search for in the
///          <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// - Returns: `true` if the <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains
///            the object.
///
@inlinable public func <? <T: Equatable>(lhs: [T], rhs: T) -> Bool { lhs.contains { (obj: T) in rhs == obj } }

/*==============================================================================================================*/
/// Checks to see if the left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>
/// contains all of the elements in the right-hand
/// <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// 
/// - Parameters:
///   - lhs: The left-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///   - rhs: The right-hand <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
/// - Returns: `true` if the left-hand
///            <code>[Array](https://developer.apple.com/documentation/swift/array/)</code> contains all of the
///            elements in the right-hand
///            <code>[Array](https://developer.apple.com/documentation/swift/array/)</code>.
///
@inlinable public func <? <T: Equatable>(lhs: [T], rhs: [T]) -> Bool {
    for o: T in rhs { if !(lhs <? o) { return false } }
    return true
}

/*==============================================================================================================*/
/// A new operator for comparing two objects.
///
infix operator <=>: ComparisonPrecedence

/*==============================================================================================================*/
/// Compares two objects to see what their `SortOrdering` is. Both objects have to conform to the
/// [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol.
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
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand
///            operand should be sorted before, at the same place as, or after the right-hand operand.
///
@inlinable public func <=> <T: Comparable>(l: T?, r: T?) -> SortOrdering {
    (l == nil ? (r == nil ? .EqualTo : .LessThan) : (r == nil ? .GreaterThan : (l! < r! ? .LessThan : (l! > r! ? .GreaterThan : .EqualTo))))
}

/*==============================================================================================================*/
/// Compares two arrays to see what their `SortOrdering` is. The objects of both arrays have to conform to the
/// [`Comparable`](https://swiftdoc.org/v5.1/protocol/comparable/) protocol. This method first compares the number
/// of objects in each array. If they are not the same then the function will return `SortOrdering.Before` or
/// `SortOrdering.After` as the left-hand array has fewer or more objects than the right-hand array. If the both
/// hold the same number of objects then the function compares each object in the left-hand array to the object in
/// the same position in the right-hand array. In other words it compares `leftArray[0]` to `rightArray[0]`,
/// `leftArray[1]` to `rightArray[1]` and so on until it finds the first pair of objects that do not of the same
/// sort ordering and returns ordering. If all the objects in the same positions in both arrays are
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
/// - Returns: `SortOrdering.LessThan`, `SortOrdering.EqualTo`, `SortOrdering.GreaterThan` as the left-hand array
///            comes before, in the same place as, or after the right-hand array.
///
@inlinable public func <=> <T: Comparable>(l: [T?], r: [T?]) -> SortOrdering {
    var cc: SortOrdering = (l.count <=> r.count)

    if cc == .EqualTo {
        for i: Int in (0 ..< l.count) {
            cc = (l[i] <=> r[i])
            guard cc == .EqualTo else { break }
        }
    }

    return cc
}

/*==============================================================================================================*/
/// Returns a <code>[String](https://developer.apple.com/documentation/swift/string/)</code> that represents the
/// given integer in hexadecimal format.
/// 
/// - Parameters:
///   - n: The integer number.
///   - pad: 0 means no padding. negative number means the number is padded with spaces to that many places.
///          Positive number means the number is padded with zeros to that many places.
/// - Returns: The <code>[String](https://developer.apple.com/documentation/swift/string/)</code>
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

/*==============================================================================================================*/
/// Simple function to convert an integer number into a string represented as a series of ones - "1" - or zeros -
/// "0" starting with the high bits first and the low bits to the right.
/// 
/// - Parameters:
///   - n: The integer number.
///   - sep: The string will be grouped into octets separated by a space unless you provide a separator string in
///          this field.
///   - pad: The number of places to left pad the string with zeros.
/// - Returns: The string.
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

/*==============================================================================================================*/
/// <code>[Optional](https://developer.apple.com/documentation/swift/optional/)</code> conditional. To test an
/// optional for `nil` you can use an `if` statement like this:
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
/// But the OCD side of me really dislikes that '!' being there even though I know it will never cause a fatal
/// error. It just rubs up against that nerve seeing it there. 🤢
/// 
/// So I created this function to simulate the functionality of the above using closures.
/// 
/// ```
///     let x = nilCheck(possiblyNil) { $0.name }, whenNilDo: { "no name" } // This will compile. 😁
/// ```
/// 
/// - Parameters:
///   - obj: The expression to test for `nil`.
///   - b1: The closure to execute if `obj` is NOT `nil`. The unwrapped value of `obj` is passed to the closure.
///   - b2: The closure to execute if `obj` IS `nil`.
/// - Returns: The value returned from whichever closure is executed.
/// - Throws: Any exception thrown by whichever closure is executed.
///
@inlinable public func ifNil<S, T>(_ obj: S?, then b2: () throws -> T, elseThen b1: (S) throws -> T) rethrows -> T {
    guard let o = obj else { return try b2() }
    return try b1(o)
}

/*==============================================================================================================*/
/// If the `maxLength` is less than <code>[zero](https://en.wikipedia.org/wiki/0)</code> then return the largest
/// integer possible (<code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>)
/// otherwise returns the value of `maxLength`.
/// 
/// - Parameter maxLength: the length to fix.
/// - Returns: Either the value of `maxLength` or
///            <code>[Int.max](https://developer.apple.com/documentation/swift/int/1540171-max)</code>.
///
@inlinable public func fixLength(_ maxLength: Int) -> Int { ((maxLength < 0) ? Int.max : maxLength) }

/*==============================================================================================================*/
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
///   - value: The value to be tested.
///   - isOneOf: The desired values.
/// - Returns: `true` of the value is one of the desired values.
///
@inlinable public func value<T: Equatable>(_ value: T, isOneOf: T...) -> Bool { isOneOf.isAny { value == $0 } }

@inlinable public func value<T: Equatable>(_ value: T, isOneOf: [T]) -> Bool { isOneOf.isAny { value == $0 } }

/*==============================================================================================================*/
/// Calculate the number of instances of a given datatype will occupy a given number of bytes. For example, if
/// given a type of `Int64.self` and a byte count of 16 then this function will return a value of 2.
/// 
/// - Parameters:
///   - type: The target datatype.
///   - value: The number of bytes.
/// - Returns: The number of instances of the datatype that can occupy the given number of bytes.
///
@inlinable public func fromBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<UInt8>.stride) / MemoryLayout<T>.stride) }

/*==============================================================================================================*/
/// Calculate the number of bytes that make up a given number of instances of the given datatype. For example if
/// given a datatype of `Int64.self` and a count of 2 then this function will return 16.
/// 
/// - Parameters:
///   - type: The target datatype.
///   - value: The number of instances of the datatype.
/// - Returns: The number of bytes that make up that many instances of that datatype.
///
@inlinable public func toBytes<T>(type: T.Type, _ value: Int) -> Int { ((value * MemoryLayout<T>.stride) / MemoryLayout<UInt8>.stride) }

/*==============================================================================================================*/
/// Output debugging text. This method only produces output when the code is compiled with a `-DDEBUG` flag.
/// 
/// - Parameters:
///   - obj: The objects to print. They are converted to string with `String(describing:)`.
///   - separator: The string to put between objects. Defaults to a single space character.
///   - terminator: The string to put at the end of all the objects. Defaults to a single line-feed (`\n`)
///                 character.
///
@inlinable public func debug(_ obj: Any..., separator: String = " ", terminator: String = "\n") {
    let _obj: [Any] = obj.map { $0 }
    debug(_obj, separator: separator, terminator: terminator)
}

/*==============================================================================================================*/
/// Output debugging text. This method only produces output when the code is compiled with a `-DDEBUG` flag.
/// 
/// - Parameters:
///   - obj: The objects to print. They are converted to string with `String(describing:)`.
///   - separator: The string to put between objects. Defaults to a single space character.
///   - terminator: The string to put at the end of all the objects. Defaults to a single, platform dependent
///                 new-line character.
///
@inlinable public func debug(_ obj: [Any], separator: String = " ", terminator: String? = nil) {
    #if DEBUG
        #if os(Windows)
            let term: String = (terminator ?? "\r\n")
        #else
            let term: String = (terminator ?? "\n")
        #endif
        if !obj.isEmpty {
            print(obj[obj.startIndex], terminator: "")
            for i in (obj.index(after: obj.startIndex) ..< obj.endIndex) {
                print(separator, terminator: "")
                print(obj[i], terminator: "")
            }
        }
        print("", terminator: term)
    #endif
}

private var nestLevel: Int       = 0
private let nestLock:  MutexLock = MutexLock()

/*==============================================================================================================*/
/// Enum used with `nDebug(_:_:separator:)`
///
public enum NestType { case None, In, Out }

private func nDebugIndent(_ count: Int, _ string: inout String, _ msg: String) {
    for _ in (0 ..< count) { string.append("    ") }
    string.append(msg)
}

/*==============================================================================================================*/
/// Output debugging text. This method only produces output when the code is compiled with a `-DDEBUG` flag. This
/// method outputs text in a nested fashion. Calling this method with NestType.In increases the nesting level.
/// Calling this method with NestType.Out decreases the nesting level. Calling this method with NestType.None
/// keeps the nesting level the same.
/// 
/// - Parameters:
///   - nestType: The nesting type.
///   - obj: The objects to print. They are converted to a string with `String(describing:)`.
///   - separator: The string to put between objects. Defaults to a single space character.
///
public func nDebug(_ nestType: NestType = .None, _ obj: Any..., separator: String = " ") {
    #if DEBUG
        nestLock.withLock {
            var str: String = ""
            if obj.isEmpty {
                switch nestType {
                    case .None: break
                    case .In:   nestLevel++
                    case .Out:  if nestLevel > 0 { nestLevel-- }
                }
            }
            else {
                switch nestType {
                    case .None: nDebugIndent(nestLevel, &str, "  | ")
                    case .In:   nDebugIndent(nestLevel++, &str, ">>> ")
                    case .Out:  nDebugIndent(nestLevel > 0 ? --nestLevel : nestLevel, &str, "<<< ")
                }

                str.append("\(obj[obj.startIndex])")
                for i in (obj.index(after: obj.startIndex) ..< obj.endIndex) { str.append("\(separator)\(obj[i])") }
            }
            print(str)
        }
    #endif
}

/*==============================================================================================================*/
/// Get a hash value from just about anything.
/// 
/// - Parameter v: The item you want the hash of.
/// - Returns: The hash.
///
@inlinable public func HashOfAnything(_ v: Any) -> Int {
    if let x = (v as? AnyHashable) { return x.hashValue }
    else { return ObjectIdentifier(v as AnyObject).hashValue }
}

/*==============================================================================================================*/
/// Execute a program and capture it's output.
/// 
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdout: The instance of Data to receive the standard output.
///   - stderr: The instance of Data to receive the standard error.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdout: inout Data, stderr: inout Data) -> Int {
    var _stdout: Data    = Data()
    var _stderr: Data    = Data()
    let pipeOut: Pipe    = Pipe()
    let pipeErr: Pipe    = Pipe()
    let proc:    Process = Process()

    proc.executableURL = URL(fileURLWithPath: exec)
    proc.arguments = args
    proc.standardOutput = pipeOut
    proc.standardError = pipeErr

    do {
        try proc.run()
    }
    catch let e {
        let err = "\(e)"
        stderr = Data(err.utf8)
        #if DEBUG
            FileHandle.standardError.write(stderr)
        #endif
        return -1
    }

    let threadOut = PGThread(startNow: true, qualityOfService: .utility) { _stdout = pipeOut.fileHandleForReading.readDataToEndOfFile() }
    let threadErr = PGThread(startNow: true, qualityOfService: .utility) { _stderr = pipeErr.fileHandleForReading.readDataToEndOfFile() }
    proc.waitUntilExit()
    threadOut.join()
    threadErr.join()
    stdout = _stdout
    stderr = _stderr
    return Int(proc.terminationStatus)
}

/*==============================================================================================================*/
/// Execute a program and capture it's output.
/// 
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdout: The string to receive the standard output.
///   - stderr: The string to receive the standard error.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdout: inout String, stderr: inout String) -> Int {
    var _stdout:  Data = Data()
    var _stderr:  Data = Data()
    let exitCode: Int  = execute(exec: exec, args: args, stdout: &_stdout, stderr: &_stderr)
    stdout = (String(data: _stdout, encoding: .utf8) ?? "")
    stderr = (String(data: _stderr, encoding: .utf8) ?? "")
    return exitCode
}

/*==============================================================================================================*/
/// Execute a program and capture it's output. Anything written to stderr by the program is discarded unless
/// `discardStderr` is set to `false` in which case it is routed to the system's stderr channel.
/// 
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdout: The string to receive the standard output.
///   - discardStderr: If `true` (the default) then anything the program writes to stderr is discarded. If `false`
///                    then anything the program writes to stderr is sent to the system's stderr channel.
/// - Returns: The numeric exit status code returned from the executed program.
///
@inlinable public func execute(exec: String, args: [String], stdout: inout String, discardStderr: Bool = true) -> Int {
    var errMsg:   String = ""
    let exitCode: Int    = execute(exec: exec, args: args, stdout: &stdout, stderr: &errMsg)
    #if DEBUG
        FileHandle.standardError.write(Data(errMsg.utf8))
    #endif
    return exitCode
}

/*==============================================================================================================*/
/// Read the data from a Pipe and return it as a string.
/// 
/// - Parameters:
///   - pipe: The pipe to read from.
///   - encoding: The encoding. Defaults to `UTF-8`.
/// - Returns: The string or `nil` if the encoding failed.
///
@inlinable public func readFromPipe(pipe: Pipe, encoding: String.Encoding = .utf8) -> String? { String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: encoding) }

/*==============================================================================================================*/
/// Execute a program. Anything written to stderr or stdout by the program is discarded unless `discardOutput` is
/// set to `false` in which case it is routed to the system's stderr and stdout channels.
/// 
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - discardOutput: If `true` (the default) then anything the program writes to stderr or stdout is discarded.
///                    If `false` then anything the program writes to stderr or stdout is sent to the system's
///                    stderr and stdout channels.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], discardOutput: Bool = true) -> Int {
    let proc: Process = Process()
    proc.executableURL = URL(fileURLWithPath: exec)
    proc.arguments = args
    proc.standardError = (discardOutput ? FileHandle.nullDevice : FileHandle.standardError)
    proc.standardOutput = (discardOutput ? FileHandle.nullDevice : FileHandle.standardOutput)
    do {
        try proc.run()
    }
    catch let e {
        #if DEBUG
            let err: String = "\(e)"
            FileHandle.standardError.write(Data(err.utf8))
        #endif
        return -1
    }
    proc.waitUntilExit()
    return Int(proc.terminationStatus)
}

/*==============================================================================================================*/
/// Which
/// 
/// - Parameter names: The programs to look for.
/// - Returns: The paths to the programs. If any program couldn't be found then that entry is `nil`.
///
public func which(names: [String]) -> [String?] {
    let ncc: Int = names.count
    guard ncc > 0 else { return [] }

    #if os(Windows)
        let prog: String = "where"
    #else
        let prog: String = "which"
    #endif
    var txt: String    = ""
    var err: String    = ""
    var out: [String?] = []

    for n in names {
        if !n.hasAnyPrefix("/", "-") && (execute(exec: prog, args: [ n ], stdout: &txt, stderr: &err) == 0) { let item: String = txt.split(on: "\\R")[0]; out <+ ((item.trimmed == "") ? nil : item) }
        else { out <+ nil }
    }

    return out
}

/*==============================================================================================================*/
/// Which
/// 
/// - Parameter name: The program to look for.
/// - Returns: The path to the program or `nil` if it couldn't be found.
///
@inlinable public func which(name: String) -> String? { which(names: [ name ])[0] }
