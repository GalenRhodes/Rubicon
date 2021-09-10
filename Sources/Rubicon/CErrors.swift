/************************************************************************//**
 *     PROJECT: Rubicon
 *    FILENAME: CErrors.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/30/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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
#if os(Windows)
    import WinSDK
#elseif canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

/*==============================================================================================================*/
/// Cover function for the C standard library function `strerror(int)`. Returns a Swift
/// <code>[String](https://developer.apple.com/documentation/swift/string/)</code>.
///
/// - Parameter code: the OS error code.
/// - Returns: A Swift <code>[String](https://developer.apple.com/documentation/swift/string/)</code> with the OS
///            error message.
///
@inlinable public func StrError(_ code: Int32) -> String {
    var bs     = 64
    var buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bs)

    defer { buffer.deallocate() }

    var r = strerror_r(code, buffer, bs)
    while r != 0 {
        guard (bs < 1_018_576) && ((r == ERANGE) || (r == -1 && errno == ERANGE)) else { return "Unknown Error: \(code)" }
        bs *= 2
        buffer.deallocate()
        buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bs)
        r = strerror_r(code, buffer, bs)
    }

    return String(cString: buffer)
}

/*==============================================================================================================*/
/// Test the result of a C standard library function call to see if an error has occurred. If so then throw a
/// fatal error with the message of the error. Usually any
/// non-<code>[zero](https://en.wikipedia.org/wiki/0)</code> value is considered an error. In some cases though a
/// non-<code>[zero](https://en.wikipedia.org/wiki/0)</code> error is just informational and in those cases you
/// can tell this function to ignore those as well.
///
/// For example, in a call to `pthread_mutex_trylock(...)`, an return code of `EBUSY` simply means that the lock
/// is already held by another thread while a code of `EINVAL` means that the mutex passed to the function was not
/// properly initialized. So you could call this function like so:
///
/// <pre>
///     let locked: Bool = (testOSFatalError(pthread_mutex_trylock(mutex), EBUSY) == 0)
/// </pre>
///
/// In this case the constant `locked` will be `true` if the thread successfully obtained ownership of the lock or
/// `false` if another thread still owns the lock. If the return code was any other value beside 0
/// (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) or EBUSY then a fatal error occurs.
///
/// - Parameters:
///   - results: The results of the call.
///   - otherOk: Other values besides 0 (<code>[zero](https://en.wikipedia.org/wiki/0)</code>) that should be
///              considered OK and not cause a fatal error.
/// - Returns: The value of results.
///
@inlinable @discardableResult public func testOSFatalError(_ results: Int32, _ otherOk: Int32...) -> Int32 {
    if results == 0 { return results }
    for other: Int32 in otherOk { if results == other { return results } }
    fatalError(StrError(results))
}

public struct CErrors: Error, CustomStringConvertible, Hashable {
    public let code:        Int32
    public let description: String

    public init(code: Int32, description: String) {
        self.code = code
        self.description = description
    }

    public init(code: Int32) {
        self.init(code: code, description: StrError(code))
    }

    @inlinable public func hash(into hasher: inout Hasher) { hasher.combine(code) }

    @inlinable public static func == (lhs: CErrors, rhs: CErrors) -> Bool { lhs.code == rhs.code }

    public static let UNKNOWN: CErrors = CErrors(code: -1, description: "Uknown Error")

    #if (os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
        // MARK: Apple OS
        /*======================================================================================================*/
        /// Operation not permitted.
        ///
        public static let EPERM:           CErrors = CErrors(code: POSIXErrorCode.EPERM.rawValue)
        /*======================================================================================================*/
        /// No such file or directory.
        ///
        public static let ENOENT:          CErrors = CErrors(code: POSIXErrorCode.ENOENT.rawValue)
        /*======================================================================================================*/
        /// No such process.
        ///
        public static let ESRCH:           CErrors = CErrors(code: POSIXErrorCode.ESRCH.rawValue)
        /*======================================================================================================*/
        /// Interrupted system call.
        ///
        public static let EINTR:           CErrors = CErrors(code: POSIXErrorCode.EINTR.rawValue)
        /*======================================================================================================*/
        /// Input/output error.
        ///
        public static let EIO:             CErrors = CErrors(code: POSIXErrorCode.EIO.rawValue)
        /*======================================================================================================*/
        /// Device not configured.
        ///
        public static let ENXIO:           CErrors = CErrors(code: POSIXErrorCode.ENXIO.rawValue)
        /*======================================================================================================*/
        /// Argument list too long.
        ///
        public static let E2BIG:           CErrors = CErrors(code: POSIXErrorCode.E2BIG.rawValue)
        /*======================================================================================================*/
        /// Exec format error.
        ///
        public static let ENOEXEC:         CErrors = CErrors(code: POSIXErrorCode.ENOEXEC.rawValue)
        /*======================================================================================================*/
        /// Bad file descriptor.
        ///
        public static let EBADF:           CErrors = CErrors(code: POSIXErrorCode.EBADF.rawValue)
        /*======================================================================================================*/
        /// No child processes.
        ///
        public static let ECHILD:          CErrors = CErrors(code: POSIXErrorCode.ECHILD.rawValue)
        /*======================================================================================================*/
        /// Resource deadlock avoided.
        ///
        public static let EDEADLK:         CErrors = CErrors(code: POSIXErrorCode.EDEADLK.rawValue)
        /*======================================================================================================*/
        /// Cannot allocate memory.
        ///
        public static let ENOMEM:          CErrors = CErrors(code: POSIXErrorCode.ENOMEM.rawValue)
        /*======================================================================================================*/
        /// Permission denied.
        ///
        public static let EACCES:          CErrors = CErrors(code: POSIXErrorCode.EACCES.rawValue)
        /*======================================================================================================*/
        /// Bad address.
        ///
        public static let EFAULT:          CErrors = CErrors(code: POSIXErrorCode.EFAULT.rawValue)
        /*======================================================================================================*/
        /// Block device required.
        ///
        public static let ENOTBLK:         CErrors = CErrors(code: POSIXErrorCode.ENOTBLK.rawValue)
        /*======================================================================================================*/
        /// Device / Resource busy.
        ///
        public static let EBUSY:           CErrors = CErrors(code: POSIXErrorCode.EBUSY.rawValue)
        /*======================================================================================================*/
        /// File exists.
        ///
        public static let EEXIST:          CErrors = CErrors(code: POSIXErrorCode.EEXIST.rawValue)
        /*======================================================================================================*/
        /// Cross-device link.
        ///
        public static let EXDEV:           CErrors = CErrors(code: POSIXErrorCode.EXDEV.rawValue)
        /*======================================================================================================*/
        /// Operation not supported by device.
        ///
        public static let ENODEV:          CErrors = CErrors(code: POSIXErrorCode.ENODEV.rawValue)
        /*======================================================================================================*/
        /// Not a directory.
        ///
        public static let ENOTDIR:         CErrors = CErrors(code: POSIXErrorCode.ENOTDIR.rawValue)
        /*======================================================================================================*/
        /// Is a directory.
        ///
        public static let EISDIR:          CErrors = CErrors(code: POSIXErrorCode.EISDIR.rawValue)
        /*======================================================================================================*/
        /// Invalid argument.
        ///
        public static let EINVAL:          CErrors = CErrors(code: POSIXErrorCode.EINVAL.rawValue)
        /*======================================================================================================*/
        /// Too many open files in system.
        ///
        public static let ENFILE:          CErrors = CErrors(code: POSIXErrorCode.ENFILE.rawValue)
        /*======================================================================================================*/
        /// Too many open files.
        ///
        public static let EMFILE:          CErrors = CErrors(code: POSIXErrorCode.EMFILE.rawValue)
        /*======================================================================================================*/
        /// Inappropriate ioctl for device.
        ///
        public static let ENOTTY:          CErrors = CErrors(code: POSIXErrorCode.ENOTTY.rawValue)
        /*======================================================================================================*/
        /// Text file busy.
        ///
        public static let ETXTBSY:         CErrors = CErrors(code: POSIXErrorCode.ETXTBSY.rawValue)
        /*======================================================================================================*/
        /// File too large.
        ///
        public static let EFBIG:           CErrors = CErrors(code: POSIXErrorCode.EFBIG.rawValue)
        /*======================================================================================================*/
        /// No space left on device.
        ///
        public static let ENOSPC:          CErrors = CErrors(code: POSIXErrorCode.ENOSPC.rawValue)
        /*======================================================================================================*/
        /// Illegal seek.
        ///
        public static let ESPIPE:          CErrors = CErrors(code: POSIXErrorCode.ESPIPE.rawValue)
        /*======================================================================================================*/
        /// Read-only file system.
        ///
        public static let EROFS:           CErrors = CErrors(code: POSIXErrorCode.EROFS.rawValue)
        /*======================================================================================================*/
        /// Too many links.
        ///
        public static let EMLINK:          CErrors = CErrors(code: POSIXErrorCode.EMLINK.rawValue)
        /*======================================================================================================*/
        /// Broken pipe.
        ///
        public static let EPIPE:           CErrors = CErrors(code: POSIXErrorCode.EPIPE.rawValue)
        /*======================================================================================================*/
        /// Numerical argument out of domain.
        ///
        public static let EDOM:            CErrors = CErrors(code: POSIXErrorCode.EDOM.rawValue)
        /*======================================================================================================*/
        /// Result too large.
        ///
        public static let ERANGE:          CErrors = CErrors(code: POSIXErrorCode.ERANGE.rawValue)
        /*======================================================================================================*/
        /// Resource temporarily unavailable.
        ///
        public static let EAGAIN:          CErrors = CErrors(code: POSIXErrorCode.EAGAIN.rawValue)
        /*======================================================================================================*/
        /// Operation would block.
        ///
        public static var EWOULDBLOCK:     CErrors = .EAGAIN
        /*======================================================================================================*/
        /// Operation now in progress.
        ///
        public static let EINPROGRESS:     CErrors = CErrors(code: POSIXErrorCode.EINPROGRESS.rawValue)
        /*======================================================================================================*/
        /// Operation already in progress.
        ///
        public static let EALREADY:        CErrors = CErrors(code: POSIXErrorCode.EALREADY.rawValue)
        /*======================================================================================================*/
        /// Socket operation on non-socket.
        ///
        public static let ENOTSOCK:        CErrors = CErrors(code: POSIXErrorCode.ENOTSOCK.rawValue)
        /*======================================================================================================*/
        /// Destination address required.
        ///
        public static let EDESTADDRREQ:    CErrors = CErrors(code: POSIXErrorCode.EDESTADDRREQ.rawValue)
        /*======================================================================================================*/
        /// Message too long.
        ///
        public static let EMSGSIZE:        CErrors = CErrors(code: POSIXErrorCode.EMSGSIZE.rawValue)
        /*======================================================================================================*/
        /// Protocol wrong type for socket.
        ///
        public static let EPROTOTYPE:      CErrors = CErrors(code: POSIXErrorCode.EPROTOTYPE.rawValue)
        /*======================================================================================================*/
        /// Protocol not available.
        ///
        public static let ENOPROTOOPT:     CErrors = CErrors(code: POSIXErrorCode.ENOPROTOOPT.rawValue)
        /*======================================================================================================*/
        /// Protocol not supported.
        ///
        public static let EPROTONOSUPPORT: CErrors = CErrors(code: POSIXErrorCode.EPROTONOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Socket type not supported.
        ///
        public static let ESOCKTNOSUPPORT: CErrors = CErrors(code: POSIXErrorCode.ESOCKTNOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Operation not supported.
        ///
        public static let ENOTSUP:         CErrors = CErrors(code: POSIXErrorCode.ENOTSUP.rawValue)
        /*======================================================================================================*/
        /// Protocol family not supported.
        ///
        public static let EPFNOSUPPORT:    CErrors = CErrors(code: POSIXErrorCode.EPFNOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Address family not supported by protocol family.
        ///
        public static let EAFNOSUPPORT:    CErrors = CErrors(code: POSIXErrorCode.EAFNOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Address already in use.
        ///
        public static let EADDRINUSE:      CErrors = CErrors(code: POSIXErrorCode.EADDRINUSE.rawValue)
        /*======================================================================================================*/
        /// Can't assign requested address.
        ///
        public static let EADDRNOTAVAIL:   CErrors = CErrors(code: POSIXErrorCode.EADDRNOTAVAIL.rawValue)
        /*======================================================================================================*/
        /// Network is down.
        ///
        public static let ENETDOWN:        CErrors = CErrors(code: POSIXErrorCode.ENETDOWN.rawValue)
        /*======================================================================================================*/
        /// Network is unreachable.
        ///
        public static let ENETUNREACH:     CErrors = CErrors(code: POSIXErrorCode.ENETUNREACH.rawValue)
        /*======================================================================================================*/
        /// Network dropped connection on reset.
        ///
        public static let ENETRESET:       CErrors = CErrors(code: POSIXErrorCode.ENETRESET.rawValue)
        /*======================================================================================================*/
        /// Software caused connection abort.
        ///
        public static let ECONNABORTED:    CErrors = CErrors(code: POSIXErrorCode.ECONNABORTED.rawValue)
        /*======================================================================================================*/
        /// Connection reset by peer.
        ///
        public static let ECONNRESET:      CErrors = CErrors(code: POSIXErrorCode.ECONNRESET.rawValue)
        /*======================================================================================================*/
        /// No buffer space available.
        ///
        public static let ENOBUFS:         CErrors = CErrors(code: POSIXErrorCode.ENOBUFS.rawValue)
        /*======================================================================================================*/
        /// Socket is already connected.
        ///
        public static let EISCONN:         CErrors = CErrors(code: POSIXErrorCode.EISCONN.rawValue)
        /*======================================================================================================*/
        /// Socket is not connected.
        ///
        public static let ENOTCONN:        CErrors = CErrors(code: POSIXErrorCode.ENOTCONN.rawValue)
        /*======================================================================================================*/
        /// Can't send after socket shutdown.
        ///
        public static let ESHUTDOWN:       CErrors = CErrors(code: POSIXErrorCode.ESHUTDOWN.rawValue)
        /*======================================================================================================*/
        /// Too many references: can't splice.
        ///
        public static let ETOOMANYREFS:    CErrors = CErrors(code: POSIXErrorCode.ETOOMANYREFS.rawValue)
        /*======================================================================================================*/
        /// Operation timed out.
        ///
        public static let ETIMEDOUT:       CErrors = CErrors(code: POSIXErrorCode.ETIMEDOUT.rawValue)
        /*======================================================================================================*/
        /// Connection refused.
        ///
        public static let ECONNREFUSED:    CErrors = CErrors(code: POSIXErrorCode.ECONNREFUSED.rawValue)
        /*======================================================================================================*/
        /// Too many levels of symbolic links.
        ///
        public static let ELOOP:           CErrors = CErrors(code: POSIXErrorCode.ELOOP.rawValue)
        /*======================================================================================================*/
        /// File name too long.
        ///
        public static let ENAMETOOLONG:    CErrors = CErrors(code: POSIXErrorCode.ENAMETOOLONG.rawValue)
        /*======================================================================================================*/
        /// Host is down.
        ///
        public static let EHOSTDOWN:       CErrors = CErrors(code: POSIXErrorCode.EHOSTDOWN.rawValue)
        /*======================================================================================================*/
        /// No route to host.
        ///
        public static let EHOSTUNREACH:    CErrors = CErrors(code: POSIXErrorCode.EHOSTUNREACH.rawValue)
        /*======================================================================================================*/
        /// Directory not empty.
        ///
        public static let ENOTEMPTY:       CErrors = CErrors(code: POSIXErrorCode.ENOTEMPTY.rawValue)
        /*======================================================================================================*/
        /// Too many processes.
        ///
        public static let EPROCLIM:        CErrors = CErrors(code: POSIXErrorCode.EPROCLIM.rawValue)
        /*======================================================================================================*/
        /// Too many users.
        ///
        public static let EUSERS:          CErrors = CErrors(code: POSIXErrorCode.EUSERS.rawValue)
        /*======================================================================================================*/
        /// Disc quota exceeded.
        ///
        public static let EDQUOT:          CErrors = CErrors(code: POSIXErrorCode.EDQUOT.rawValue)
        /*======================================================================================================*/
        /// Stale NFS file handle.
        ///
        public static let ESTALE:          CErrors = CErrors(code: POSIXErrorCode.ESTALE.rawValue)
        /*======================================================================================================*/
        /// Too many levels of remote in path.
        ///
        public static let EREMOTE:         CErrors = CErrors(code: POSIXErrorCode.EREMOTE.rawValue)
        /*======================================================================================================*/
        /// RPC struct is bad.
        ///
        public static let EBADRPC:         CErrors = CErrors(code: POSIXErrorCode.EBADRPC.rawValue)
        /*======================================================================================================*/
        /// RPC version wrong.
        ///
        public static let ERPCMISMATCH:    CErrors = CErrors(code: POSIXErrorCode.ERPCMISMATCH.rawValue)
        /*======================================================================================================*/
        /// RPC prog. not avail.
        ///
        public static let EPROGUNAVAIL:    CErrors = CErrors(code: POSIXErrorCode.EPROGUNAVAIL.rawValue)
        /*======================================================================================================*/
        /// Program version wrong.
        ///
        public static let EPROGMISMATCH:   CErrors = CErrors(code: POSIXErrorCode.EPROGMISMATCH.rawValue)
        /*======================================================================================================*/
        /// Bad procedure for program.
        ///
        public static let EPROCUNAVAIL:    CErrors = CErrors(code: POSIXErrorCode.EPROCUNAVAIL.rawValue)
        /*======================================================================================================*/
        /// No locks available.
        ///
        public static let ENOLCK:          CErrors = CErrors(code: POSIXErrorCode.ENOLCK.rawValue)
        /*======================================================================================================*/
        /// Function not implemented.
        ///
        public static let ENOSYS:          CErrors = CErrors(code: POSIXErrorCode.ENOSYS.rawValue)
        /*======================================================================================================*/
        /// Inappropriate file type or format.
        ///
        public static let EFTYPE:          CErrors = CErrors(code: POSIXErrorCode.EFTYPE.rawValue)
        /*======================================================================================================*/
        /// Authentication error.
        ///
        public static let EAUTH:           CErrors = CErrors(code: POSIXErrorCode.EAUTH.rawValue)
        /*======================================================================================================*/
        /// Need authenticator.
        ///
        public static let ENEEDAUTH:       CErrors = CErrors(code: POSIXErrorCode.ENEEDAUTH.rawValue)
        /*======================================================================================================*/
        /// Device power is off.
        ///
        public static let EPWROFF:         CErrors = CErrors(code: POSIXErrorCode.EPWROFF.rawValue)
        /*======================================================================================================*/
        /// Device error, e.g. paper out.
        ///
        public static let EDEVERR:         CErrors = CErrors(code: POSIXErrorCode.EDEVERR.rawValue)
        /*======================================================================================================*/
        /// Value too large to be stored in data type.
        ///
        public static let EOVERFLOW:       CErrors = CErrors(code: POSIXErrorCode.EOVERFLOW.rawValue)
        /*======================================================================================================*/
        /// Bad executable.
        ///
        public static let EBADEXEC:        CErrors = CErrors(code: POSIXErrorCode.EBADEXEC.rawValue)
        /*======================================================================================================*/
        /// Bad CPU type in executable.
        ///
        public static let EBADARCH:        CErrors = CErrors(code: POSIXErrorCode.EBADARCH.rawValue)
        /*======================================================================================================*/
        /// Shared library version mismatch.
        ///
        public static let ESHLIBVERS:      CErrors = CErrors(code: POSIXErrorCode.ESHLIBVERS.rawValue)
        /*======================================================================================================*/
        /// Malformed Macho file.
        ///
        public static let EBADMACHO:       CErrors = CErrors(code: POSIXErrorCode.EBADMACHO.rawValue)
        /*======================================================================================================*/
        /// Operation canceled.
        ///
        public static let ECANCELED:       CErrors = CErrors(code: POSIXErrorCode.ECANCELED.rawValue)
        /*======================================================================================================*/
        /// Identifier removed.
        ///
        public static let EIDRM:           CErrors = CErrors(code: POSIXErrorCode.EIDRM.rawValue)
        /*======================================================================================================*/
        /// No message of desired type.
        ///
        public static let ENOMSG:          CErrors = CErrors(code: POSIXErrorCode.ENOMSG.rawValue)
        /*======================================================================================================*/
        /// Illegal byte sequence.
        ///
        public static let EILSEQ:          CErrors = CErrors(code: POSIXErrorCode.EILSEQ.rawValue)
        /*======================================================================================================*/
        /// Attribute not found.
        ///
        public static let ENOATTR:         CErrors = CErrors(code: POSIXErrorCode.ENOATTR.rawValue)
        /*======================================================================================================*/
        /// Bad message.
        ///
        public static let EBADMSG:         CErrors = CErrors(code: POSIXErrorCode.EBADMSG.rawValue)
        /*======================================================================================================*/
        /// Reserved.
        ///
        public static let EMULTIHOP:       CErrors = CErrors(code: POSIXErrorCode.EMULTIHOP.rawValue)
        /*======================================================================================================*/
        /// No message available on STREAM.
        ///
        public static let ENODATA:         CErrors = CErrors(code: POSIXErrorCode.ENODATA.rawValue)
        /*======================================================================================================*/
        /// Reserved.
        ///
        public static let ENOLINK:         CErrors = CErrors(code: POSIXErrorCode.ENOLINK.rawValue)
        /*======================================================================================================*/
        /// No STREAM resources.
        ///
        public static let ENOSR:           CErrors = CErrors(code: POSIXErrorCode.ENOSR.rawValue)
        /*======================================================================================================*/
        /// Not a STREAM.
        ///
        public static let ENOSTR:          CErrors = CErrors(code: POSIXErrorCode.ENOSTR.rawValue)
        /*======================================================================================================*/
        /// Protocol error.
        ///
        public static let EPROTO:          CErrors = CErrors(code: POSIXErrorCode.EPROTO.rawValue)
        /*======================================================================================================*/
        /// STREAM ioctl timeout.
        ///
        public static let ETIME:           CErrors = CErrors(code: POSIXErrorCode.ETIME.rawValue)
        /*======================================================================================================*/
        /// No such policy registered.
        ///
        public static let ENOPOLICY:       CErrors = CErrors(code: POSIXErrorCode.ENOPOLICY.rawValue)
        /*======================================================================================================*/
        /// State not recoverable.
        ///
        public static let ENOTRECOVERABLE: CErrors = CErrors(code: POSIXErrorCode.ENOTRECOVERABLE.rawValue)
        /*======================================================================================================*/
        /// Previous owner died.
        ///
        public static let EOWNERDEAD:      CErrors = CErrors(code: POSIXErrorCode.EOWNERDEAD.rawValue)
        /*======================================================================================================*/
        /// Interface output queue is full.
        ///
        public static let EQFULL:          CErrors = CErrors(code: POSIXErrorCode.EQFULL.rawValue)
        /*======================================================================================================*/
        /// Must be equal largest errno.
        ///
        public static var ELAST:           CErrors = .EQFULL
    #elseif os(Linux) || os(Android)
        // MARK: Linux/Android
        /*======================================================================================================*/
        /// Operation not permitted.
        ///
        public static let EPERM:           CErrors = CErrors(code: POSIXErrorCode.EPERM.rawValue)
        /*======================================================================================================*/
        /// No such file or directory.
        ///
        public static let ENOENT:          CErrors = CErrors(code: POSIXErrorCode.ENOENT.rawValue)
        /*======================================================================================================*/
        /// No such process.
        ///
        public static let ESRCH:           CErrors = CErrors(code: POSIXErrorCode.ESRCH.rawValue)
        /*======================================================================================================*/
        /// Interrupted system call.
        ///
        public static let EINTR:           CErrors = CErrors(code: POSIXErrorCode.EINTR.rawValue)
        /*======================================================================================================*/
        /// Input/output error.
        ///
        public static let EIO:             CErrors = CErrors(code: POSIXErrorCode.EIO.rawValue)
        /*======================================================================================================*/
        /// Device not configured.
        ///
        public static let ENXIO:           CErrors = CErrors(code: POSIXErrorCode.ENXIO.rawValue)
        /*======================================================================================================*/
        /// Argument list too long.
        ///
        public static let E2BIG:           CErrors = CErrors(code: POSIXErrorCode.E2BIG.rawValue)
        /*======================================================================================================*/
        /// Exec format error.
        ///
        public static let ENOEXEC:         CErrors = CErrors(code: POSIXErrorCode.ENOEXEC.rawValue)
        /*======================================================================================================*/
        /// Bad file descriptor.
        ///
        public static let EBADF:           CErrors = CErrors(code: POSIXErrorCode.EBADF.rawValue)
        /*======================================================================================================*/
        /// No child processes.
        ///
        public static let ECHILD:          CErrors = CErrors(code: POSIXErrorCode.ECHILD.rawValue)
        /*======================================================================================================*/
        /// Try again.
        ///
        public static let EAGAIN:          CErrors = CErrors(code: POSIXErrorCode.EAGAIN.rawValue)
        /*======================================================================================================*/
        /// Cannot allocate memory.
        ///
        public static let ENOMEM:          CErrors = CErrors(code: POSIXErrorCode.ENOMEM.rawValue)
        /*======================================================================================================*/
        /// Permission denied.
        ///
        public static let EACCES:          CErrors = CErrors(code: POSIXErrorCode.EACCES.rawValue)
        /*======================================================================================================*/
        /// Bad address.
        ///
        public static let EFAULT:          CErrors = CErrors(code: POSIXErrorCode.EFAULT.rawValue)
        /*======================================================================================================*/
        /// Block device required.
        ///
        public static let ENOTBLK:         CErrors = CErrors(code: POSIXErrorCode.ENOTBLK.rawValue)
        /*======================================================================================================*/
        /// Device / Resource busy.
        ///
        public static let EBUSY:           CErrors = CErrors(code: POSIXErrorCode.EBUSY.rawValue)
        /*======================================================================================================*/
        /// File exists.
        ///
        public static let EEXIST:          CErrors = CErrors(code: POSIXErrorCode.EEXIST.rawValue)
        /*======================================================================================================*/
        /// Cross-device link.
        ///
        public static let EXDEV:           CErrors = CErrors(code: POSIXErrorCode.EXDEV.rawValue)
        /*======================================================================================================*/
        /// Operation not supported by device.
        ///
        public static let ENODEV:          CErrors = CErrors(code: POSIXErrorCode.ENODEV.rawValue)
        /*======================================================================================================*/
        /// Not a directory.
        ///
        public static let ENOTDIR:         CErrors = CErrors(code: POSIXErrorCode.ENOTDIR.rawValue)
        /*======================================================================================================*/
        /// Is a directory.
        ///
        public static let EISDIR:          CErrors = CErrors(code: POSIXErrorCode.EISDIR.rawValue)
        /*======================================================================================================*/
        /// Invalid argument.
        ///
        public static let EINVAL:          CErrors = CErrors(code: POSIXErrorCode.EINVAL.rawValue)
        /*======================================================================================================*/
        /// Too many open files in system.
        ///
        public static let ENFILE:          CErrors = CErrors(code: POSIXErrorCode.ENFILE.rawValue)
        /*======================================================================================================*/
        /// Too many open files.
        ///
        public static let EMFILE:          CErrors = CErrors(code: POSIXErrorCode.EMFILE.rawValue)
        /*======================================================================================================*/
        /// Inappropriate ioctl for device.
        ///
        public static let ENOTTY:          CErrors = CErrors(code: POSIXErrorCode.ENOTTY.rawValue)
        /*======================================================================================================*/
        /// Text file busy.
        ///
        public static let ETXTBSY:         CErrors = CErrors(code: POSIXErrorCode.ETXTBSY.rawValue)
        /*======================================================================================================*/
        /// File too large.
        ///
        public static let EFBIG:           CErrors = CErrors(code: POSIXErrorCode.EFBIG.rawValue)
        /*======================================================================================================*/
        /// No space left on device.
        ///
        public static let ENOSPC:          CErrors = CErrors(code: POSIXErrorCode.ENOSPC.rawValue)
        /*======================================================================================================*/
        /// Illegal seek.
        ///
        public static let ESPIPE:          CErrors = CErrors(code: POSIXErrorCode.ESPIPE.rawValue)
        /*======================================================================================================*/
        /// Read-only file system.
        ///
        public static let EROFS:           CErrors = CErrors(code: POSIXErrorCode.EROFS.rawValue)
        /*======================================================================================================*/
        /// Too many links.
        ///
        public static let EMLINK:          CErrors = CErrors(code: POSIXErrorCode.EMLINK.rawValue)
        /*======================================================================================================*/
        /// Broken pipe.
        ///
        public static let EPIPE:           CErrors = CErrors(code: POSIXErrorCode.EPIPE.rawValue)
        /*======================================================================================================*/
        /// Numerical argument out of domain.
        ///
        public static let EDOM:            CErrors = CErrors(code: POSIXErrorCode.EDOM.rawValue)
        /*======================================================================================================*/
        /// Result too large.
        ///
        public static let ERANGE:          CErrors = CErrors(code: POSIXErrorCode.ERANGE.rawValue)
        /*======================================================================================================*/
        /// Resource deadlock would occur.
        ///
        public static let EDEADLK:         CErrors = CErrors(code: POSIXErrorCode.EDEADLK.rawValue)
        /*======================================================================================================*/
        /// File name too long.
        ///
        public static let ENAMETOOLONG:    CErrors = CErrors(code: POSIXErrorCode.ENAMETOOLONG.rawValue)
        /*======================================================================================================*/
        /// No record locks available
        ///
        public static let ENOLCK:          CErrors = CErrors(code: POSIXErrorCode.ENOLCK.rawValue)
        /*======================================================================================================*/
        /// Function not implemented.
        ///
        public static let ENOSYS:          CErrors = CErrors(code: POSIXErrorCode.ENOSYS.rawValue)
        /*======================================================================================================*/
        /// Directory not empty.
        ///
        public static let ENOTEMPTY:       CErrors = CErrors(code: POSIXErrorCode.ENOTEMPTY.rawValue)
        /*======================================================================================================*/
        /// Too many symbolic links encountered
        ///
        public static let ELOOP:           CErrors = CErrors(code: POSIXErrorCode.ELOOP.rawValue)
        /*======================================================================================================*/
        /// Operation would block.
        ///
        public static var EWOULDBLOCK:     CErrors = .EAGAIN
        /*======================================================================================================*/
        /// No message of desired type.
        ///
        public static let ENOMSG:          CErrors = CErrors(code: POSIXErrorCode.ENOMSG.rawValue)
        /*======================================================================================================*/
        /// Identifier removed.
        ///
        public static let EIDRM:           CErrors = CErrors(code: POSIXErrorCode.EIDRM.rawValue)
        /*======================================================================================================*/
        /// Channel number out of range.
        ///
        public static let ECHRNG:          CErrors = CErrors(code: POSIXErrorCode.ECHRNG.rawValue)
        /*======================================================================================================*/
        /// Level 2 not synchronized.
        ///
        public static let EL2NSYNC:        CErrors = CErrors(code: POSIXErrorCode.EL2NSYNC.rawValue)
        /*======================================================================================================*/
        /// Level 3 halted
        ///
        public static let EL3HLT:          CErrors = CErrors(code: POSIXErrorCode.EL3HLT.rawValue)
        /*======================================================================================================*/
        /// Level 3 reset.
        ///
        public static let EL3RST:          CErrors = CErrors(code: POSIXErrorCode.EL3RST.rawValue)
        /*======================================================================================================*/
        /// Link number out of range.
        ///
        public static let ELNRNG:          CErrors = CErrors(code: POSIXErrorCode.ELNRNG.rawValue)
        /*======================================================================================================*/
        /// Protocol driver not attached.
        ///
        public static let EUNATCH:         CErrors = CErrors(code: POSIXErrorCode.EUNATCH.rawValue)
        /*======================================================================================================*/
        /// No CSI structure available.
        ///
        public static let ENOCSI:          CErrors = CErrors(code: POSIXErrorCode.ENOCSI.rawValue)
        /*======================================================================================================*/
        /// Level 2 halted.
        ///
        public static let EL2HLT:          CErrors = CErrors(code: POSIXErrorCode.EL2HLT.rawValue)
        /*======================================================================================================*/
        /// Invalid exchange
        ///
        public static let EBADE:           CErrors = CErrors(code: POSIXErrorCode.EBADE.rawValue)
        /*======================================================================================================*/
        /// Invalid request descriptor
        ///
        public static let EBADR:           CErrors = CErrors(code: POSIXErrorCode.EBADR.rawValue)
        /*======================================================================================================*/
        /// Exchange full
        ///
        public static let EXFULL:          CErrors = CErrors(code: POSIXErrorCode.EXFULL.rawValue)
        /*======================================================================================================*/
        /// No anode
        ///
        public static let ENOANO:          CErrors = CErrors(code: POSIXErrorCode.ENOANO.rawValue)
        /*======================================================================================================*/
        /// Invalid request code
        ///
        public static let EBADRQC:         CErrors = CErrors(code: POSIXErrorCode.EBADRQC.rawValue)
        /*======================================================================================================*/
        /// Invalid slot
        ///
        public static let EBADSLT:         CErrors = CErrors(code: POSIXErrorCode.EBADSLT.rawValue)
        /*======================================================================================================*/
        /// Resource deadlock would occur.
        ///
        public static var EDEADLOCK:       CErrors = .EDEADLK
        /*======================================================================================================*/
        /// Bad font file format
        ///
        public static let EBFONT:          CErrors = CErrors(code: POSIXErrorCode.EBFONT.rawValue)
        /*======================================================================================================*/
        /// Device not a stream
        ///
        public static let ENOSTR:          CErrors = CErrors(code: POSIXErrorCode.ENOSTR.rawValue)
        /*======================================================================================================*/
        /// No data available
        ///
        public static let ENODATA:         CErrors = CErrors(code: POSIXErrorCode.ENODATA.rawValue)
        /*======================================================================================================*/
        /// Timer expired
        ///
        public static let ETIME:           CErrors = CErrors(code: POSIXErrorCode.ETIME.rawValue)
        /*======================================================================================================*/
        /// Out of streams resources
        ///
        public static let ENOSR:           CErrors = CErrors(code: POSIXErrorCode.ENOSR.rawValue)
        /*======================================================================================================*/
        /// Machine is not on the network
        ///
        public static let ENONET:          CErrors = CErrors(code: POSIXErrorCode.ENONET.rawValue)
        /*======================================================================================================*/
        /// Package not installed
        ///
        public static let ENOPKG:          CErrors = CErrors(code: POSIXErrorCode.ENOPKG.rawValue)
        /*======================================================================================================*/
        /// Object is remote
        ///
        public static let EREMOTE:         CErrors = CErrors(code: POSIXErrorCode.EREMOTE.rawValue)
        /*======================================================================================================*/
        /// Link has been severed
        ///
        public static let ENOLINK:         CErrors = CErrors(code: POSIXErrorCode.ENOLINK.rawValue)
        /*======================================================================================================*/
        /// Advertise error
        ///
        public static let EADV:            CErrors = CErrors(code: POSIXErrorCode.EADV.rawValue)
        /*======================================================================================================*/
        /// Srmount error
        ///
        public static let ESRMNT:          CErrors = CErrors(code: POSIXErrorCode.ESRMNT.rawValue)
        /*======================================================================================================*/
        /// Communication error on send
        ///
        public static let ECOMM:           CErrors = CErrors(code: POSIXErrorCode.ECOMM.rawValue)
        /*======================================================================================================*/
        /// Protocol error
        ///
        public static let EPROTO:          CErrors = CErrors(code: POSIXErrorCode.EPROTO.rawValue)
        /*======================================================================================================*/
        /// Multihop attempted
        ///
        public static let EMULTIHOP:       CErrors = CErrors(code: POSIXErrorCode.EMULTIHOP.rawValue)
        /*======================================================================================================*/
        /// RFS specific error
        ///
        public static let EDOTDOT:         CErrors = CErrors(code: POSIXErrorCode.EDOTDOT.rawValue)
        /*======================================================================================================*/
        /// Not a data message
        ///
        public static let EBADMSG:         CErrors = CErrors(code: POSIXErrorCode.EBADMSG.rawValue)
        /*======================================================================================================*/
        /// Value too large for defined data type
        ///
        public static let EOVERFLOW:       CErrors = CErrors(code: POSIXErrorCode.EOVERFLOW.rawValue)
        /*======================================================================================================*/
        /// Name not unique on network
        ///
        public static let ENOTUNIQ:        CErrors = CErrors(code: POSIXErrorCode.ENOTUNIQ.rawValue)
        /*======================================================================================================*/
        /// File descriptor in bad state
        ///
        public static let EBADFD:          CErrors = CErrors(code: POSIXErrorCode.EBADFD.rawValue)
        /*======================================================================================================*/
        /// Remote address changed
        ///
        public static let EREMCHG:         CErrors = CErrors(code: POSIXErrorCode.EREMCHG.rawValue)
        /*======================================================================================================*/
        /// Can not access a needed shared library
        ///
        public static let ELIBACC:         CErrors = CErrors(code: POSIXErrorCode.ELIBACC.rawValue)
        /*======================================================================================================*/
        /// Accessing a corrupted shared library
        ///
        public static let ELIBBAD:         CErrors = CErrors(code: POSIXErrorCode.ELIBBAD.rawValue)
        /*======================================================================================================*/
        /// .lib section in a.out corrupted
        ///
        public static let ELIBSCN:         CErrors = CErrors(code: POSIXErrorCode.ELIBSCN.rawValue)
        /*======================================================================================================*/
        /// Attempting to link in too many shared libraries
        ///
        public static let ELIBMAX:         CErrors = CErrors(code: POSIXErrorCode.ELIBMAX.rawValue)
        /*======================================================================================================*/
        /// Cannot exec a shared library directly
        ///
        public static let ELIBEXEC:        CErrors = CErrors(code: POSIXErrorCode.ELIBEXEC.rawValue)
        /*======================================================================================================*/
        /// Illegal byte sequence
        ///
        public static let EILSEQ:          CErrors = CErrors(code: POSIXErrorCode.EILSEQ.rawValue)
        /*======================================================================================================*/
        /// Interrupted system call should be restarted
        ///
        public static let ERESTART:        CErrors = CErrors(code: POSIXErrorCode.ERESTART.rawValue)
        /*======================================================================================================*/
        /// Streams pipe error
        ///
        public static let ESTRPIPE:        CErrors = CErrors(code: POSIXErrorCode.ESTRPIPE.rawValue)
        /*======================================================================================================*/
        /// Too many users
        ///
        public static let EUSERS:          CErrors = CErrors(code: POSIXErrorCode.EUSERS.rawValue)
        /*======================================================================================================*/
        /// Socket operation on non-socket
        ///
        public static let ENOTSOCK:        CErrors = CErrors(code: POSIXErrorCode.ENOTSOCK.rawValue)
        /*======================================================================================================*/
        /// Destination address required
        ///
        public static let EDESTADDRREQ:    CErrors = CErrors(code: POSIXErrorCode.EDESTADDRREQ.rawValue)
        /*======================================================================================================*/
        /// Message too long
        ///
        public static let EMSGSIZE:        CErrors = CErrors(code: POSIXErrorCode.EMSGSIZE.rawValue)
        /*======================================================================================================*/
        /// Protocol wrong type for socket
        ///
        public static let EPROTOTYPE:      CErrors = CErrors(code: POSIXErrorCode.EPROTOTYPE.rawValue)
        /*======================================================================================================*/
        /// Protocol not available
        ///
        public static let ENOPROTOOPT:     CErrors = CErrors(code: POSIXErrorCode.ENOPROTOOPT.rawValue)
        /*======================================================================================================*/
        /// Protocol not supported
        ///
        public static let EPROTONOSUPPORT: CErrors = CErrors(code: POSIXErrorCode.EPROTONOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Socket type not supported
        ///
        public static let ESOCKTNOSUPPORT: CErrors = CErrors(code: POSIXErrorCode.ESOCKTNOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Operation not supported on transport endpoint
        ///
        public static let EOPNOTSUPP:      CErrors = CErrors(code: POSIXErrorCode.EOPNOTSUPP.rawValue)
        /*======================================================================================================*/
        /// Protocol family not supported
        ///
        public static let EPFNOSUPPORT:    CErrors = CErrors(code: POSIXErrorCode.EPFNOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Address family not supported by protocol
        ///
        public static let EAFNOSUPPORT:    CErrors = CErrors(code: POSIXErrorCode.EAFNOSUPPORT.rawValue)
        /*======================================================================================================*/
        /// Address already in use
        ///
        public static let EADDRINUSE:      CErrors = CErrors(code: POSIXErrorCode.EADDRINUSE.rawValue)
        /*======================================================================================================*/
        /// Cannot assign requested address
        ///
        public static let EADDRNOTAVAIL:   CErrors = CErrors(code: POSIXErrorCode.EADDRNOTAVAIL.rawValue)
        /*======================================================================================================*/
        /// Network is down
        ///
        public static let ENETDOWN:        CErrors = CErrors(code: POSIXErrorCode.ENETDOWN.rawValue)
        /*======================================================================================================*/
        /// Network is unreachable
        ///
        public static let ENETUNREACH:     CErrors = CErrors(code: POSIXErrorCode.ENETUNREACH.rawValue)
        /*======================================================================================================*/
        /// Network dropped connection because of reset
        ///
        public static let ENETRESET:       CErrors = CErrors(code: POSIXErrorCode.ENETRESET.rawValue)
        /*======================================================================================================*/
        /// Software caused connection abort
        ///
        public static let ECONNABORTED:    CErrors = CErrors(code: POSIXErrorCode.ECONNABORTED.rawValue)
        /*======================================================================================================*/
        /// Connection reset by peer
        ///
        public static let ECONNRESET:      CErrors = CErrors(code: POSIXErrorCode.ECONNRESET.rawValue)
        /*======================================================================================================*/
        /// No buffer space available
        ///
        public static let ENOBUFS:         CErrors = CErrors(code: POSIXErrorCode.ENOBUFS.rawValue)
        /*======================================================================================================*/
        /// Transport endpoint is already connected
        ///
        public static let EISCONN:         CErrors = CErrors(code: POSIXErrorCode.EISCONN.rawValue)
        /*======================================================================================================*/
        /// Transport endpoint is not connected
        ///
        public static let ENOTCONN:        CErrors = CErrors(code: POSIXErrorCode.ENOTCONN.rawValue)
        /*======================================================================================================*/
        /// Cannot send after transport endpoint shutdown
        ///
        public static let ESHUTDOWN:       CErrors = CErrors(code: POSIXErrorCode.ESHUTDOWN.rawValue)
        /*======================================================================================================*/
        /// Too many references: cannot splice
        ///
        public static let ETOOMANYREFS:    CErrors = CErrors(code: POSIXErrorCode.ETOOMANYREFS.rawValue)
        /*======================================================================================================*/
        /// Connection timed out
        ///
        public static let ETIMEDOUT:       CErrors = CErrors(code: POSIXErrorCode.ETIMEDOUT.rawValue)
        /*======================================================================================================*/
        /// Connection refused
        ///
        public static let ECONNREFUSED:    CErrors = CErrors(code: POSIXErrorCode.ECONNREFUSED.rawValue)
        /*======================================================================================================*/
        /// Host is down
        ///
        public static let EHOSTDOWN:       CErrors = CErrors(code: POSIXErrorCode.EHOSTDOWN.rawValue)
        /*======================================================================================================*/
        /// No route to host
        ///
        public static let EHOSTUNREACH:    CErrors = CErrors(code: POSIXErrorCode.EHOSTUNREACH.rawValue)
        /*======================================================================================================*/
        /// Operation already in progress
        ///
        public static let EALREADY:        CErrors = CErrors(code: POSIXErrorCode.EALREADY.rawValue)
        /*======================================================================================================*/
        /// Operation now in progress
        ///
        public static let EINPROGRESS:     CErrors = CErrors(code: POSIXErrorCode.EINPROGRESS.rawValue)
        /*======================================================================================================*/
        /// Stale NFS file handle
        ///
        public static let ESTALE:          CErrors = CErrors(code: POSIXErrorCode.ESTALE.rawValue)
        /*======================================================================================================*/
        /// Structure needs cleaning
        ///
        public static let EUCLEAN:         CErrors = CErrors(code: POSIXErrorCode.EUCLEAN.rawValue)
        /*======================================================================================================*/
        /// Not a XENIX named type file
        ///
        public static let ENOTNAM:         CErrors = CErrors(code: POSIXErrorCode.ENOTNAM.rawValue)
        /*======================================================================================================*/
        /// No XENIX semaphores available
        ///
        public static let ENAVAIL:         CErrors = CErrors(code: POSIXErrorCode.ENAVAIL.rawValue)
        /*======================================================================================================*/
        /// Is a named type file
        ///
        public static let EISNAM:          CErrors = CErrors(code: POSIXErrorCode.EISNAM.rawValue)
        /*======================================================================================================*/
        /// Remote I/O error
        ///
        public static let EREMOTEIO:       CErrors = CErrors(code: POSIXErrorCode.EREMOTEIO.rawValue)
        /*======================================================================================================*/
        /// Quota exceeded
        ///
        public static let EDQUOT:          CErrors = CErrors(code: POSIXErrorCode.EDQUOT.rawValue)
        /*======================================================================================================*/
        /// No medium found
        ///
        public static let ENOMEDIUM:       CErrors = CErrors(code: POSIXErrorCode.ENOMEDIUM.rawValue)
        /*======================================================================================================*/
        /// Wrong medium type
        ///
        public static let EMEDIUMTYPE:     CErrors = CErrors(code: POSIXErrorCode.EMEDIUMTYPE.rawValue)
        /*======================================================================================================*/
        /// Operation Canceled
        ///
        public static let ECANCELED:       CErrors = CErrors(code: POSIXErrorCode.ECANCELED.rawValue)
        /*======================================================================================================*/
        /// Required key not available
        ///
        public static let ENOKEY:          CErrors = CErrors(code: POSIXErrorCode.ENOKEY.rawValue)
        /*======================================================================================================*/
        /// Key has expired
        ///
        public static let EKEYEXPIRED:     CErrors = CErrors(code: POSIXErrorCode.EKEYEXPIRED.rawValue)
        /*======================================================================================================*/
        /// Key has been revoked
        ///
        public static let EKEYREVOKED:     CErrors = CErrors(code: POSIXErrorCode.EKEYREVOKED.rawValue)
        /*======================================================================================================*/
        /// Key was rejected by service
        ///
        public static let EKEYREJECTED:    CErrors = CErrors(code: POSIXErrorCode.EKEYREJECTED.rawValue)
        /*======================================================================================================*/
        /// Owner died
        ///
        public static let EOWNERDEAD:      CErrors = CErrors(code: POSIXErrorCode.EOWNERDEAD.rawValue)
        /*======================================================================================================*/
        /// State not recoverable
        ///
        public static let ENOTRECOVERABLE: CErrors = CErrors(code: POSIXErrorCode.ENOTRECOVERABLE.rawValue)
        /*======================================================================================================*/
        /// Operation not possible due to RF-kill
        ///
        public static let ERFKILL:         CErrors = CErrors(code: POSIXErrorCode.ERFKILL.rawValue)
        /*======================================================================================================*/
        /// Memory page has hardware error
        ///
        public static let EHWPOISON:       CErrors = CErrors(code: POSIXErrorCode.EHWPOISON.rawValue)
    #elseif os(Windows)
        // MARK: Windows
        /*======================================================================================================*/
        /// Operation not permitted
        ///
        public static let EPERM:        CErrors = CErrors(code: POSIXErrorCode.EPERM.rawValue)
        /*======================================================================================================*/
        /// No such file or directory
        ///
        public static let ENOENT:       CErrors = CErrors(code: POSIXErrorCode.ENOENT.rawValue)
        /*======================================================================================================*/
        /// No such process
        ///
        public static let ESRCH:        CErrors = CErrors(code: POSIXErrorCode.ESRCH.rawValue)
        /*======================================================================================================*/
        /// Interrupted function
        ///
        public static let EINTR:        CErrors = CErrors(code: POSIXErrorCode.EINTR.rawValue)
        /*======================================================================================================*/
        /// I/O error
        ///
        public static let EIO:          CErrors = CErrors(code: POSIXErrorCode.EIO.rawValue)
        /*======================================================================================================*/
        /// No such device or address
        ///
        public static let ENXIO:        CErrors = CErrors(code: POSIXErrorCode.ENXIO.rawValue)
        /*======================================================================================================*/
        /// Argument list too long
        ///
        public static let E2BIG:        CErrors = CErrors(code: POSIXErrorCode.E2BIG.rawValue)
        /*======================================================================================================*/
        /// Exec format error
        ///
        public static let ENOEXEC:      CErrors = CErrors(code: POSIXErrorCode.ENOEXEC.rawValue)
        /*======================================================================================================*/
        /// Bad file number
        ///
        public static let EBADF:        CErrors = CErrors(code: POSIXErrorCode.EBADF.rawValue)
        /*======================================================================================================*/
        /// No spawned processes
        ///
        public static let ECHILD:       CErrors = CErrors(code: POSIXErrorCode.ECHILD.rawValue)
        /*======================================================================================================*/
        /// No more processes or not enough memory or maximum nesting level reached
        ///
        public static let EAGAIN:       CErrors = CErrors(code: POSIXErrorCode.EAGAIN.rawValue)
        /*======================================================================================================*/
        /// Not enough memory
        ///
        public static let ENOMEM:       CErrors = CErrors(code: POSIXErrorCode.ENOMEM.rawValue)
        /*======================================================================================================*/
        /// Permission denied
        ///
        public static let EACCES:       CErrors = CErrors(code: POSIXErrorCode.EACCES.rawValue)
        /*======================================================================================================*/
        /// Bad address
        ///
        public static let EFAULT:       CErrors = CErrors(code: POSIXErrorCode.EFAULT.rawValue)
        /*======================================================================================================*/
        /// Device or resource busy
        ///
        public static let EBUSY:        CErrors = CErrors(code: POSIXErrorCode.EBUSY.rawValue)
        /*======================================================================================================*/
        /// File exists
        ///
        public static let EEXIST:       CErrors = CErrors(code: POSIXErrorCode.EEXIST.rawValue)
        /*======================================================================================================*/
        /// Cross-device link
        ///
        public static let EXDEV:        CErrors = CErrors(code: POSIXErrorCode.EXDEV.rawValue)
        /*======================================================================================================*/
        /// No such device
        ///
        public static let ENODEV:       CErrors = CErrors(code: POSIXErrorCode.ENODEV.rawValue)
        /*======================================================================================================*/
        /// Not a directory
        ///
        public static let ENOTDIR:      CErrors = CErrors(code: POSIXErrorCode.ENOTDIR.rawValue)
        /*======================================================================================================*/
        /// Is a directory
        ///
        public static let EISDIR:       CErrors = CErrors(code: POSIXErrorCode.EISDIR.rawValue)
        /*======================================================================================================*/
        /// Invalid argument
        ///
        public static let EINVAL:       CErrors = CErrors(code: POSIXErrorCode.EINVAL.rawValue)
        /*======================================================================================================*/
        /// Too many files open in system
        ///
        public static let ENFILE:       CErrors = CErrors(code: POSIXErrorCode.ENFILE.rawValue)
        /*======================================================================================================*/
        /// Too many open files
        ///
        public static let EMFILE:       CErrors = CErrors(code: POSIXErrorCode.EMFILE.rawValue)
        /*======================================================================================================*/
        /// Inappropriate I/O control operation
        ///
        public static let ENOTTY:       CErrors = CErrors(code: POSIXErrorCode.ENOTTY.rawValue)
        /*======================================================================================================*/
        /// File too large
        ///
        public static let EFBIG:        CErrors = CErrors(code: POSIXErrorCode.EFBIG.rawValue)
        /*======================================================================================================*/
        /// No space left on device
        ///
        public static let ENOSPC:       CErrors = CErrors(code: POSIXErrorCode.ENOSPC.rawValue)
        /*======================================================================================================*/
        /// Invalid seek
        ///
        public static let ESPIPE:       CErrors = CErrors(code: POSIXErrorCode.ESPIPE.rawValue)
        /*======================================================================================================*/
        /// Read-only file system
        ///
        public static let EROFS:        CErrors = CErrors(code: POSIXErrorCode.EROFS.rawValue)
        /*======================================================================================================*/
        /// Too many links
        ///
        public static let EMLINK:       CErrors = CErrors(code: POSIXErrorCode.EMLINK.rawValue)
        /*======================================================================================================*/
        /// Broken pipe
        ///
        public static let EPIPE:        CErrors = CErrors(code: POSIXErrorCode.EPIPE.rawValue)
        /*======================================================================================================*/
        /// Math argument
        ///
        public static let EDOM:         CErrors = CErrors(code: POSIXErrorCode.EDOM.rawValue)
        /*======================================================================================================*/
        /// Result too large
        ///
        public static let ERANGE:       CErrors = CErrors(code: POSIXErrorCode.ERANGE.rawValue)
        /*======================================================================================================*/
        /// Resource deadlock would occur
        ///
        public static let EDEADLK:      CErrors = CErrors(code: POSIXErrorCode.EDEADLK.rawValue)
        /*======================================================================================================*/
        /// Same as EDEADLK for compatibility with older Microsoft C versions
        ///
        public static let EDEADLOCK:    CErrors = .EDEADLK
        /*======================================================================================================*/
        /// Filename too long
        ///
        public static let ENAMETOOLONG: CErrors = CErrors(code: POSIXErrorCode.ENAMETOOLONG.rawValue)
        /*======================================================================================================*/
        /// No locks available
        ///
        public static let ENOLCK:       CErrors = CErrors(code: POSIXErrorCode.ENOLCK.rawValue)
        /*======================================================================================================*/
        /// Function not supported
        ///
        public static let ENOSYS:       CErrors = CErrors(code: POSIXErrorCode.ENOSYS.rawValue)
        /*======================================================================================================*/
        /// Directory not empty
        ///
        public static let ENOTEMPTY:    CErrors = CErrors(code: POSIXErrorCode.ENOTEMPTY.rawValue)
        /*======================================================================================================*/
        /// Illegal byte sequence
        ///
        public static let EILSEQ:       CErrors = CErrors(code: POSIXErrorCode.EILSEQ.rawValue)
        /*======================================================================================================*/
        /// String was truncated
        ///
        public static let STRUNCATE:    CErrors = CErrors(code: POSIXErrorCode.STRUNCATE.rawValue)

    #endif
}
