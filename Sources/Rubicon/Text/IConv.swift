/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: IConv.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 1/5/21
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
#if os(Linux)
    import iconv
#endif

/*===============================================================================================================================================================================*/
/// This class represents a wrapper around the libiconv functions.
///
open class IConv {

    /*===========================================================================================================================================================================*/
    /// The response from IConv.
    ///
    public typealias Response = (results: Results, inputBytesUsed: Int, outputBytesUsed: Int)

    /*===========================================================================================================================================================================*/
    /// A list of all the available character encodings on this system.
    ///
    public static var encodingsList: [String] = getEncodingsList()
    /*===========================================================================================================================================================================*/
    /// The name of the source character encoding.
    ///
    public let fromEncoding:        String
    /*===========================================================================================================================================================================*/
    /// The name of the target character encoding.
    ///
    public let toEncoding:          String
    /*===========================================================================================================================================================================*/
    /// If `true` then IConv will ignore invalid character encodings.
    ///
    public let ignoreErrors:        Bool
    /*===========================================================================================================================================================================*/
    /// If `true` then IConv will enable transliteration.
    ///
    public let enableTransliterate: Bool

    /*===========================================================================================================================================================================*/
    /// Enumeration of the possible results of the conversion.
    ///
    public enum Results: Equatable {
        case OK
        case IncompleteSequence
        case InputTooBig
        case InvalidSequence
        case UnknownEncoding
        case OtherError
    }

    lazy var handle: iconv_t? = iconv_open("\(toEncoding)\(ignoreErrors ? "//IGNORE" : "")\(enableTransliterate ? "//TRANSLIT" : "")", "\(fromEncoding)")

    /*===========================================================================================================================================================================*/
    /// Create a new instance of IConv.
    ///
    /// - Parameters:
    ///   - toEncoding: the target encoding name.
    ///   - fromEncoding: the source encoding name.
    ///   - ignoreErrors: `true` if encoding errors should be ignored. The default is `false`.
    ///   - enableTransliterate: `true` if transliteration should be enabled. The default is `false`.
    ///
    public init(toEncoding: String, fromEncoding: String, ignoreErrors: Bool = false, enableTransliterate: Bool = false) {
        self.toEncoding = toEncoding
        self.fromEncoding = fromEncoding
        self.ignoreErrors = ignoreErrors
        self.enableTransliterate = enableTransliterate
    }

    deinit {
        if let h = handle, h != (iconv_t)(bitPattern: -1) { iconv_close(h) }
    }

    /*===========================================================================================================================================================================*/
    /// Reset the converter.
    ///
    /// - Returns: `Results.OK` if successful. `Results.OtherError` if not successful.
    ///
    open func reset() -> Results {
        guard let h = handle, h != (iconv_t)(bitPattern: -1) else { return .UnknownEncoding }

        var inSz:  Int = 0
        var outSz: Int = 0
        let r:     Int = iconv(h, nil, &inSz, nil, &outSz)

        return ((r == -1) ? .OtherError : .OK)
    }

    /*===========================================================================================================================================================================*/
    /// Convert the contents of the `input` buffer and store in the `output` buffer.
    ///
    /// - Parameters:
    ///   - input: the input buffer.
    ///   - length: the number of bytes in the input buffer.
    ///   - output: the output buffer.
    ///   - maxLength: the maximum number of bytes the output buffer can hold.
    /// - Returns: the response.
    ///
    open func convert(input: UnsafeRawPointer, length: Int, output: UnsafeMutableRawPointer, maxLength: Int) -> Response {
        guard let h = handle, h != (iconv_t)(bitPattern: -1) else { return (.UnknownEncoding, 0, 0) }

        var inSz:    Int           = length
        var outSz:   Int           = maxLength
        var inP:     CCharPointer? = UnsafeMutableRawPointer(mutating: input).bindMemory(to: CChar.self, capacity: inSz)
        var outP:    CCharPointer? = output.bindMemory(to: CChar.self, capacity: outSz)
        let res:     Int           = iconv(h, &inP, &inSz, &outP, &outSz)
        let inUsed:  Int           = (length - inSz)
        let outUsed: Int           = (maxLength - outSz)

        if res >= 0 { return (.OK, inUsed, outUsed) }

        switch errno {
            case E2BIG:  return (.InputTooBig, inUsed, outUsed)
            case EINVAL: return (.IncompleteSequence, inUsed, outUsed)
            case EILSEQ: return (.InvalidSequence, inUsed, outUsed)
            default:     return (.OtherError, inUsed, outUsed)
        }
    }

    /*===========================================================================================================================================================================*/
    /// Convert the contents of the `input` buffer and store in the `output` buffer.
    ///
    /// - Parameters:
    ///   - input: the input buffer.
    ///   - output: the output buffer.
    /// - Returns: the results.
    ///
    open func convert(input: EasyByteBuffer, output: EasyByteBuffer) -> Results {
        let r = convert(input: input.bytes, length: input.count, output: output.bytes, maxLength: output.length)
        output.count = r.outputBytesUsed
        input.relocateToFront(start: r.inputBytesUsed, count: (input.count - r.inputBytesUsed))
        return r.results
    }

    /*===========================================================================================================================================================================*/
    /// Convert the contents of the input stream. This method reads the input stream in 1,024 byte chunks, converts those bytes, and then calls the give closure with the results
    /// of that conversion.
    ///
    /// - Parameters:
    ///   - inputStream: the input stream.
    ///   - body: the closure to handle each converted chunk.
    /// - Throws: if an I/O error occurs or a conversion error occurs.
    ///
    open func with(inputStream: InputStream, do body: (BytePointer, Int) throws -> Bool) throws {
        if inputStream.streamStatus == .notOpen { inputStream.open() }

        let inBuff:  EasyByteBuffer = EasyByteBuffer(length: 1024)
        let outBuff: EasyByteBuffer = EasyByteBuffer(length: 4100)
        var ioRes:   Int            = inputStream.read(inBuff.bytes, maxLength: inBuff.length)

        while ioRes > 0 {
            if try doWithIconv(ioRes, inBuff, outBuff, body) { break }
            ioRes = inputStream.read((inBuff.bytes + inBuff.count), maxLength: (inBuff.length - inBuff.count))
        }

        if ioRes == 0 && inBuff.count > 0 { _ = try doWithIconv(ioRes, inBuff, outBuff, body) }
        else if ioRes < 0 { throw inputStream.streamError ?? StreamError.UnknownError() }
    }

    /*===========================================================================================================================================================================*/
    /// Convert a chunk of data.
    ///
    /// - Parameters:
    ///   - ioRes: the number of bytes read from the input stream.
    ///   - inBuff: the input buffer.
    ///   - outBuff: the output buffer.
    ///   - body: the closure to call with the converted data.
    /// - Returns: `true` if the conversion whould be halted.
    /// - Throws: if an I/O error occurs or a conversion error occurs.
    ///
    private func doWithIconv(_ ioRes: Int, _ inBuff: EasyByteBuffer, _ outBuff: EasyByteBuffer, _ body: (BytePointer, Int) throws -> Bool) throws -> Bool {
        inBuff.count = ioRes

        let iconvRes: Results = convert(input: inBuff, output: outBuff)
        let stop:     Bool    = try body(outBuff.bytes, outBuff.count)

        switch iconvRes {
            case .InvalidSequence: throw CErrors.ILSEQ()
            case .OtherError:      throw CErrors.UNKNOWN(code: -1)
            default:               break
        }

        return stop
    }

    /*===========================================================================================================================================================================*/
    /// Get the list of available encodings.
    ///
    /// - Returns: an array of strings.
    ///
    private static func getEncodingsList() -> [String] {
        let data = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: MaxEncodings)
        data.initialize(repeating: nil, count: MaxEncodings)

        defer {
            for i in (0 ..< MaxEncodings) { if let p: UnsafeMutablePointer<Int8> = data[i] { p.deallocate() } }
            data.deallocate()
        }

        iconvlist({ (count: UInt32, p: UnsafePointer<UnsafePointer<Int8>?>?, d: UnsafeMutableRawPointer?) -> Int32 in
                      if let p = p, let d = d {
                          let _data: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> = d.bindMemory(to: UnsafeMutablePointer<Int8>?.self, capacity: MaxEncodings)
                          for i in (0 ..< Int(count)) {
                              if let p2: UnsafePointer<Int8> = p[i] {
                                  guard let z = NextSlot(_data) else { return 1 }
                                  _data[z] = CopyStr(p2)
                              }
                          }
                      }
                      return 0
                  }, data)

        var list: [String] = []
        for i in (0 ..< MaxEncodings) { if let p = data[i] { if let str = String(utf8String: p) { list <+ str.uppercased() } } }
        list.sort()
        return list
    }
}

/*===============================================================================================================================================================================*/
/// Copy a NULL terminated C string.
///
/// - Parameter str: a pointer to the C string.
/// - Returns: the copy of the C string.
///
fileprivate func CopyStr(_ str: UnsafePointer<Int8>) -> UnsafeMutablePointer<Int8> {
    let len = StrLen(str)
    let x   = UnsafeMutablePointer<Int8>.allocate(capacity: len)
    x.initialize(from: str, count: len)
    return x
}

/*===============================================================================================================================================================================*/
/// Get the next free index.
///
/// - Parameter data: the data array.
/// - Returns: the next free index or `nil` if the array is full.
///
fileprivate func NextSlot(_ data: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Int? {
    for i in (0 ..< MaxEncodings) { if data[i] == nil { return i } }
    return nil
}

/*===============================================================================================================================================================================*/
/// Get the length of a NULL terminated C string.
///
/// - Parameter str: the C string.
/// - Returns: it's length.
///
fileprivate func StrLen(_ str: UnsafePointer<Int8>) -> Int {
    var len = 0
    while str[len] != 0 { len += 1 }
    return len + 1
}

/*===============================================================================================================================================================================*/
/// The maximum number of encoding names to list.
///
fileprivate let MaxEncodings: Int = 5_000
