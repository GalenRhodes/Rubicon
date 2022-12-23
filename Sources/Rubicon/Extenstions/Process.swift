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
/*@f0*/
    public typealias ExecuteResults     = (exitCode: Int32, stdOut: String, stdErr: String)
    public typealias ExecuteDataResults = (exitCode: Int32, stdOut: Data, stdErr: Data)
    public typealias Source             = (UnsafeMutablePointer<UInt8>, Int) throws -> Int
    public typealias Target             = (UnsafePointer<UInt8>, Int) throws -> Void
    public typealias OnExit             = (Int32) -> Void
/*@f1*/
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
        let (process, inThread, outThread, errThread) = try _execute(url: url, args: args, env: env, stdIn: stdIn, stdOut: stdOut, stdErr: stdErr, onExit: nil)
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
    public class func execute(executableURL url: URL, arguments args: [String] = [], environment env: [String: String]? = nil, stdIn: Source?, stdOut: Target?, stdErr: Target?, onExit: @escaping OnExit) throws -> Process {
        try _execute(url: url, args: args, env: env, stdIn: stdIn, stdOut: stdOut, stdErr: stdErr, onExit: onExit).0
    }

    /*==========================================================================================================================================================================*/
    /// Executes the operating system `which` command to locate an executable in the default path.
    ///
    /// - Parameter name: The name of the executable.
    /// - Returns: The path on the file system to the executable or nil if it could not be found.
    /// - Throws: on O/S error.
    ///
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
    /// Executes a command within the operating system command line shell.
    ///
    /// - Parameters:
    ///   - shell: The shell program to execute. On Unix based systems this is `/bin/sh`. On Windows based systems this is `cmd.exe`.
    ///   - args: The arguments to execute in the shell.
    ///   - env: Environment variables.
    ///   - stdIn: Any data to provide on STDIN.
    /// - Returns: A tuple of type `ExecuteDataResults`.
    /// - Throws: If there is a problem executing the shell program.
    ///
    public class func osShell(shell: String? = nil, arguments args: [String], environment env: [String: String]? = nil, inputData stdIn: Data?) throws -> ExecuteDataResults {
        let r = getOsShellArguments(shell: shell, arguments: args)
        return try Process.execute(executableURL: URL(fileURLWithPath: r.shellExec), arguments: r.args, environment: env, inputData: stdIn)
    }

    /*==========================================================================================================================================================================*/
    /// Executes a command within the operating system command line shell.
    ///
    /// - Parameters:
    ///   - shell: The shell program to execute. On Unix based systems this is `/bin/sh`. On Windows based systems this is `cmd.exe`.
    ///   - args: The arguments to execute in the shell.
    ///   - env: Environment variables.
    ///   - stdIn: Any text to provide on STDIN.
    ///   - enc: The character encoding for the text provided on STDIN. Defaults to `UTF-8`.
    /// - Returns: A tuple of type `ExecuteDataResults`.
    /// - Throws: If there is a problem executing the shell program.
    ///
    public class func osShell(shell: String? = nil, arguments args: [String], environment env: [String: String]? = nil, inputString stdIn: String? = nil, encoding enc: String.Encoding = .utf8) throws -> ExecuteResults {
        let r = getOsShellArguments(shell: shell, arguments: args)
        return try Process.execute(executableURL: URL(fileURLWithPath: r.shellExec), arguments: r.args, environment: env, inputString: stdIn, encoding: enc)
    }

    /*==========================================================================================================================================================================*/
    /// Utility method used by `execute(executableURL:arguments:environment:stdIn:stdOut:stdErr:)` and `execute(executableURL:arguments:environment:stdIn:stdOut:stdErr:onExit:)`
    /// to execute the `Process`.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the executable.
    ///   - args: Command-line arguments.
    ///   - env: Environment variables.
    ///   - stdIn: Closure to provide data on `STDIN`.
    ///   - stdOut: Closure to accept data from `STDOUT`.
    ///   - stdErr: Closure to accept data from `STDERR`.
    ///   - onExit: Closure to be called on process completion.
    /// - Returns: A tuple containing the instance of `Process` and the background threads providing data to `STDIN` and accepting data from `STDOUT` and `STDERR`.
    /// - Throws: If there was an error executing the process.
    ///
    private class func _execute(url: URL, args: [String], env: [String: String]?, stdIn: Source?, stdOut: Target?, stdErr: Target?, onExit: OnExit?) throws -> (Process, ProcessWriteFromSourceThread?, ProcessReadToTargetThread?, ProcessReadToTargetThread?) {
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
        if let h = onExit { process.terminationHandler = { p in h(p.terminationStatus) } }

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
            "\"\(args.map({ $0.escapedForCommandLine }).joined(separator: "\" \""))\""
        #else
            args.map({ $0.escapedForCommandLine }).joined(separator: " ")
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
    private class func start(threads: VThread<Void>?...) {
        for t in threads { if let t = t { t.start() } }
    }

    /*==========================================================================================================================================================================*/
    private class func join(threads: VThread<Void>?...) throws {
        var error: Error? = nil
        for t in threads { if let t = t { do { try t.get() } catch let e { if error == nil { error = e } } } } /*@f0*/
        if let e = error { throw e } /*@f1*/
    }

    /*==========================================================================================================================================================================*/
    private class ProcessWriteFromSourceThread: ProcessThread {
        let source: Source

        init(_ source: @escaping Source) {
            self.source = source
            super.init()
        }

        override func main(isCancelled: () -> Bool) throws { try pipe.writeToPipe { isCancelled() ? 0 : try source($0, $1) } }
    }

    /*==========================================================================================================================================================================*/
    private class ProcessReadToTargetThread: ProcessThread {
        let target: Target

        init(_ target: @escaping Target) {
            self.target = target
            super.init()
        }

        override func main(isCancelled: () -> Bool) throws {
            try pipe.readFromPipe { buffer, length in
                guard !isCancelled() else { return true }
                try target(buffer, length)
                return false
            }
        }
    }

    /*==========================================================================================================================================================================*/
    private class ProcessThread: VThread<Void> {
        let pipe: Pipe = Pipe()

        init() { super.init(qualityOfService: .background) }
    }
}
