// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: IConv.swift
//         IDE: AppCode
//      AUTHOR: Galen Rhodes
//        DATE: November 05, 2022
//
// Copyright © 2022 Project Galen. All rights reserved.
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

#if os(Linux) || os(iOS) || os(tvOS) || os(watchOS) || os(macOS) || os(macOS)

    import Foundation
    import CoreFoundation
    import iconv
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #endif

    open class IConv {

        public enum Option {
            case None
            case Ignore
            case Transliterate
        }

        public enum IConvStatus {
            case IllegalMultiByteSequence
            case InvalidCharacterForEncoding
            case OutputBufferTooSmall
            case NonIdenticalConversions(count: Int)
        }

/*@f0*/
        public typealias Source = (UnsafeMutableRawPointer, Int) throws -> Int
        public typealias Target = (UnsafeRawPointer, Int) throws -> Bool
        public typealias IConvCounts = (inputCount: Int, outputCount: Int)
        public typealias IConvResults = (results: IConvStatus, newInputLength: Int, outputLength: Int)
/*@f1*/

        @usableFromInline static let InputBufferSize:  Int = 4096
        @usableFromInline static let OutputBufferSize: Int = ((InputBufferSize + 10) * 4)

        @usableFromInline var cd:   iconv_t
        @usableFromInline let lock: NSLock = NSLock()

        /// The name of the input encoding.
        public let inputEncoding:  String
        /// The name of the output encoding.
        public let outputEncoding: String
        /// The options for translation.
        public let option:         Option

        /*==========================================================================================================================================================================*/
        /// Create a new instance of `IConv` to convert characters from one encoding format to another.
        ///
        /// - Parameters:
        ///   - inputEncoding: A string containing the name of the outbound character encoding.
        ///   - outputEncoding: A string containing the name of the inbound character encoding. (Defaults to `"UTF-8"`)
        ///   - option: One of `IConv.Option.None`, `IConv.Option.Ignore`, or `IConv.Option.Transliterate`. (Defaults to `IConv.Option.None`)
        /// - Throws: If either the `outputEncoding` or the `inputEncoding` are not valid or some other error occurs.
        ///
        public init(fromEncoding inputEncoding: String, toEncoding outputEncoding: String = "UTF-8", option: Option = .None) throws {
            self.inputEncoding = inputEncoding
            self.outputEncoding = outputEncoding
            self.option = option
            self.cd = iconv_open(outputEncoding + option.flag, inputEncoding)

            if self.cd == (iconv_t)(bitPattern: -1) {
                switch errno {
                    case EMFILE: throw IConvError.NoAvailableFileDescriptors
                    case ENFILE: throw IConvError.TooManyFilesOpen
                    case ENOMEM: throw IConvError.InsufficientMemory
                    case EINVAL: throw IConvError.UnknownCharacterEncoding
                    default:     throw IConvError.UnknownError(code: errno)
                }
            }
        }

        deinit {
            iconv_close(cd)
        }

        /*==========================================================================================================================================================================*/
        /// Convert a stream of characters from the input encoding to the output encoding.
        ///
        /// - Parameters:
        ///   - input:
        ///   - output:
        /// - Returns: A tuple of type `IConvResults` that contains the number of bytes read from input and the number of bytes written to the output.
        /// - Throws: If there was an error during translation or if one of the closures threw and error.
        ///
        open func convert(input: Source, output: Target) throws -> IConvCounts {
            try lock.withLock {
                let inBuff   = UnsafeMutableRawPointer.allocate(byteCount: IConv.InputBufferSize, alignment: MemoryLayout<CChar>.alignment)
                let outBuff  = UnsafeMutableRawPointer.allocate(byteCount: IConv.OutputBufferSize, alignment: MemoryLayout<CChar>.alignment)
                var inIndex  = 0
                var totalIn  = 0
                var totalOut = 0

                defer {
                    inBuff.deallocate()
                    outBuff.deallocate()
                }

                try initialize()

                repeat {
                    let readCount = try input((inBuff + inIndex), (IConv.InputBufferSize - inIndex))
                    guard readCount > 0 else { return try doFinalize(outBuff, output, totalIn, totalOut) }
                    let (inRemaining, outUsed) = try doConvert(inBuff, (inIndex + readCount), outBuff)

                    inIndex = inRemaining
                    totalIn += readCount
                    totalOut += outUsed

                    guard try output(outBuff, outUsed) else { return (totalIn, totalOut) }
                } while true
            }
        }

        /*==========================================================================================================================================================================*/
        open func convert(input: UnsafeMutableRawPointer, inputLength: Int, output: UnsafeMutableRawPointer, outputMaxLength: Int) throws -> IConvResults {
            try lock.withLock {
                try input.withMemoryRebound(to: CChar.self, capacity: inputLength) { (pIn: UnsafeMutablePointer<CChar>) -> IConvResults in
                    try output.withMemoryRebound(to: CChar.self, capacity: outputMaxLength) { (pOut: UnsafeMutablePointer<CChar>) -> IConvResults in
                        var ppIn:            UnsafeMutablePointer<CChar>? = pIn
                        var ppOut:           UnsafeMutablePointer<CChar>? = pOut
                        var inputRemaining:  Int                          = inputLength
                        var outputRemaining: Int                          = outputMaxLength
                        let iconvResult:     Int                          = iconv(cd, &ppIn, &inputRemaining, &ppOut, &outputRemaining)
                        let outputLength:    Int                          = (outputMaxLength - outputRemaining)
                        let e:               Int32                        = errno

                        if inputRemaining > 0 { memcpy(pIn, ppIn!, inputRemaining) }
                        guard iconvResult == -1 else { return (results: .NonIdenticalConversions(count: iconvResult), newInputLength: inputRemaining, outputLength: outputLength) }

                        switch e {
                            case E2BIG:  return (results: .OutputBufferTooSmall, newInputLength: inputRemaining, outputLength: outputLength)
                            case EINVAL: return (results: .InvalidCharacterForEncoding, newInputLength: inputRemaining, outputLength: outputLength)
                            case EILSEQ: return (results: .IllegalMultiByteSequence, newInputLength: inputRemaining, outputLength: outputLength)
                            default:     throw IConvError.UnknownError(code: e)
                        }
                    }
                }
            }
        }

        /*==========================================================================================================================================================================*/
        /// Get a list of the available encodings on this system.
        ///
        /// - Returns: An array of strings with the names of all the encodings supported.
        /// - Throws: If `iconv` is not available on this system.
        ///
        open class func getEncodingList() throws -> [String] {
            let r = try Process.execute(whichExecutable: "iconv", arguments: ["-l"], inputString: nil)
            #if os(Linux)
                return r.stdOut.split(regex: "//\\s+").sorted()
            #else
                return r.stdOut.split(regex: "\\s+").sorted()
            #endif
        }

        /*==========================================================================================================================================================================*/
        @usableFromInline typealias XResults = (inPtr: UnsafeMutablePointer<CChar>?, inUnusedCount: Int, outPtr: UnsafeMutablePointer<CChar>?, outUnusedCount: Int, error: IConvError?)

        /*==========================================================================================================================================================================*/
        @inlinable class func iConvert(cd: iconv_t, inPtr: UnsafeMutablePointer<CChar>?, inBuffSz: Int, outPtr: UnsafeMutablePointer<CChar>?, outBuffSz: Int) throws -> XResults {
            var inPtrPtr:     UnsafeMutablePointer<CChar>? = inPtr
            var outPtrPtr:    UnsafeMutablePointer<CChar>? = outPtr
            var inRemaining:  Int                          = inBuffSz
            var outRemaining: Int                          = outBuffSz

            let iconvResult: Int         = iconv(cd, &inPtrPtr, &inRemaining, &outPtrPtr, &outRemaining)
            let error:       IConvError? = IConvError.encodingError(result: iconvResult, code: errno)

            guard error == nil || isValue(error!, in: .IllegalMultiByteSequence, .OutputBufferTooSmall, .InvalidCharacterForEncoding) else { throw error! }
            return (inPtrPtr, inRemaining, outPtrPtr, outRemaining, error)
        }
    }

    extension IConv {
        /*==========================================================================================================================================================================*/
        @inlinable func initialize() throws {
            _ = try IConv.iConvert(cd: cd, inPtr: nil, inBuffSz: 0, outPtr: nil, outBuffSz: 0)
        }

        /*==========================================================================================================================================================================*/
        @inlinable func doFinalize(_ outBuff: UnsafeMutableRawPointer, _ output: (UnsafeRawPointer, Int) throws -> Bool, _ totalIn: Int, _ totalOut: Int) throws -> (Int, Int) {
            let outCount = try (IConv.OutputBufferSize - doConvert(nil, 0, outBuff, IConv.OutputBufferSize).outUnusedCount)
            _ = try output(outBuff, outCount)
            return (totalIn, totalOut + outCount)
        }

        /*==========================================================================================================================================================================*/
        @inlinable func doConvert(_ inBuff: UnsafeMutableRawPointer, _ inBuffSz: Int, _ outBuff: UnsafeMutableRawPointer) throws -> (Int, Int) {
            let results = try asCharPtr(inBuff, inBuffSz) { try doConvert($0, inBuffSz, outBuff, IConv.OutputBufferSize) }
            memcpy(inBuff, results.inPtr!, results.inUnusedCount)
            return (results.inUnusedCount, IConv.OutputBufferSize - results.outUnusedCount)
        }

        /*==========================================================================================================================================================================*/
        @inlinable func doConvert(_ inPtr: UnsafeMutablePointer<CChar>?, _ inSz: Int, _ outBuff: UnsafeMutableRawPointer, _ outSz: Int) throws -> XResults {
            try asCharPtr(outBuff, outSz) { try IConv.iConvert(cd: cd, inPtr: inPtr, inBuffSz: inSz, outPtr: $0, outBuffSz: outSz) }
        }

        /*==========================================================================================================================================================================*/
        @inlinable func asCharPtr<R>(_ buff: UnsafeMutableRawPointer, _ sz: Int, _ action: (UnsafeMutablePointer<CChar>) throws -> R) rethrows -> R {
            try buff.withMemoryRebound(to: CChar.self, capacity: sz, action)
        }
    }

    extension IConv.Option {
        /*==========================================================================================================================================================================*/
        @inlinable var flag: String {
            switch self {
                case .None:          return ""
                case .Ignore:        return "//IGNORE"
                case .Transliterate: return "//TRANSLIT"
            }
        }
    }
#endif
