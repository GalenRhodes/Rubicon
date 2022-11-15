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

import Foundation
import CoreFoundation
import iconv
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

open class IConv {

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

    open func convert(inputData: Data) throws -> (Status, Int, Data) {
        inputData.withUnsafeBytes { (ip: UnsafeRawBufferPointer) -> (Status, Int, Data) in
            let op           = UnsafeMutableRawBufferPointer.allocate(byteCount: ((ip.count + 10) * 4), alignment: MemoryLayout<CChar>.alignment)
            let (st, ic, oc) = convert(input: ip, output: op)
            return op.withBaseAddress { b, _ in (st, ic, Data(bytes: b, count: oc)) }
        }
    }

    open func convert(input: UnsafeRawBufferPointer, output: UnsafeMutableRawBufferPointer) -> (Status, Int, Int) {
        input.withBaseAddress { ip, il -> (Status, Int, Int) in
            output.withBaseAddress { op, ol -> (Status, Int, Int) in
                convert(input: ip, inputSize: il, output: op, outputSize: ol)
            }
        }
    }

    open func convert(input: UnsafeRawPointer, inputSize: Int, output: UnsafeMutableRawPointer, outputSize: Int) -> (Status, Int, Int) {
        convert0(UnsafeMutableRawPointer(mutating: input), inputSize, output, outputSize)
    }

    open func finalize() throws -> (Status, Data) {
        let outputSize = 40
        let op         = UnsafeMutableRawPointer.allocate(byteCount: outputSize, alignment: MemoryLayout<CChar>.alignment)
        let (st, oc)   = finalize(output: op, outputSize: outputSize)
        return (st, Data(bytes: op, count: oc))
    }

    open func finalize(output: UnsafeMutableRawBufferPointer) -> (Status, Int) {
        output.withBaseAddress { finalize(output: $0, outputSize: $1) }
    }

    open func finalize(output: UnsafeMutableRawPointer, outputSize: Int) -> (Status, Int) {
        let (st, _, oc) = convert0(nil, 0, output, outputSize)
        return (st, oc)
    }

    @discardableResult open func reset() -> (Status, Int, Int) {
        convert0(nil, 0, nil, 0)
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

    private func convert0(_ input: UnsafeMutableRawPointer?, _ inputSize: Int, _ output: UnsafeMutableRawPointer?, _ outputSize: Int) -> (Status, Int, Int) {
        if let input = input, let output = output {
            return convert1(input, inputSize, output, outputSize)
        }
        else if let output = output {
            return convert2(output, outputSize)
        }
        else {
            return convert3()
        }
    }

    private func convert1(_ input: UnsafeMutableRawPointer, _ inputSize: Int, _ output: UnsafeMutableRawPointer, _ outputSize: Int) -> (Status, Int, Int) {
        input.withMemoryRebound(to: CChar.self, capacity: inputSize) { ip in
            output.withMemoryRebound(to: CChar.self, capacity: outputSize) { op in
                var inputBuffer:  UnsafeMutablePointer<CChar>? = ip
                var outputBuffer: UnsafeMutablePointer<CChar>? = op
                return convertX(&inputBuffer, inputSize, &outputBuffer, outputSize)
            }
        }
    }

    private func convert2(_ output: UnsafeMutableRawPointer, _ outputSize: Int) -> (Status, Int, Int) {
        output.withMemoryRebound(to: CChar.self, capacity: outputSize) { op in
            var inputBuffer:  UnsafeMutablePointer<CChar>? = nil
            var outputBuffer: UnsafeMutablePointer<CChar>? = op
            return convertX(&inputBuffer, 0, &outputBuffer, outputSize)
        }
    }

    private func convert3() -> (Status, Int, Int) {
        var inputBuffer:  UnsafeMutablePointer<CChar>? = nil
        var outputBuffer: UnsafeMutablePointer<CChar>? = nil
        return convertX(&inputBuffer, 0, &outputBuffer, 0)
    }

    private func convertX(_ inputBuffer: inout UnsafeMutablePointer<CChar>?, _ inputSize: Int, _ outputBuffer: inout UnsafeMutablePointer<CChar>?, _ outputSize: Int) -> (Status, Int, Int) {
        var inputRemaining:  Int = inputSize
        var outputRemaining: Int = outputSize

        if iconv(cd, &inputBuffer, &inputRemaining, &outputBuffer, &outputRemaining) == -1 {
            switch errno {
                case EILSEQ: return (.InvalidSequence, inputSize - inputRemaining, outputSize - outputRemaining)
                case EINVAL: return (.IncompleteSequence, inputSize - inputRemaining, outputSize - outputRemaining)
                case E2BIG:  return (.OutputBufferFull, inputSize - inputRemaining, outputSize - outputRemaining)
                default:     return (.Error(IConvError.UnknownError(code: errno)), inputSize - inputRemaining, outputSize - outputRemaining)
            }
        }

        return (.Complete, inputSize - inputRemaining, outputSize - outputRemaining)
    }
}
