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

    fileprivate var conversionDescriptor: iconv_t

    public let inputEncoding:  String
    public let outputEncoding: String
    public let options:        Options

    public init(to outputEncoding: String = "UTF-8", from inputEncoding: String, options: Options = .None) throws {
        self.inputEncoding = inputEncoding
        self.outputEncoding = outputEncoding
        self.options = options
        self.conversionDescriptor = iconv_open(outputEncoding + options.flag, inputEncoding)

        if self.conversionDescriptor == (iconv_t)(bitPattern: -1) {
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
        iconv_close(conversionDescriptor)
    }

    open func convert(inputData: Data) throws -> (Status, Int, Data) {
        try inputData.withUnsafeBytes { (bp: UnsafeRawBufferPointer) -> (Status, Int, Data) in
            try bp.withMemoryRebound(to: CChar.self) { (bp: UnsafeBufferPointer<CChar>) -> (Status, Int, Data) in
                guard let input = bp.baseAddress else { throw IConvError.InvalidInputBuffer }
                let outputSize: Int                         = ((bp.count + 10) * 4)
                let output:     UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: outputSize)
                let results                                 = try convert(input: input, inputSize: bp.count, output: output, outputSize: outputSize)
                return (results.0, results.1, Data(bytes: UnsafeRawPointer(output), count: results.2))
            }
        }
    }

    open func finalize() throws -> (Status, Int, Data) {
        let outputSize                          = 40
        let output: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: outputSize)
        let results                             = try finalize(output: output, outputSize: outputSize)
        return (results.0, results.1, Data(bytes: UnsafeRawPointer(output), count: results.2))
    }

    open func convert(input: UnsafePointer<UInt8>, inputSize: Int, output: UnsafeMutablePointer<UInt8>, outputSize: Int) throws -> (Status, Int, Int) {
        try output.withMemoryRebound(to: CChar.self, capacity: outputSize) { o in
            try input.withMemoryRebound(to: CChar.self, capacity: inputSize) { i in
                try convert(input: i, inputSize: inputSize, output: o, outputSize: outputSize)
            }
        }
    }

    open func convert(input: UnsafePointer<CChar>, inputSize: Int, output: UnsafeMutablePointer<CChar>, outputSize: Int) throws -> (Status, Int, Int) {
        let inputBuffer: UnsafeMutablePointer<CChar> = UnsafeMutablePointer<CChar>.allocate(capacity: inputSize)
        inputBuffer.initialize(from: input, count: inputSize)
        defer {
            inputBuffer.deinitialize(count: inputSize)
            inputBuffer.deallocate()
        }
        return try convert(input: inputBuffer, inputSize: inputSize, output: output, outputSize: outputSize)
    }

    open func convert(input: UnsafeBufferPointer<UInt8>, output: UnsafeMutableBufferPointer<UInt8>) throws -> (Status, Int, Int) {
        guard let i = input.baseAddress else { throw IConvError.InvalidInputBuffer }
        guard let o = output.baseAddress else { throw IConvError.InvalidOutputBuffer }
        return try convert(input: i, inputSize: input.count, output: o, outputSize: output.count)
    }

    open func finalize(output: UnsafeMutablePointer<UInt8>, outputSize: Int) throws -> (Status, Int, Int) {
        try output.withMemoryRebound(to: CChar.self, capacity: outputSize) { try finalize(output: $0, outputSize: outputSize) }
    }

    open func finalize(output: UnsafeMutablePointer<CChar>, outputSize: Int) throws -> (Status, Int, Int) {
        try convert(input: nil, inputSize: 0, output: output, outputSize: outputSize)
    }

    open func finalize(output: UnsafeMutableBufferPointer<UInt8>) throws -> (Status, Int, Int) {
        guard let o = output.baseAddress else { throw IConvError.InvalidOutputBuffer }
        return try finalize(output: o, outputSize: output.count)
    }

    open func reset() {
        _ = try? convert(input: nil, inputSize: 0, output: nil, outputSize: 0)
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

    public enum Status { case Complete, InvalidSequence, IncompleteSequence, OutputBufferFull }

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

    fileprivate func convert(input: UnsafeMutablePointer<CChar>?, inputSize: Int, output: UnsafeMutablePointer<CChar>?, outputSize: Int) throws -> (Status, Int, Int) {
        var inputBuffer:     UnsafeMutablePointer<CChar>? = input
        var outputBuffer:    UnsafeMutablePointer<CChar>? = output
        var inputRemaining:  Int                          = inputSize
        var outputRemaining: Int                          = outputSize
        let returnValue:     Int                          = iconv(conversionDescriptor, &inputBuffer, &inputRemaining, &outputBuffer, &outputRemaining)

        if returnValue == -1 {
            switch errno {
                case EILSEQ: return (.InvalidSequence, inputSize - inputRemaining, outputSize - outputRemaining)
                case EINVAL: return (.IncompleteSequence, inputSize - inputRemaining, outputSize - outputRemaining)
                case E2BIG:  return (.OutputBufferFull, inputSize - inputRemaining, outputSize - outputRemaining)
                default: throw IConvError.UnknownError(code: errno)
            }
        }

        return (.Complete, inputSize - inputRemaining, outputSize - outputRemaining)
    }
}
