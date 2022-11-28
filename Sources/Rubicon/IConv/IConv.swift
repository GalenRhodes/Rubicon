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
        public static let FinalizeOutputSize: Int = 40

        public typealias Result = (status: Status, inputCount: Int, outputCount: Int)
        public typealias DataResult = (status: Status, inputCount: Int, output: Data)
        public typealias FinalResult = (status: Status, outputCount: Int)
        public typealias FinalDataResult = (status: Status, output: Data)

        private var cd:             iconv_t
        public let  inputEncoding:  String
        public let  outputEncoding: String
        public let  options:        Options

        public init(to outputEncoding: String = "UTF-8", from inputEncoding: String, options: Options = .None) throws {
            self.inputEncoding = inputEncoding
            self.outputEncoding = outputEncoding
            self.options = options
            self.cd = iconv_open(outputEncoding + options.flag, inputEncoding)

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

        open class func getEncodingList() throws -> [String] {
            let (_, stdOut, _) = try Process.execute(executableURL: URL(fileURLWithPath: "/usr/bin/iconv"), arguments: [ "-l" ], inputString: nil)
            if let str = stdOut {
                #if os(Linux)
                    return str.split(regex: "//\\s+").sorted()
                #elseif os(iOS) || os(macOS) || os(OSX) || os(tvOS) || os(watchOS)
                    return str.split(regex: "\\s+").sorted()
                #endif
            }
            return []
        }

        public enum Status { case Complete, InvalidSequence, IncompleteSequence, OutputBufferFull, Error(_ error: IConvError) }

        public enum Options {
            case None, Ignore, Transliterate

            fileprivate var flag: String {
                switch self {
                    case .None:          return ""
                    case .Ignore:        return "//IGNORE"
                    case .Transliterate: return "//TRANSLIT"
                }
            }
        }

        @usableFromInline func _convert(_ ip: UnsafeMutablePointer<CChar>?, _ inputSize: Int, _ op: UnsafeMutablePointer<CChar>?, _ outputSize: Int) -> Result {
            var inputBuffer:  UnsafeMutablePointer<CChar>? = ip
            var outputBuffer: UnsafeMutablePointer<CChar>? = op
            var inRem:        Int                          = inputSize
            var outRem:       Int                          = outputSize

            let r:     Int   = iconv(cd, &inputBuffer, &inRem, &outputBuffer, &outRem)
            let inCc:  Int   = (inputSize - inRem)
            let outCc: Int   = (outputSize - outRem)
            let er:    Int32 = errno

            if r != -1 { return (.Complete, inCc, outCc) }

            switch er {
                case EILSEQ: return (.InvalidSequence, inCc, outCc)
                case EINVAL: return (.IncompleteSequence, inCc, outCc)
                case E2BIG:  return (.OutputBufferFull, inCc, outCc)
                default:     return (.Error(IConvError.UnknownError(code: er)), inCc, outCc)
            }
        }
    }

    extension IConv {
        @inlinable public func convert(inputData: Data) throws -> DataResult {
            inputData.withUnsafeBytes { (ip: UnsafeRawBufferPointer) -> DataResult in
                let op = UnsafeMutableRawBufferPointer.allocate(byteCount: ((ip.count + 10) * 4), alignment: MemoryLayout<CChar>.alignment)
                let rs = convert(input: ip, output: op)
                return op.withBaseAddress { b, _ in (rs.status, rs.inputCount, Data(bytes: b, count: rs.outputCount)) }
            }
        }

        @inlinable public func convert(input: UnsafeRawBufferPointer, output: UnsafeMutableRawBufferPointer) -> Result {
            input.withBaseAddress { ip, il in output.withBaseAddress { op, ol in convert(input: ip, inputSize: il, output: op, outputSize: ol) } }
        }

        @inlinable public func convert(input: UnsafeRawPointer, inputSize: Int, output: UnsafeMutableRawPointer, outputSize: Int) -> Result {
            input.asMutable { mp in
                mp.withMemoryRebound(to: CChar.self, capacity: inputSize) { ip in
                    output.withMemoryRebound(to: CChar.self, capacity: outputSize) { op in _convert(ip, inputSize, op, outputSize) }
                }
            }
        }

        @inlinable public func finalize() throws -> FinalDataResult {
            withTemporaryRawBuffer(byteCount: IConv.FinalizeOutputSize, alignment: MemoryLayout<CChar>.alignment) {
                let rs = finalize(output: $0, outputSize: $1)
                return (rs.status, Data(bytes: $0, count: rs.outputCount))
            }
        }

        @inlinable public func finalize(output: UnsafeMutableRawPointer, outputSize: Int) -> FinalResult {
            let r = output.withMemoryRebound(to: CChar.self, capacity: outputSize) { _convert(nil, 0, $0, outputSize) }
            return (r.status, r.outputCount)
        }

        @inlinable public func finalize(output: UnsafeMutableRawBufferPointer) -> FinalResult { output.withBaseAddress { finalize(output: $0, outputSize: $1) } }

        @inlinable @discardableResult public func reset() -> Result { return _convert(nil, 0, nil, 0) }
    }
#endif
