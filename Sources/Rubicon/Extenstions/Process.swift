// ===========================================================================
//     PROJECT: Rubicon
//    FILENAME: Process.swift
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
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(WinSDK)
    import WinSDK
#endif

/*==========================================================================================================================================================================*/
public enum ProcessErrors: Error {
    case ExecutableNotFound
}

/*==========================================================================================================================================================================*/
extension Process {
    @usableFromInline static let BufferSize: Int = 1024
/*@f:0*/
    public typealias ExecuteResults     = (exitCode: Int32, stdOut: String, stdErr: String)
    public typealias ExecuteDataResults = (exitCode: Int32, stdOut: Data, stdErr: Data)
    public typealias Source             = (UnsafeMutablePointer<UInt8>, Int) throws -> Int
    public typealias Target             = (UnsafePointer<UInt8>, Int) throws -> Void
/*@f:1*/
    /*==========================================================================================================================================================================*/
    /// Executes a given executable in a separate process and returns the data returned on STDOUT and STDERR during the execution of the process. In this case, instead of
    /// passing an absolute URL you pass just the name of the executable and the Unix/Linux command `which` (`where` on Windows) is used to locate it.
    ///
    /// - Parameters:
    ///   - exe: The name of the executable (binary) that will be found using the `which` shell command (`where` on Windows).
    ///   - args: The command line arguments to be passed to the process.
    ///   - env: Environment variables to pass to the process.
    ///   - stdIn: The string of data to pass to the process on STDIN. If no input data is needed then pass `nil`. (Optional)
    ///   - end: The character encoding to use to convert the input and output.
    /// - Returns: A tuple with the exit code, STDOUT, and STDERR - (exitCode: Int32, stdOut: String, stdErr: String).
    /// - Throws: If `Process.run()` throws an exception or `ProcessErrors.ExecutableNotFound` if the executable could not be found.
    ///
    @inlinable public class func execute(whichExecutable exe: String, arguments args: [String], environment env: [String: String]? = nil, inputString stdIn: String?, encoding end: String.Encoding = .utf8) throws -> ExecuteResults {
        guard let exeUrlStr = try osWhich(executable: exe) else { throw ProcessErrors.ExecutableNotFound }
        return try execute(executableURL: URL(fileURLWithPath: exeUrlStr), arguments: args, environment: env, inputString: stdIn, encoding: end)
    }

    /*==========================================================================================================================================================================*/
    /// Executes a given executable in a separate process and returns the data returned on STDOUT and STDERR during the execution of the process. In this case, instead of
    /// passing an absolute URL you pass just the name of the executable and the Unix/Linux command `which` (`where` on Windows) is used to locate it.
    ///
    /// - Parameters:
    ///   - exe: The name of the executable (binary) that will be found using the `which` shell command (`where` on Windows).
    ///   - args: The command line arguments to be passed to the process.
    ///   - env: Environment variables to pass to the process. (Optional)
    ///   - stdIn: The data to pass to the process on STDIN. If no input data is needed then pass `nil`. (Optional)
    /// - Returns: A tuple with the exit code, STDOUT, and STDERR - (exitCode: Int32, stdOut: Data, stdErr: Data).
    /// - Throws: If `Process.run()` throws an exception or `ProcessErrors.ExecutableNotFound` if the executable could not be found.
    ///
    @inlinable public class func execute(whichExecutable exe: String, arguments args: [String], environment env: [String: String]? = nil, inputData stdIn: Data?) throws -> ExecuteDataResults {
        guard let exeUrlStr = try osWhich(executable: exe) else { throw ProcessErrors.ExecutableNotFound }
        return try execute(executableURL: URL(fileURLWithPath: exeUrlStr), arguments: args, environment: env, inputData: stdIn)
    }

    /*==========================================================================================================================================================================*/
    /// Executes a given executable in a separate process and returns the data returned on STDOUT and STDERR during the execution of the process.
    ///
    /// - Parameters:
    ///   - url: The file URL to the executable (binary).
    ///   - args: The command line arguments to be passed to the process.
    ///   - env: Environment variables to pass to the process.
    ///   - stdIn: The string of data to pass to the process on STDIN. If no input data is needed then pass `nil`. (Optional)
    ///   - enc: The character encoding to use to convert the input and output.
    /// - Returns: A tuple with the exit code, STDOUT, and STDERR - (exitCode: Int32, stdOut: String, stdErr: String).
    /// - Throws: If `Process.run()` throws an exception.
    ///
    @inlinable public class func execute(executableURL url: URL, arguments args: [String], environment env: [String: String]? = nil, inputString stdIn: String?, encoding enc: String.Encoding = .utf8) throws -> ExecuteResults {
        let r = try execute(executableURL: url, arguments: args, inputData: stdIn?.data(using: enc))
        return (r.exitCode, r.stdOut.asString(encoding: enc) ?? "", r.stdErr.asString(encoding: enc) ?? "")
    }

    /*==========================================================================================================================================================================*/
    /// Executes a given executable in a separate process and returns the data returned on STDOUT and STDERR during the execution of the process.
    ///
    /// - Parameters:
    ///   - url: The file URL to the executable (binary).
    ///   - args: The command line arguments to be passed to the process.
    ///   - env: Environment variables to pass to the process. (Optional)
    ///   - stdIn: The data to pass to the process on STDIN. If no input data is needed then pass `nil`. (Optional)
    /// - Returns: A tuple with the exit code, STDOUT, and STDERR - (exitCode: Int32, stdOut: Data, stdErr: Data).
    /// - Throws: If `Process.run()` throws an exception.
    ///
    public class func execute(executableURL url: URL, arguments args: [String], environment env: [String: String]? = nil, inputData stdIn: Data?) throws -> ExecuteDataResults {
        var out: Data = Data()
        var err: Data = Data()
        let ts = try execute(executableURL: url, arguments: args, environment: env, stdIn: getStdInThread(stdIn: stdIn), stdOut: { out.append($0, count: $1) }, stdErr: { err.append($0, count: $1) })
        return (ts, out, err)
    }

    /*==========================================================================================================================================================================*/
    /// Executes a given executable in a separate process and returns the exit code.
    ///
    /// - Parameters:
    ///   - url: The file URL to the executable (binary).
    ///   - args: The command line arguments to be passed to the process.
    ///   - env: Environment variables to pass to the process. (Optional)
    ///   - stdIn: A closure to provide data to the STDIN of the process.
    ///   - stdOut: A closure to collect the data from STDOUT of the process.
    ///   - stdErr: A closure to collect the data from STDERR of the process.
    /// - Returns: A tuple with the exit code, STDOUT, and STDERR - (exitCode: Int32, stdOut: Data, stdErr: Data).
    /// - Throws: If `Process.run()` or any of the closures throw an exception.
    ///
    public class func execute(executableURL url: URL, arguments args: [String] = [], environment env: [String: String]? = nil, stdIn: Source?, stdOut: Target?, stdErr: Target?) throws -> Int32 {
        let (process, inThread, outThread, errThread) = try _execute(url: url, args: args, env: env, stdIn: stdIn, stdOut: stdOut, stdErr: stdErr)
        process.waitUntilExit()
        try join(threads: outThread, errThread, inThread)
        return process.terminationStatus
    }

    /*==========================================================================================================================================================================*/
    /// Executes a given executable in a separate process and returns.
    ///
    /// - Parameters:
    ///   - url: The file URL to the executable (binary).
    ///   - args: The command line arguments to be passed to the process.
    ///   - env: Environment variables to pass to the process. (Optional)
    ///   - stdIn: A closure to provide data to the STDIN of the process.
    ///   - stdOut: A closure to collect the data from STDOUT of the process.
    ///   - stdErr: A closure to collect the data from STDERR of the process.
    ///   - onExit: A closure which will be called when the process has finished executing. It takes a single parameter which, when called, will be the processes' termination status.
    /// - Throws: If `Process.run()` throws an error.
    ///
    public class func execute(executableURL url: URL, arguments args: [String] = [], environment env: [String: String]? = nil, stdIn: Source?, stdOut: Target?, stdErr: Target?, onExit: @escaping (Int32) -> Void) throws {
        let (process, inThread, outThread, errThread) = try _execute(url: url, args: args, env: env, stdIn: stdIn, stdOut: stdOut, stdErr: stdErr)
        let waitThread = Thread {
            process.waitUntilExit()
            try? join(threads: outThread, errThread, inThread)
            onExit(process.terminationStatus)
        }
        waitThread.qualityOfService = .background
        waitThread.start()
    }

    /*==========================================================================================================================================================================*/
    public class func osWhich(executable name: String) throws -> String? {
        #if os(Windows)
            let r = try osShell(arguments: [ "where", argString(arguments: [ name ]) ])
            guard r.exitCode == 0 else { return nil }
            let a = r.stdOut.trimmed.split(regex: "\\r\\n|\\r|\\n")
            return ((a.count > 0) ? a[0] : nil)
        #else
            let r = try osShell(arguments: [ "which", argString(arguments: [ name ]) ])
            return ((r.exitCode == 0) ? r.stdOut.trimmed : nil)
        #endif
    }

    /*==========================================================================================================================================================================*/
    public class func osShell(shell: String? = nil, arguments args: [String], environment env: [String: String]? = nil, inputData stdIn: Data?) throws -> ExecuteDataResults {
        let r = getOsShellArguments(shell: shell, arguments: args)
        return try Process.execute(executableURL: URL(fileURLWithPath: r.shellExec), arguments: r.args, environment: env, inputData: stdIn)
    }

    /*==========================================================================================================================================================================*/
    public class func osShell(shell: String? = nil, arguments args: [String], environment env: [String: String]? = nil, inputString stdIn: String? = nil, encoding enc: String.Encoding = .utf8) throws -> ExecuteResults {
        let r = getOsShellArguments(shell: shell, arguments: args)
        return try Process.execute(executableURL: URL(fileURLWithPath: r.shellExec), arguments: r.args, environment: env, inputString: stdIn, encoding: enc)
    }

    /*==========================================================================================================================================================================*/
    private class func _execute(url: URL, args: [String], env: [String: String]?, stdIn: Source?, stdOut: Target?, stdErr: Target?) throws -> (Process, ProcessWriteFromSourceThread?, ProcessReadToTargetThread?, ProcessReadToTargetThread?) {
        let outThread: ProcessReadToTargetThread?    = ((stdOut == nil) ? nil : ProcessReadToTargetThread(stdOut!))
        let errThread: ProcessReadToTargetThread?    = ((stdErr == nil) ? nil : ProcessReadToTargetThread(stdErr!))
        let inThread:  ProcessWriteFromSourceThread? = ((stdIn == nil) ? nil : ProcessWriteFromSourceThread(stdIn!))
        let process:   Process                       = Process()

        process.arguments = args
        process.executableURL = url
        if let t = outThread { process.standardOutput = t.pipe }
        if let t = errThread { process.standardError = t.pipe }
        if let t = inThread { process.standardInput = t.pipe }
        if let e = env, e.count > 0 { process.environment = e }

        try process.run()
        start(threads: outThread, errThread, inThread)
        return (process, inThread, outThread, errThread)
    }

    /*==========================================================================================================================================================================*/
    private class func getStdInThread(stdIn: Data?) -> Source? {
        guard let stdIn = stdIn else { return nil }
        var cc = 0
        return {
            let usableBytes = min($1, (stdIn.count - cc))
            if usableBytes > 0 {
                stdIn.copyBytes(to: $0, from: (cc ..< (cc + usableBytes)))
                cc += usableBytes
            }
            return usableBytes
        }
    }

    /*==========================================================================================================================================================================*/
    private class func argString(arguments args: [String]) -> String {
        #if os(Windows)
            "\"\(args.map({ $0.replacing("\"", with: "\\\"") }).joined(separator: "\" \""))\""
        #else
            args.map({ $0.replacing(" ", with: "\\ ") }).joined(separator: " ")
        #endif
    }

    /*==========================================================================================================================================================================*/
    private class func getOsShellArguments(shell: String?, arguments: [String]) -> (shellExec: String, args: [String]) {
        #if os(Windows)
            return ((shell ?? "cmd.exe"), ((arguments.count > 0) ? [ "/c", argString(arguments: arguments) ] : [ "/c" ]))
        #else
            return ((shell ?? "/bin/sh"), ((arguments.count > 0) ? [ "-c", argString(arguments: arguments) ] : [ "-c" ]))
        #endif
    }

    /*==========================================================================================================================================================================*/
    private class func start(threads: JoinableThread<Void>?...) {
        for t in threads { if let t = t { t.start() } }
    }

    /*==========================================================================================================================================================================*/
    private class func join(threads: JoinableThread<Void>?...) throws {
        var error: Error? = nil
        for t in threads { if let t = t { do { try t.get() }
        catch let e { if error == nil { error = e } } } }
        if let e = error { throw e }
    }

    /*==========================================================================================================================================================================*/
    private class ProcessWriteFromSourceThread: JoinableThread<Void> {
        let pipe:   Pipe = Pipe()
        let source: Source

        init(_ source: @escaping Source) {
            self.source = source
            super.init()
        }

        override func main(isCancelled: () -> Bool) throws {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: BufferSize)
            defer { buffer.deallocate() }
            while !isCancelled() {
                var cc = try source(buffer, BufferSize)
                guard cc > 0 else { break }
                try pipe.fileHandleForWriting.write(contentsOf: UnsafeBufferPointer<UInt8>(start: buffer, count: cc))
                cc = try source(buffer, BufferSize)
            }
        }
    }

    /*==========================================================================================================================================================================*/
    private class ProcessReadToTargetThread: JoinableThread<Void> {
        let pipe:   Pipe = Pipe()
        let target: Target

        init(_ target: @escaping Target) {
            self.target = target
            super.init()
        }

        override func main(isCancelled: () -> Bool) throws {
            while !isCancelled() {
                guard let d = try pipe.fileHandleForReading.read(upToCount: BufferSize), d.count > 0 else { break }
                try d.withUnsafeBytes { (b: UnsafeRawBufferPointer) in try b.withMemoryRebound(to: UInt8.self) { try $0.withBaseAddress { try target($0, $1) } } }
            }
        }
    }
}
