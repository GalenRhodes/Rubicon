/*===============================================================================================================================================================================*
 *     PROJECT: Rubicon
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/8/21
 *
 * Copyright © 2021 Project Galen. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation
#if os(Windows)
    import WinSDK
#endif

/*==============================================================================================================*/
/// Applications that run on Linux need to have the main dispatch queue running in order to use Grand Central
/// Dispatch. This function does that.
///
/// - Parameter exec: The closure that runs your application.
/// - Returns: The exit code for your application or `1` if your application threw an uncaught error.
///
@inlinable public func launchApplication(exec: ([String]) throws -> Int32) -> Never {
    withoutActuallyEscaping(exec) { _exec in
        DispatchQueue.main.async {
            do {
                exit(try _exec(CommandLine.arguments))
            }
            catch let e {
                try? "UNCAUGHT ERROR: \(e)".write(toFile: "/dev/stderr", atomically: false, encoding: .utf8)
                exit(1)
            }
        }
    }
    dispatchMain()
}

/*==============================================================================================================*/
/// Execute a program and capture it's output.
///
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdin: Data to be provided to the program on stdin.
///   - stdout: The instance of Data to receive the standard output.
///   - stderr: The instance of Data to receive the standard error.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdin: Data, stdout: inout Data, stderr: inout Data) -> Int {
    let pipeIn: Pipe = Pipe()
    let thread = PGThread(startNow: false, qualityOfService: .utility) { pipeIn.fileHandleForWriting.write(stdin); try? pipeIn.fileHandleForWriting.close() }
    thread.start()
    return execute(exec: exec, args: args, stdin: pipeIn, stdout: &stdout, stderr: &stderr)
}

/*==============================================================================================================*/
/// Execute a program and capture it's output.
///
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdin: An instance of Pipe or FileHandle that will provide input to the program on the stdin channel.
///   - stdout: The instance of Data to receive the standard output.
///   - stderr: The instance of Data to receive the standard error.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdin: Any? = nil, stdout: inout Data, stderr: inout Data) -> Int {
    var _stdout: Data    = Data()
    var _stderr: Data    = Data()
    let pipeOut: Pipe    = Pipe()
    let pipeErr: Pipe    = Pipe()
    let proc:    Process = Process()
    var error:   Error?  = nil

    proc.executableURL = URL(fileURLWithPath: exec)
    proc.arguments = args
    proc.standardInput = stdin
    proc.standardOutput = pipeOut
    proc.standardError = pipeErr

    guard launchProcess(process: proc, error: &error) else {
        if let e = error { stderr = Data(e.localizedDescription.utf8) }
        return -1
    }

    let threadOut = PGThread(startNow: true, qualityOfService: .utility) { _stdout = pipeOut.fileHandleForReading.readDataToEndOfFile(); try? pipeOut.fileHandleForReading.close() }
    let threadErr = PGThread(startNow: true, qualityOfService: .utility) { _stderr = pipeErr.fileHandleForReading.readDataToEndOfFile(); try? pipeErr.fileHandleForReading.close() }
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
///   - stdin: A string containting input to be sent to the program on stdin.
///   - stdout: The string to receive the standard output.
///   - stderr: The string to receive the standard error.
///   - encoding: The encoding of the input, output and error.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdin: String, stdout: inout String, stderr: inout String, encoding: String.Encoding = .utf8) -> Int {
    let pipeIn = Pipe()
    let thread = PGThread(startNow: false, qualityOfService: .utility) {
        var bytes:  [UInt8]             = Array<UInt8>(repeating: 0, count: 1024)
        var used:   Int                 = 0
        var range:  StringRange = (stdin.startIndex ..< stdin.startIndex)
        var result: Bool                = stdin.getBytes(&bytes, maxLength: 1024, usedLength: &used, encoding: encoding, range: stdin.fullRange, remaining: &range)

        while result {
            pipeIn.fileHandleForWriting.write(Data(bytes: &bytes, count: used))
            guard range.upperBound < stdin.endIndex else { break }
            result = stdin.getBytes(&bytes, maxLength: 1024, usedLength: &used, encoding: encoding, range: (range.upperBound ..< stdin.endIndex), remaining: &range)
        }

        try? pipeIn.fileHandleForWriting.close()
    }
    thread.start()
    return execute(exec: exec, args: args, stdin: pipeIn, stdout: &stdout, stderr: &stderr, encoding: encoding)
}

/*==============================================================================================================*/
/// Execute a program and capture it's output.
///
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdin: An instance of Pipe or FileHandle that will provide input to the program on the stdin channel.
///   - stdout: The string to receive the standard output.
///   - stderr: The string to receive the standard error.
///   - encoding: The encoding to used on the standard output and standard error.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdin: Any? = nil, stdout: inout String, stderr: inout String, encoding: String.Encoding = .utf8) -> Int {
    var _stdout:  Data = Data()
    var _stderr:  Data = Data()
    let exitCode: Int  = execute(exec: exec, args: args, stdin: stdin, stdout: &_stdout, stderr: &_stderr)
    stdout = (String(data: _stdout, encoding: encoding) ?? "")
    stderr = (String(data: _stderr, encoding: encoding) ?? "")
    return exitCode
}

/*==============================================================================================================*/
/// Execute a program and capture it's output. Anything written to stderr by the program is discarded unless
/// `discardStderr` is set to `false` in which case it is routed to the system's stderr channel.
///
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdin: An instance of Pipe or FileHandle that will provide input to the program on the stdin channel.
///   - stdout: The string to receive the standard output.
///   - encoding: The encoding to used on the standard output.
///   - discardStderr: If `true` (the default) then anything the program writes to stderr is discarded. If `false`
///                    then anything the program writes to stderr is sent to the system's stderr channel.
/// - Returns: The numeric exit status code returned from the executed program.
///
@inlinable public func execute(exec: String, args: [String], stdin: Any? = nil, stdout: inout String, encoding: String.Encoding = .utf8, discardStderr: Bool = true) -> Int {
    var _stdout:  Data = Data()
    var _stderr:  Data = Data()
    let exitCode: Int  = execute(exec: exec, args: args, stdin: stdin, stdout: &_stdout, stderr: &_stderr)
    stdout = (String(data: _stdout, encoding: encoding) ?? "")
    #if DEBUG
        FileHandle.standardError.write(_stderr)
    #else
        if !discardStderr { FileHandle.standardError.write(_stderr) }
    #endif
    return exitCode
}

/*==============================================================================================================*/
/// Execute a program. Anything written to stderr or stdout by the program is discarded unless `discardOutput` is
/// set to `false` in which case it is routed to the system's stderr and stdout channels.
///
/// - Parameters:
///   - exec: The program to execute.
///   - args: The command line arguments for the program.
///   - stdin: An instance of Pipe or FileHandle that will provide input to the program on the stdin channel.
///   - discardOutput: If `true` (the default) then anything the program writes to stderr or stdout is discarded.
///                    If `false` then anything the program writes to stderr or stdout is sent to the system's
///                    stderr and stdout channels.
/// - Returns: The numeric exit status code returned from the executed program.
///
public func execute(exec: String, args: [String], stdin: Any? = nil, discardOutput: Bool = true) -> Int {
    let proc: Process = Process()
    proc.executableURL = URL(fileURLWithPath: exec)
    proc.arguments = args
    proc.standardInput = stdin
    proc.standardError = (discardOutput ? FileHandle.nullDevice : FileHandle.standardError)
    proc.standardOutput = (discardOutput ? FileHandle.nullDevice : FileHandle.standardOutput)
    guard launchProcess(process: proc) else { return -1 }
    proc.waitUntilExit()
    return Int(proc.terminationStatus)
}

/*==============================================================================================================*/
/// Launch a process and return.
///
/// - Parameter process: The process to launch.
/// - Returns: `true` if successful.
///
@inlinable func launchProcess(process: Process) -> Bool {
    var error: Error? = nil
    return launchProcess(process: process, error: &error)
}

/*==============================================================================================================*/
/// Launch a process and return.
///
/// - Parameters:
///   - process: The process to launch.
///   - error: Receives any error.
/// - Returns: `true` if successful.
///
@inlinable func launchProcess(process: Process, error: inout Error?) -> Bool {
    do {
        try process.run()
        return true
    }
    catch let e {
        error = e
        #if DEBUG
            FileHandle.standardError.write(Data(e.localizedDescription.utf8))
        #endif
        return false
    }
}
