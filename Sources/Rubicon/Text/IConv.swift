/*=================================================================================================================================================================================*
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
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation

#if !os(Windows)
    #if os(Linux) || os(Android) || os(WASI)
        import iconv
        let EncListSep: String = "\\s*/\\s*"
    #else
        let EncListSep: String = "\\s+"
    #endif

    /*==========================================================================================================*/
    /// This class represents a wrapper around the libiconv functions.
    ///
    open class IConv {
        /*======================================================================================================*/
        /// The response from IConv.
        ///
        public typealias Response = (results: Results, inputBytesUsed: Int, outputBytesUsed: Int)

        /*======================================================================================================*/
        /// The name of the source character encoding.
        ///
        public let fromEncoding:        String
        /*======================================================================================================*/
        /// The name of the target character encoding.
        ///
        public let toEncoding:          String
        /*======================================================================================================*/
        /// If `true` then IConv will ignore invalid character encodings.
        ///
        public let ignoreErrors:        Bool
        /*======================================================================================================*/
        /// If `true` then IConv will enable transliteration.
        ///
        public let enableTransliterate: Bool
        /*======================================================================================================*/
        /// A list of all the available character encodings on this system.
        ///
        public static var encodingsList: [String] = {
            var stdout: String = ""
            guard let exePath = which(name: "iconv") else { return [ "UTF-8" ] }
            guard execute(exec: exePath, args: [ "-l" ], stdout: &stdout) == 0 else { return [ "UTF-8" ] }
            guard let rx = RegularExpression(pattern: EncListSep) else { return [ "UTF-8" ] }
            var arr: [String]     = []
            var idx: StringIndex = stdout.startIndex
            rx.forEach(in: stdout) { match, _, _ in if let m = match { fooo(&arr, stdout, &idx, m.range) } }
            fooo(&arr, stdout, idx, stdout.endIndex)
            return Array<String>(Set<String>(arr)).sorted()
        }()

        /*======================================================================================================*/
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

        @IConvHandle private var handle: iconv_t? = nil

        /*======================================================================================================*/
        /// Create a new instance of IConv.
        /// 
        /// - Parameters:
        ///   - toEncoding: The target encoding name.
        ///   - fromEncoding: The source encoding name.
        ///   - ignoreErrors: `true` if encoding errors should be ignored. The default is `false`.
        ///   - enableTransliterate: `true` if transliteration should be enabled. The default is `false`.
        ///
        public init(toEncoding: String, fromEncoding: String, ignoreErrors: Bool = false, enableTransliterate: Bool = false) {
            self.toEncoding = toEncoding
            self.fromEncoding = fromEncoding
            self.ignoreErrors = ignoreErrors
            self.enableTransliterate = enableTransliterate
            self.handle = iconv_open("\(toEncoding)\(ignoreErrors ? "//IGNORE" : "")\(enableTransliterate ? "//TRANSLIT" : "")", "\(fromEncoding)")
        }

        deinit {
            close()
        }

        /*======================================================================================================*/
        /// Close this instance of IConv and free it's resources. This is also done automatically when the object
        /// is disposed of by ARC.
        ///
        open func close() {
            guard let h = handle else { return }
            iconv_close(h)
            handle = nil
        }

        /*======================================================================================================*/
        /// Reset the converter.
        /// 
        /// - Returns: `Results.OK` if successful. `Results.OtherError` if not successful.
        ///
        open func reset() -> Results {
            guard let h = handle else { return .UnknownEncoding }

            var inSz:  Int = 0
            var outSz: Int = 0
            let r:     Int = iconv(h, nil, &inSz, nil, &outSz)

            return ((r == -1) ? .OtherError : .OK)
        }

        /*======================================================================================================*/
        /// Convert the contents of the `input` buffer and store in the `output` buffer.
        /// 
        /// - Parameters:
        ///   - input: The input buffer.
        ///   - length: The number of bytes in the input buffer.
        ///   - output: The output buffer.
        ///   - maxLength: The maximum number of bytes the output buffer can hold.
        /// - Returns: The response.
        ///
        open func convert(input: UnsafeRawPointer, length: Int, output: UnsafeMutableRawPointer, maxLength: Int) -> Response {
            guard let h = handle else { return (.UnknownEncoding, 0, 0) }

            var inSz:  Int           = length
            var outSz: Int           = maxLength
            var inP:   CCharPointer? = UnsafeMutableRawPointer(mutating: input).bindMemory(to: CChar.self, capacity: inSz)
            var outP:  CCharPointer? = output.bindMemory(to: CChar.self, capacity: outSz)
            let res:   Int           = iconv(h, &inP, &inSz, &outP, &outSz)

            return getResponse(callResponse: res, inUsed: (length - inSz), outUsed: (maxLength - outSz))
        }

        /*======================================================================================================*/
        /// Convert the contents of the `input` buffer and store in the `output` buffer.
        /// 
        /// - Parameters:
        ///   - input: The input buffer.
        ///   - output: The output buffer.
        /// - Returns: The results.
        ///
        open func convert(input i: MutableManagedByteBuffer, output o: MutableManagedByteBuffer) -> Results {
            return i.withBytes { inBytes, inLen, inCount -> Results in
                o.withBytes { outBytes, outLen, outCount -> Results in
                    let r = convert(input: inBytes, length: inCount, output: outBytes, maxLength: outLen)
                    outCount = r.outputBytesUsed
                    inCount -= r.inputBytesUsed
                    i.relocateToFront(start: r.inputBytesUsed, count: inCount)
                    return r.results
                }
            }
        }

        /*======================================================================================================*/
        /// Convert a string into bytes with a given encoding.
        /// 
        /// - Parameters:
        ///   - string: The string to convert.
        ///   - encoding: The encoding to use.
        ///   - ignoreErrors: `true` if invalid sequences should be ignored.
        ///   - enableTransliterate: `true` if transliteration should be used.
        /// - Returns: A `Data` structure containing the bytes.
        ///
        public static func convert(string: String, encoding: String, ignoreErrors: Bool = false, enableTransliterate: Bool = false) -> Data? {
            let iconv:   IConv                    = IConv(toEncoding: encoding, fromEncoding: "UTF-8", ignoreErrors: ignoreErrors, enableTransliterate: enableTransliterate)
            let utf8str: String.UTF8View          = string.utf8
            let bInput:  MutableManagedByteBuffer = EasyByteBuffer(length: 1024)
            let bOutput: MutableManagedByteBuffer = EasyByteBuffer(length: ((1024 * 4) + 1024))
            var data:    Data                     = Data()

            for byte: UInt8 in utf8str {
                if bInput.append(byte: byte) == nil {
                    guard processIconvResults(&data, bOutput, iconv.convert(input: bInput, output: bOutput), false) else { return nil }
                    bInput.append(byte: byte)
                }
            }

            if bInput.count > 0 { guard processIconvResults(&data, bOutput, iconv.convert(input: bInput, output: bOutput), true) else { return nil } }
            guard processIconvResults(&data, bOutput, iconv.finalConvert(output: bOutput), true) else { return nil }
            return data
        }

        private static func processIconvResults(_ data: inout Data, _ bOutput: MutableManagedByteBuffer, _ results: Results, _ isFinal: Bool) -> Bool {
            switch results {
                case .InvalidSequence:    return false
                case .UnknownEncoding:    return false
                case .OtherError:         return false
                case .IncompleteSequence: if isFinal { bOutput.append(byte: 0x3f) }
                default:                  break
            }
            bOutput.withBytes { p, l, c -> Void in data.append(p, count: c); c = 0 }
            return true
        }

        /*======================================================================================================*/
        /// Do the final conversion step after all of the input has been processed to get any deferred conversions
        /// that might be waiting.
        /// 
        /// - Parameters:
        ///   - output: The output buffer.
        ///   - maxLength: The maximum length of the output buffer.
        /// - Returns: A `Response` tuple.
        ///
        open func finalConvert(output: UnsafeMutableRawPointer, maxLength: Int) -> Response {
            guard let h = handle else { return (.UnknownEncoding, 0, 0) }

            var outSz: Int           = maxLength
            var outP:  CCharPointer? = output.bindMemory(to: CChar.self, capacity: outSz)
            let res:   Int           = iconv(h, nil, nil, &outP, &outSz)

            return getResponse(callResponse: res, inUsed: 0, outUsed: (maxLength - outSz))
        }

        /*======================================================================================================*/
        /// Do the final conversion step after all of the input has been processed to get any deferred conversions
        /// that might be waiting.
        /// 
        /// - Parameter o: the output buffer.
        /// - Returns: The `Results`.
        ///
        open func finalConvert(output o: MutableManagedByteBuffer) -> Results {
            o.withBytes { outBytes, outLen, outCount -> Results in
                let r = finalConvert(output: outBytes, maxLength: outLen)
                outCount = r.outputBytesUsed
                return r.results
            }
        }

        /*======================================================================================================*/
        /// Convert the contents of the input stream. This method reads the input stream in 1,024 byte chunks,
        /// converts those bytes, and then calls the give closure with the results of that conversion.
        /// 
        /// - Parameters:
        ///   - inputStream: The input stream.
        ///   - body: The closure to handle each converted chunk.
        /// - Throws: If an I/O error occurs or a conversion error occurs.
        ///
        open func with(inputStream: InputStream, do body: (BytePointer, Int) throws -> Bool) throws {
            if inputStream.streamStatus == .notOpen { inputStream.open() }

            let inBuff:  EasyByteBuffer = EasyByteBuffer(length: 1024)
            let outBuff: EasyByteBuffer = EasyByteBuffer(length: 4100)
            var ioRes:   Int            = try inputStream.read(to: inBuff)

            while ioRes > 0 {
                if try doWithIconv(ioRes, inBuff, outBuff, body) { break }
                ioRes = try inputStream.read(to: inBuff)
            }

            if ioRes == 0 && inBuff.count > 0 { _ = try doWithIconv(ioRes, inBuff, outBuff, body) }
        }

        /*======================================================================================================*/
        /// Convert a chunk of data.
        /// 
        /// - Parameters:
        ///   - ioRes: The number of bytes read from the input stream.
        ///   - inBuff: The input buffer.
        ///   - outBuff: The output buffer.
        ///   - body: The closure to call with the converted data.
        /// - Returns: `true` if the conversion whould be halted.
        /// - Throws: If an I/O error occurs or a conversion error occurs.
        ///
        private func doWithIconv(_ ioRes: Int, _ inBuff: MutableManagedByteBuffer, _ outBuff: MutableManagedByteBuffer, _ body: (BytePointer, Int) throws -> Bool) throws -> Bool {
            let iconvRes: Results = convert(input: inBuff, output: outBuff)
            let stop: Bool = try outBuff.withBytes { p, l, c -> Bool in try body(p, c) }

            switch iconvRes {
                case .InvalidSequence: throw CErrors.EILSEQ
                case .OtherError:      throw CErrors.UNKNOWN
                default:               break
            }

            return stop
        }

        /*======================================================================================================*/
        /// Convert the data returned from the call to `iconv(_ :, _:, _:, _:, _:)` to a `Response` tuple.
        /// 
        /// - Parameters:
        ///   - res: The results returned from the call.
        ///   - inUsed: The number of input bytes used.
        ///   - outUsed: The number of output bytes used.
        /// - Returns: The `Response` tuple.
        ///
        private func getResponse(callResponse res: Int, inUsed: Int, outUsed: Int) -> Response {
            if res >= 0 { return (.OK, inUsed, outUsed) }

            switch errno {
                case E2BIG:  return (.InputTooBig, inUsed, outUsed)
                case EINVAL: return (.IncompleteSequence, inUsed, outUsed)
                case EILSEQ: return (.InvalidSequence, inUsed, outUsed)
                default:     return (.OtherError, inUsed, outUsed)
            }
        }
    }

    /*==========================================================================================================*/
    /// A private property wrapper for the iconv handle to convert a `-1` to a `nil`.
    ///
    @propertyWrapper fileprivate struct IConvHandle {
        var wrappedValue: iconv_t? {
            get { value }
            set { value = ((newValue == (iconv_t)(bitPattern: -1)) ? nil : newValue) }
        }
        private var value: iconv_t? = nil

        init(wrappedValue: iconv_t?) { self.wrappedValue = wrappedValue }
    }

    fileprivate func fooo(_ arr: inout [String], _ str: String, _ sIdx: StringIndex, _ eIdx: StringIndex) {
        let s = String(str[sIdx ..< eIdx]).trimmed
        if s.count > 0 { arr <+ s }
    }

    fileprivate func fooo(_ arr: inout [String], _ str: String, _ sIdx: inout StringIndex, _ range: StringRange) {
        fooo(&arr, str, sIdx, range.lowerBound)
        sIdx = range.upperBound
    }
#endif
