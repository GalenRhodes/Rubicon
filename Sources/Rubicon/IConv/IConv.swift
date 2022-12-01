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

#if !os(Windows)

    import Foundation
    import CoreFoundation
    import iconv
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #endif

    open class IConv {
        public static let InputBufferSize:  Int = 4096
        public static let OutputBufferSize: Int = ((InputBufferSize + 10) * 4)

        public typealias IConvResults = (inPtr: UnsafeMutablePointer<CChar>?, inUnusedCount: Int, outPtr: UnsafeMutablePointer<CChar>?, outUnusedCount: Int, errorCode: Int32)

        public enum Option { case None, Ignore, Transliterate }

        @usableFromInline var cd:   iconv_t
        @usableFromInline let lock: NSLock = NSLock()

        public let inputEncoding:  String
        public let outputEncoding: String
        public let option:         Option

        public init(to outputEncoding: String = "UTF-8", from inputEncoding: String, option: Option = .None) throws {
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

        open func convert(input: (UnsafeMutableRawPointer, Int) throws -> Int, output: (UnsafeRawPointer, Int) throws -> Bool) throws -> (inputCount: Int, outputCount: Int) {
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

                _ = try IConv.iConvert(cd: cd, inPtr: nil, inBuffSz: 0, outPtr: nil, outBuffSz: 0)

                repeat {
                    let readCount = try input((inBuff + inIndex), (IConv.InputBufferSize - inIndex))
                    guard readCount > 0 else { return try doFinalize(outBuff, output, totalIn, totalOut) }
                    let (inRemaining, outUsed) = try doConvert(inBuff, (inIndex + readCount), outBuff)

                    inIndex = inRemaining
                    totalIn += readCount
                    totalOut += outUsed

                    guard try output(outBuff, outUsed) else { return (totalIn, totalOut) }
                }
                while true
            }
        }

        open class func iConvert(cd: iconv_t, inPtr: UnsafeMutablePointer<CChar>?, inBuffSz: Int, outPtr: UnsafeMutablePointer<CChar>?, outBuffSz: Int) throws -> IConvResults {
            var inPtrPtr:     UnsafeMutablePointer<CChar>? = inPtr
            var outPtrPtr:    UnsafeMutablePointer<CChar>? = outPtr
            var inRemaining:  Int                          = inBuffSz
            var outRemaining: Int                          = outBuffSz
            let iconvResult:  Int                          = iconv(cd, &inPtrPtr, &inRemaining, &outPtrPtr, &outRemaining)
            let e:            Int32                        = errno

            guard iconvResult != -1 || isValue(e, in: EILSEQ, EINVAL, E2BIG) else { throw IConvError.UnknownError(code: e) }
            return (inPtrPtr, inRemaining, outPtrPtr, outRemaining, ((iconvResult == -1) ? e : 0))
        }

        open class func getEncodingList() throws -> [String] {
            let r = try Process.execute(whichExecutable: "iconv", arguments: [ "-l" ], inputString: nil)
            #if os(Linux)
                return r.stdOut.split(regex: "//\\s+").sorted()
            #elseif os(iOS) || os(macOS) || os(OSX) || os(tvOS) || os(watchOS)
                return r.stdOut.split(regex: "\\s+").sorted()
            #endif
        }
    }

    extension IConv {
        @inlinable func doFinalize(_ outBuff: UnsafeMutableRawPointer, _ output: (UnsafeRawPointer, Int) throws -> Bool, _ totalIn: Int, _ totalOut: Int) throws -> (Int, Int) {
            let outCount = try (IConv.OutputBufferSize - foo02(nil, 0, outBuff, IConv.OutputBufferSize).outUnusedCount)
            _ = try output(outBuff, outCount)
            return (totalIn, totalOut + outCount)
        }

        @inlinable func doConvert(_ inBuff: UnsafeMutableRawPointer, _ inBuffSz: Int, _ outBuff: UnsafeMutableRawPointer) throws -> (Int, Int) {
            let results = try asCharPtr(inBuff, inBuffSz) { try foo02($0, inBuffSz, outBuff, IConv.OutputBufferSize) }
            memcpy(inBuff, results.inPtr!, results.inUnusedCount)
            return (results.inUnusedCount, IConv.OutputBufferSize - results.outUnusedCount)
        }

        @inlinable func foo02(_ inPtr: UnsafeMutablePointer<CChar>?, _ inSz: Int, _ outBuff: UnsafeMutableRawPointer, _ outSz: Int) throws -> IConvResults {
            try asCharPtr(outBuff, outSz) { try IConv.iConvert(cd: cd, inPtr: inPtr, inBuffSz: inSz, outPtr: $0, outBuffSz: outSz) }
        }

        @inlinable func asCharPtr<R>(_ buff: UnsafeMutableRawPointer, _ sz: Int, _ action: (UnsafeMutablePointer<CChar>) throws -> R) rethrows -> R {
            try buff.withMemoryRebound(to: CChar.self, capacity: sz, action)
        }
    }

    extension IConv.Option {
        @inlinable var flag: String {
            switch self {
                case .None:          return ""
                case .Ignore:        return "//IGNORE"
                case .Transliterate: return "//TRANSLIT"
            }
        }
    }
#endif
