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
    (CString.newCCharBufferOf(length: 1000) {
        ((strerror_r(code, $0, $1) == 0) ? strlen($0) : -1)
    })?.string ?? "Unknown Error: \(code)"
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

//@f:0
/*==============================================================================================================*/
/// Allows wrapping the errors returned by calls to the Standard C Library so they can be thrown as exceptions.
///
public enum CErrors: Equatable, Error, CustomStringConvertible {
    /*==========================================================================================================*/
    /// Permission denied
    ///
    case ACCES(description: String = "Permission denied")
    /*==========================================================================================================*/
    /// Address already in use
    ///
    case ADDRINUSE(description: String = "Address already in use")
    /*==========================================================================================================*/
    /// Can't assign requested address
    ///
    case ADDRNOTAVAIL(description: String = "Can't assign requested address")
    /*==========================================================================================================*/
    /// Address family not supported by protocol family
    ///
    case AFNOSUPPORT(description: String = "Address family not supported by protocol family")
    /*==========================================================================================================*/
    /// Resource temporarily unavailable
    ///
    case AGAIN(description: String = "Resource temporarily unavailable")
    /*==========================================================================================================*/
    /// Operation already in progress
    ///
    case ALREADY(description: String = "Operation already in progress")
    /*==========================================================================================================*/
    /// Bad file descriptor
    ///
    case BADF(description: String = "Bad file descriptor")
    /*==========================================================================================================*/
    /// Bad message
    ///
    case BADMSG(description: String = "Bad message")
    /*==========================================================================================================*/
    /// Device / Resource busy
    ///
    case BUSY(description: String = "Device / Resource busy")
    /*==========================================================================================================*/
    /// Operation canceled
    ///
    case CANCELED(description: String = "Operation canceled")
    /*==========================================================================================================*/
    /// No child processes
    ///
    case CHILD(description: String = "No child processes")
    /*==========================================================================================================*/
    /// Software caused connection abort
    ///
    case CONNABORTED(description: String = "Software caused connection abort")
    /*==========================================================================================================*/
    /// Connection refused
    ///
    case CONNREFUSED(description: String = "Connection refused")
    /*==========================================================================================================*/
    /// Connection reset by peer
    ///
    case CONNRESET(description: String = "Connection reset by peer")
    /*==========================================================================================================*/
    /// Resource deadlock avoided
    ///
    case DEADLK(description: String = "Resource deadlock avoided")
    /*==========================================================================================================*/
    /// Destination address required
    ///
    case DESTADDRREQ(description: String = "Destination address required")
    /*==========================================================================================================*/
    /// Numerical argument out of domain
    ///
    case DOM(description: String = "Numerical argument out of domain")
    /*==========================================================================================================*/
    /// Disc quota exceeded
    ///
    case DQUOT(description: String = "Disc quota exceeded")
    /*==========================================================================================================*/
    /// File exists
    ///
    case EXIST(description: String = "File exists")
    /*==========================================================================================================*/
    /// Bad address
    ///
    case FAULT(description: String = "Bad address")
    /*==========================================================================================================*/
    /// File too large
    ///
    case FBIG(description: String = "File too large")
    /*==========================================================================================================*/
    /// Host is down
    ///
    case HOSTDOWN(description: String = "Host is down")
    /*==========================================================================================================*/
    /// No route to host
    ///
    case HOSTUNREACH(description: String = "No route to host")
    /*==========================================================================================================*/
    /// Identifier removed
    ///
    case IDRM(description: String = "Identifier removed")
    /*==========================================================================================================*/
    /// Illegal byte sequence
    ///
    case ILSEQ(description: String = "Illegal byte sequence")
    /*==========================================================================================================*/
    /// Operation now in progress
    ///
    case INPROGRESS(description: String = "Operation now in progress")
    /*==========================================================================================================*/
    /// Interrupted system call
    ///
    case INTR(description: String = "Interrupted system call")
    /*==========================================================================================================*/
    /// Invalid argument
    ///
    case INVAL(description: String = "Invalid argument")
    /*==========================================================================================================*/
    /// Input/output error
    ///
    case IO(description: String = "Input/output error")
    /*==========================================================================================================*/
    /// Socket is already connected
    ///
    case ISCONN(description: String = "Socket is already connected")
    /*==========================================================================================================*/
    /// Is a directory
    ///
    case ISDIR(description: String = "Is a directory")
    /*==========================================================================================================*/
    /// Too many levels of symbolic links
    ///
    case LOOP(description: String = "Too many levels of symbolic links")
    /*==========================================================================================================*/
    /// Too many open files
    ///
    case MFILE(description: String = "Too many open files")
    /*==========================================================================================================*/
    /// Too many links
    ///
    case MLINK(description: String = "Too many links")
    /*==========================================================================================================*/
    /// Message too long
    ///
    case MSGSIZE(description: String = "Message too long")
    /*==========================================================================================================*/
    /// Reserved
    ///
    case MULTIHOP(description: String = "Reserved")
    /*==========================================================================================================*/
    /// File name too long
    ///
    case NAMETOOLONG(description: String = "File name too long")
    /*==========================================================================================================*/
    /// Network is down
    ///
    case NETDOWN(description: String = "Network is down")
    /*==========================================================================================================*/
    /// Network dropped connection on reset
    ///
    case NETRESET(description: String = "Network dropped connection on reset")
    /*==========================================================================================================*/
    /// Network is unreachable
    ///
    case NETUNREACH(description: String = "Network is unreachable")
    /*==========================================================================================================*/
    /// Too many open files in system
    ///
    case NFILE(description: String = "Too many open files in system")
    /*==========================================================================================================*/
    /// No buffer space available
    ///
    case NOBUFS(description: String = "No buffer space available")
    /*==========================================================================================================*/
    /// No message available on STREAM
    ///
    case NODATA(description: String = "No message available on STREAM")
    /*==========================================================================================================*/
    /// Operation not supported by device
    ///
    case NODEV(description: String = "Operation not supported by device")
    /*==========================================================================================================*/
    /// No such file or directory
    ///
    case NOENT(description: String = "No such file or directory")
    /*==========================================================================================================*/
    /// Exec format error
    ///
    case NOEXEC(description: String = "Exec format error")
    /*==========================================================================================================*/
    /// No locks available
    ///
    case NOLCK(description: String = "No locks available")
    /*==========================================================================================================*/
    /// Reserved
    ///
    case NOLINK(description: String = "Reserved")
    /*==========================================================================================================*/
    /// Cannot allocate memory
    ///
    case NOMEM(description: String = "Cannot allocate memory")
    /*==========================================================================================================*/
    /// No message of desired type
    ///
    case NOMSG(description: String = "No message of desired type")
    /*==========================================================================================================*/
    /// Protocol not available
    ///
    case NOPROTOOPT(description: String = "Protocol not available")
    /*==========================================================================================================*/
    /// No space left on device
    ///
    case NOSPC(description: String = "No space left on device")
    /*==========================================================================================================*/
    /// No STREAM resources
    ///
    case NOSR(description: String = "No STREAM resources")
    /*==========================================================================================================*/
    /// Not a STREAM
    ///
    case NOSTR(description: String = "Not a STREAM")
    /*==========================================================================================================*/
    /// Function not implemented
    ///
    case NOSYS(description: String = "Function not implemented")
    /*==========================================================================================================*/
    /// Block device required
    ///
    case NOTBLK(description: String = "Block device required")
    /*==========================================================================================================*/
    /// Socket is not connected
    ///
    case NOTCONN(description: String = "Socket is not connected")
    /*==========================================================================================================*/
    /// Not a directory
    ///
    case NOTDIR(description: String = "Not a directory")
    /*==========================================================================================================*/
    /// Directory not empty
    ///
    case NOTEMPTY(description: String = "Directory not empty")
    /*==========================================================================================================*/
    /// State not recoverable
    ///
    case NOTRECOVERABLE(description: String = "State not recoverable")
    /*==========================================================================================================*/
    /// Socket operation on non-socket
    ///
    case NOTSOCK(description: String = "Socket operation on non-socket")
    /*==========================================================================================================*/
    /// Operation not supported
    ///
    case NOTSUP(description: String = "Operation not supported")
    /*==========================================================================================================*/
    /// Inappropriate ioctl for device
    ///
    case NOTTY(description: String = "Inappropriate ioctl for device")
    /*==========================================================================================================*/
    /// Device not configured
    ///
    case NXIO(description: String = "Device not configured")
    /*==========================================================================================================*/
    /// Operation not supported on socket
    ///
    case OPNOTSUPP(description: String = "Operation not supported on socket")
    /*==========================================================================================================*/
    /// Value too large to be stored in data type
    ///
    case OVERFLOW(description: String = "Value too large to be stored in data type")
    /*==========================================================================================================*/
    /// Previous owner died
    ///
    case OWNERDEAD(description: String = "Previous owner died")
    /*==========================================================================================================*/
    /// Operation not permitted
    ///
    case PERM(description: String = "Operation not permitted")
    /*==========================================================================================================*/
    /// Protocol family not supported
    ///
    case PFNOSUPPORT(description: String = "Protocol family not supported")
    /*==========================================================================================================*/
    /// Broken pipe
    ///
    case PIPE(description: String = "Broken pipe")
    /*==========================================================================================================*/
    /// Protocol error
    ///
    case PROTO(description: String = "Protocol error")
    /*==========================================================================================================*/
    /// Protocol not supported
    ///
    case PROTONOSUPPORT(description: String = "Protocol not supported")
    /*==========================================================================================================*/
    /// Protocol wrong type for socket
    ///
    case PROTOTYPE(description: String = "Protocol wrong type for socket")
    /*==========================================================================================================*/
    /// <code>[Result](https://developer.apple.com/documentation/swift/result/)</code> too large
    ///
    case RANGE(description: String = "Result too large")
    /*==========================================================================================================*/
    /// Too many levels of remote in path
    ///
    case REMOTE(description: String = "Too many levels of remote in path")
    /*==========================================================================================================*/
    /// Read-only file system
    ///
    case ROFS(description: String = "Read-only file system")
    /*==========================================================================================================*/
    /// Can't send after socket shutdown
    ///
    case SHUTDOWN(description: String = "Can't send after socket shutdown")
    /*==========================================================================================================*/
    /// Socket type not supported
    ///
    case SOCKTNOSUPPORT(description: String = "Socket type not supported")
    /*==========================================================================================================*/
    /// Illegal seek
    ///
    case SPIPE(description: String = "Illegal seek")
    /*==========================================================================================================*/
    /// No such process
    ///
    case SRCH(description: String = "No such process")
    /*==========================================================================================================*/
    /// Stale NFS file handle
    ///
    case STALE(description: String = "Stale NFS file handle")
    /*==========================================================================================================*/
    /// STREAM ioctl timeout
    ///
    case TIME(description: String = "STREAM ioctl timeout")
    /*==========================================================================================================*/
    /// Operation timed out
    ///
    case TIMEDOUT(description: String = "Operation timed out")
    /*==========================================================================================================*/
    /// Argument list too long
    ///
    case TOBIG(description: String = "Argument list too long")
    /*==========================================================================================================*/
    /// Too many references: can't splice
    ///
    case TOOMANYREFS(description: String = "Too many references: can't splice")
    /*==========================================================================================================*/
    /// Text file busy
    ///
    case TXTBSY(description: String = "Text file busy")
    /*==========================================================================================================*/
    /// Too many users
    ///
    case USERS(description: String = "Too many users")
    /*==========================================================================================================*/
    /// Operation would block
    ///
    case WOULDBLOCK(description: String = "Operation would block")
    /*==========================================================================================================*/
    /// Cross-device link
    ///
    case XDEV(description: String = "Cross-device link")

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        // These only exist on Apple OS'.
        /*======================================================================================================*/
        /// Authentication error
        ///
        case AUTH(description: String = "Authentication error")
        /*======================================================================================================*/
        /// Bad CPU type in executable
        ///
        case BADARCH(description: String = "Bad CPU type in executable")
        /*======================================================================================================*/
        /// Bad executable
        ///
        case BADEXEC(description: String = "Bad executable")
        /*======================================================================================================*/
        /// Malformed Macho file
        ///
        case BADMACHO(description: String = "Malformed Macho file")
        /*======================================================================================================*/
        /// RPC struct is bad
        ///
        case BADRPC(description: String = "RPC struct is bad")
        /*======================================================================================================*/
        /// Device error, e.g. paper out
        ///
        case DEVERR(description: String = "Device error, e.g. paper out")
        /*======================================================================================================*/
        /// Inappropriate file type or format
        ///
        case FTYPE(description: String = "Inappropriate file type or format")
        /*======================================================================================================*/
        /// Must be equal largest errno
        ///
        case LAST(description: String = "Must be equal largest errno")
        /*======================================================================================================*/
        /// Need authenticator
        ///
        case NEEDAUTH(description: String = "Need authenticator")
        /*======================================================================================================*/
        /// Attribute not found
        ///
        case NOATTR(description: String = "Attribute not found")
        /*======================================================================================================*/
        /// No such policy registered
        ///
        case NOPOLICY(description: String = "No such policy registered")
        /*======================================================================================================*/
        /// Too many processes
        ///
        case PROCLIM(description: String = "Too many processes")
        /*======================================================================================================*/
        /// Bad procedure for program
        ///
        case PROCUNAVAIL(description: String = "Bad procedure for program")
        /*======================================================================================================*/
        /// Program version wrong
        ///
        case PROGMISMATCH(description: String = "Program version wrong")
        /*======================================================================================================*/
        /// RPC prog. not avail
        ///
        case PROGUNAVAIL(description: String = "RPC prog. not avail")
        /*======================================================================================================*/
        /// Device power is off
        ///
        case PWROFF(description: String = "Device power is off")
        /*======================================================================================================*/
        /// Interface output queue is full
        ///
        case QFULL(description: String = "Interface output queue is full")
        /*======================================================================================================*/
        /// RPC version wrong
        ///
        case RPCMISMATCH(description: String = "RPC version wrong")
        /*======================================================================================================*/
        /// Shared library version mismatch
        ///
        case SHLIBVERS(description: String = "Shared library version mismatch")
    #endif

    #if os(Linux)
        // These only exist on Linux.
        /*======================================================================================================*/
        /// Advertise error
        ///
        case ADV(description: String = "Advertise error")
        /*======================================================================================================*/
        /// Invalid exchange
        ///
        case BADE(description: String = "Invalid exchange")
        /*======================================================================================================*/
        /// File descriptor in bad state
        ///
        case BADFD(description: String = "File descriptor in bad state")
        /*======================================================================================================*/
        /// Invalid request descriptor
        ///
        case BADR(description: String = "Invalid request descriptor")
        /*======================================================================================================*/
        /// Invalid request code
        ///
        case BADRQC(description: String = "Invalid request code")
        /*======================================================================================================*/
        /// Invalid slot
        ///
        case BADSLT(description: String = "Invalid slot")
        /*======================================================================================================*/
        /// Bad font file format
        ///
        case BFONT(description: String = "Bad font file format")
        /*======================================================================================================*/
        /// Channel number out of range
        ///
        case CHRNG(description: String = "Channel number out of range")
        /*======================================================================================================*/
        /// Communication error on send
        ///
        case COMM(description: String = "Communication error on send")
        /*======================================================================================================*/
        /// Resource deadlock avoided
        ///
        case DEADLOCK(description: String = "Resource deadlock avoided")
        /*======================================================================================================*/
        /// RFS specific error
        ///
        case DOTDOT(description: String = "RFS specific error")
        /*======================================================================================================*/
        /// Memory page has hardware error
        ///
        case HWPOISON(description: String = "Memory page has hardware error")
        /*======================================================================================================*/
        /// Is a named type file
        ///
        case ISNAM(description: String = "Is a named type file")
        /*======================================================================================================*/
        /// Key has expired
        ///
        case KEYEXPIRED(description: String = "Key has expired")
        /*======================================================================================================*/
        /// Key was rejected by service
        ///
        case KEYREJECTED(description: String = "Key was rejected by service")
        /*======================================================================================================*/
        /// Key has been revoked
        ///
        case KEYREVOKED(description: String = "Key has been revoked")
        /*======================================================================================================*/
        /// Level 2 halted
        ///
        case L2HLT(description: String = "Level 2 halted")
        /*======================================================================================================*/
        /// Level 2 not synchronized
        ///
        case L2NSYNC(description: String = "Level 2 not synchronized")
        /*======================================================================================================*/
        /// Level 3 halted
        ///
        case L3HLT(description: String = "Level 3 halted")
        /*======================================================================================================*/
        /// Level 3 reset
        ///
        case L3RST(description: String = "Level 3 reset")
        /*======================================================================================================*/
        /// Can not access a needed shared library
        ///
        case LIBACC(description: String = "Can not access a needed shared library")
        /*======================================================================================================*/
        /// Accessing a corrupted shared library
        ///
        case LIBBAD(description: String = "Accessing a corrupted shared library")
        /*======================================================================================================*/
        /// Cannot exec a shared library directly
        ///
        case LIBEXEC(description: String = "Cannot exec a shared library directly")
        /*======================================================================================================*/
        /// Attempting to link in too many shared libraries
        ///
        case LIBMAX(description: String = "Attempting to link in too many shared libraries")
        /*======================================================================================================*/
        /// .lib section in a.out corrupted
        ///
        case LIBSCN(description: String = ".lib section in a.out corrupted")
        /*======================================================================================================*/
        /// Link number out of range
        ///
        case LNRNG(description: String = "Link number out of range")
        /*======================================================================================================*/
        /// Wrong medium type
        ///
        case MEDIUMTYPE(description: String = "Wrong medium type")
        /*======================================================================================================*/
        /// No XENIX semaphores available
        ///
        case NAVAIL(description: String = "No XENIX semaphores available")
        /*======================================================================================================*/
        /// No anode
        ///
        case NOANO(description: String = "No anode")
        /*======================================================================================================*/
        /// No CSI structure available
        ///
        case NOCSI(description: String = "No CSI structure available")
        /*======================================================================================================*/
        /// Required key not available
        ///
        case NOKEY(description: String = "Required key not available")
        /*======================================================================================================*/
        /// No medium found
        ///
        case NOMEDIUM(description: String = "No medium found")
        /*======================================================================================================*/
        /// Machine is not on the network
        ///
        case NONET(description: String = "Machine is not on the network")
        /*======================================================================================================*/
        /// Package not installed
        ///
        case NOPKG(description: String = "Package not installed")
        /*======================================================================================================*/
        /// Not a XENIX named type file
        ///
        case NOTNAM(description: String = "Not a XENIX named type file")
        /*======================================================================================================*/
        /// Name not unique on network
        ///
        case NOTUNIQ(description: String = "Name not unique on network")
        /*======================================================================================================*/
        /// Remote address changed
        ///
        case REMCHG(description: String = "Remote address changed")
        /*======================================================================================================*/
        /// Remote I/O error
        ///
        case REMOTEIO(description: String = "Remote I/O error")
        /*======================================================================================================*/
        /// Interrupted system call should be restarted
        ///
        case RESTART(description: String = "Interrupted system call should be restarted")
        /*======================================================================================================*/
        /// Operation not possible due to RF-kill
        ///
        case RFKILL(description: String = "Operation not possible due to RF-kill")
        /*======================================================================================================*/
        /// Srmount error
        ///
        case SRMNT(description: String = "Srmount error")
        /*======================================================================================================*/
        /// Streams pipe error
        ///
        case STRPIPE(description: String = "Streams pipe error")
        /*======================================================================================================*/
        /// Structure needs cleaning
        ///
        case UCLEAN(description: String = "Structure needs cleaning")
        /*======================================================================================================*/
        /// Protocol driver not attached
        ///
        case UNATCH(description: String = "Protocol driver not attached")
        /*======================================================================================================*/
        /// Exchange full
        ///
        case XFULL(description: String = "Exchange full")
    #endif

    /*==========================================================================================================*/
    /// You will never see this one. It's just to get rid of a warning.
    ///
    case UNKNOWN(description: String = "Unknown Error", code: Int32)

    /*==========================================================================================================*/
    /// The operating system supplied message for this error.
    ///
    public var osMessage:   String {
        switch self {
            case .ACCES:          return StrError(EACCES)          /* Permission denied                               */
            case .ADDRINUSE:      return StrError(EADDRINUSE)      /* Address already in use                          */
            case .ADDRNOTAVAIL:   return StrError(EADDRNOTAVAIL)   /* Can't assign requested address                  */
            case .AFNOSUPPORT:    return StrError(EAFNOSUPPORT)    /* Address family not supported by protocol family */
            case .AGAIN:          return StrError(EAGAIN)          /* Resource temporarily unavailable                */
            case .ALREADY:        return StrError(EALREADY)        /* Operation already in progress                   */
            case .BADF:           return StrError(EBADF)           /* Bad file descriptor                             */
            case .BADMSG:         return StrError(EBADMSG)         /* Bad message                                     */
            case .BUSY:           return StrError(EBUSY)           /* Device / Resource busy                          */
            case .CANCELED:       return StrError(ECANCELED)       /* Operation canceled                              */
            case .CHILD:          return StrError(ECHILD)          /* No child processes                              */
            case .CONNABORTED:    return StrError(ECONNABORTED)    /* Software caused connection abort                */
            case .CONNREFUSED:    return StrError(ECONNREFUSED)    /* Connection refused                              */
            case .CONNRESET:      return StrError(ECONNRESET)      /* Connection reset by peer                        */
            case .DEADLK:         return StrError(EDEADLK)         /* Resource deadlock avoided                       */
            case .DESTADDRREQ:    return StrError(EDESTADDRREQ)    /* Destination address required                    */
            case .DOM:            return StrError(EDOM)            /* Numerical argument out of domain                */
            case .DQUOT:          return StrError(EDQUOT)          /* Disc quota exceeded                             */
            case .EXIST:          return StrError(EEXIST)          /* File exists                                     */
            case .FAULT:          return StrError(EFAULT)          /* Bad address                                     */
            case .FBIG:           return StrError(EFBIG)           /* File too large                                  */
            case .HOSTDOWN:       return StrError(EHOSTDOWN)       /* Host is down                                    */
            case .HOSTUNREACH:    return StrError(EHOSTUNREACH)    /* No route to host                                */
            case .IDRM:           return StrError(EIDRM)           /* Identifier removed                              */
            case .ILSEQ:          return StrError(EILSEQ)          /* Illegal byte sequence                           */
            case .INPROGRESS:     return StrError(EINPROGRESS)     /* Operation now in progress                       */
            case .INTR:           return StrError(EINTR)           /* Interrupted system call                         */
            case .INVAL:          return StrError(EINVAL)          /* Invalid argument                                */
            case .IO:             return StrError(EIO)             /* Input/output error                              */
            case .ISCONN:         return StrError(EISCONN)         /* Socket is already connected                     */
            case .ISDIR:          return StrError(EISDIR)          /* Is a directory                                  */
            case .LOOP:           return StrError(ELOOP)           /* Too many levels of symbolic links               */
            case .MFILE:          return StrError(EMFILE)          /* Too many open files                             */
            case .MLINK:          return StrError(EMLINK)          /* Too many links                                  */
            case .MSGSIZE:        return StrError(EMSGSIZE)        /* Message too long                                */
            case .MULTIHOP:       return StrError(EMULTIHOP)       /* Reserved                                        */
            case .NAMETOOLONG:    return StrError(ENAMETOOLONG)    /* File name too long                              */
            case .NETDOWN:        return StrError(ENETDOWN)        /* Network is down                                 */
            case .NETRESET:       return StrError(ENETRESET)       /* Network dropped connection on reset             */
            case .NETUNREACH:     return StrError(ENETUNREACH)     /* Network is unreachable                          */
            case .NFILE:          return StrError(ENFILE)          /* Too many open files in system                   */
            case .NOBUFS:         return StrError(ENOBUFS)         /* No buffer space available                       */
            case .NODATA:         return StrError(ENODATA)         /* No message available on STREAM                  */
            case .NODEV:          return StrError(ENODEV)          /* Operation not supported by device               */
            case .NOENT:          return StrError(ENOENT)          /* No such file or directory                       */
            case .NOEXEC:         return StrError(ENOEXEC)         /* Exec format error                               */
            case .NOLCK:          return StrError(ENOLCK)          /* No locks available                              */
            case .NOLINK:         return StrError(ENOLINK)         /* Reserved                                        */
            case .NOMEM:          return StrError(ENOMEM)          /* Cannot allocate memory                          */
            case .NOMSG:          return StrError(ENOMSG)          /* No message of desired type                      */
            case .NOPROTOOPT:     return StrError(ENOPROTOOPT)     /* Protocol not available                          */
            case .NOSPC:          return StrError(ENOSPC)          /* No space left on device                         */
            case .NOSR:           return StrError(ENOSR)           /* No STREAM resources                             */
            case .NOSTR:          return StrError(ENOSTR)          /* Not a STREAM                                    */
            case .NOSYS:          return StrError(ENOSYS)          /* Function not implemented                        */
            case .NOTBLK:         return StrError(ENOTBLK)         /* Block device required                           */
            case .NOTCONN:        return StrError(ENOTCONN)        /* Socket is not connected                         */
            case .NOTDIR:         return StrError(ENOTDIR)         /* Not a directory                                 */
            case .NOTEMPTY:       return StrError(ENOTEMPTY)       /* Directory not empty                             */
            case .NOTRECOVERABLE: return StrError(ENOTRECOVERABLE) /* State not recoverable                           */
            case .NOTSOCK:        return StrError(ENOTSOCK)        /* Socket operation on non-socket                  */
            case .NOTSUP:         return StrError(ENOTSUP)         /* Operation not supported                         */
            case .NOTTY:          return StrError(ENOTTY)          /* Inappropriate ioctl for device                  */
            case .NXIO:           return StrError(ENXIO)           /* Device not configured                           */
            case .OPNOTSUPP:      return StrError(EOPNOTSUPP)      /* Operation not supported on socket               */
            case .OVERFLOW:       return StrError(EOVERFLOW)       /* Value too large to be stored in data type       */
            case .OWNERDEAD:      return StrError(EOWNERDEAD)      /* Previous owner died                             */
            case .PERM:           return StrError(EPERM)           /* Operation not permitted                         */
            case .PFNOSUPPORT:    return StrError(EPFNOSUPPORT)    /* Protocol family not supported                   */
            case .PIPE:           return StrError(EPIPE)           /* Broken pipe                                     */
            case .PROTO:          return StrError(EPROTO)          /* Protocol error                                  */
            case .PROTONOSUPPORT: return StrError(EPROTONOSUPPORT) /* Protocol not supported                          */
            case .PROTOTYPE:      return StrError(EPROTOTYPE)      /* Protocol wrong type for socket                  */
            case .RANGE:          return StrError(ERANGE)          /* Result too large                                */
            case .REMOTE:         return StrError(EREMOTE)         /* Too many levels of remote in path               */
            case .ROFS:           return StrError(EROFS)           /* Read-only file system                           */
            case .SHUTDOWN:       return StrError(ESHUTDOWN)       /* Can't send after socket shutdown                */
            case .SOCKTNOSUPPORT: return StrError(ESOCKTNOSUPPORT) /* Socket type not supported                       */
            case .SPIPE:          return StrError(ESPIPE)          /* Illegal seek                                    */
            case .SRCH:           return StrError(ESRCH)           /* No such process                                 */
            case .STALE:          return StrError(ESTALE)          /* Stale NFS file handle                           */
            case .TIME:           return StrError(ETIME)           /* STREAM ioctl timeout                            */
            case .TIMEDOUT:       return StrError(ETIMEDOUT)       /* Operation timed out                             */
            case .TOBIG:          return StrError(E2BIG)           /* Argument list too long                          */
            case .TOOMANYREFS:    return StrError(ETOOMANYREFS)    /* Too many references: can't splice               */
            case .TXTBSY:         return StrError(ETXTBSY)         /* Text file busy                                  */
            case .USERS:          return StrError(EUSERS)          /* Too many users                                  */
            case .WOULDBLOCK:     return StrError(EWOULDBLOCK)     /* Operation would block                           */
            case .XDEV:           return StrError(EXDEV)           /* Cross-device link                               */
            default: break
        }

        #if os(macOS) || os(tvOS) || os(iOS) || os(watchOS)
            // These only exist on Apple OS'.
            switch self {
                case .AUTH:           return StrError(EAUTH)           /* Authentication error                            */
                case .BADARCH:        return StrError(EBADARCH)        /* Bad CPU type in executable                      */
                case .BADEXEC:        return StrError(EBADEXEC)        /* Bad executable                                  */
                case .BADMACHO:       return StrError(EBADMACHO)       /* Malformed Macho file                            */
                case .BADRPC:         return StrError(EBADRPC)         /* RPC struct is bad                               */
                case .DEVERR:         return StrError(EDEVERR)         /* Device error, e.g. paper out                    */
                case .FTYPE:          return StrError(EFTYPE)          /* Inappropriate file type or format               */
                case .LAST:           return StrError(ELAST)           /* Must be equal largest errno                     */
                case .NEEDAUTH:       return StrError(ENEEDAUTH)       /* Need authenticator                              */
                case .NOATTR:         return StrError(ENOATTR)         /* Attribute not found                             */
                case .NOPOLICY:       return StrError(ENOPOLICY)       /* No such policy registered                       */
                case .PROCLIM:        return StrError(EPROCLIM)        /* Too many processes                              */
                case .PROCUNAVAIL:    return StrError(EPROCUNAVAIL)    /* Bad procedure for program                       */
                case .PROGMISMATCH:   return StrError(EPROGMISMATCH)   /* Program version wrong                           */
                case .PROGUNAVAIL:    return StrError(EPROGUNAVAIL)    /* RPC prog. not avail                             */
                case .PWROFF:         return StrError(EPWROFF)         /* Device power is off                             */
                case .QFULL:          return StrError(EQFULL)          /* Interface output queue is full                  */
                case .RPCMISMATCH:    return StrError(ERPCMISMATCH)    /* RPC version wrong                               */
                case .SHLIBVERS:      return StrError(ESHLIBVERS)      /* Shared library version mismatch                 */
                default: break
            }
        #endif

        #if os(Linux)
            // These only exist on Linux.
            switch self {
                case .ADV:         return StrError(EADV)         /* Advertise error                                 */
                case .BADE:        return StrError(EBADE)        /* Invalid exchange                                */
                case .BADFD:       return StrError(EBADFD)       /* File descriptor in bad state                    */
                case .BADR:        return StrError(EBADR)        /* Invalid request descriptor                      */
                case .BADRQC:      return StrError(EBADRQC)      /* Invalid request code                            */
                case .BADSLT:      return StrError(EBADSLT)      /* Invalid slot                                    */
                case .BFONT:       return StrError(EBFONT)       /* Bad font file format                            */
                case .CHRNG:       return StrError(ECHRNG)       /* Channel number out of range                     */
                case .COMM:        return StrError(ECOMM)        /* Communication error on send                     */
                case .DEADLOCK:    return StrError(EDEADLOCK)    /* Resource deadlock avoided                       */
                case .DOTDOT:      return StrError(EDOTDOT)      /* RFS specific error                              */
                case .HWPOISON:    return StrError(EHWPOISON)    /* Memory page has hardware error                  */
                case .ISNAM:       return StrError(EISNAM)       /* Is a named type file                            */
                case .KEYEXPIRED:  return StrError(EKEYEXPIRED)  /* Key has expired                                 */
                case .KEYREJECTED: return StrError(EKEYREJECTED) /* Key was rejected by service                     */
                case .KEYREVOKED:  return StrError(EKEYREVOKED)  /* Key has been revoked                            */
                case .L2HLT:       return StrError(EL2HLT)       /* Level 2 halted                                  */
                case .L2NSYNC:     return StrError(EL2NSYNC)     /* Level 2 not synchronized                        */
                case .L3HLT:       return StrError(EL3HLT)       /* Level 3 halted                                  */
                case .L3RST:       return StrError(EL3RST)       /* Level 3 reset                                   */
                case .LIBACC:      return StrError(ELIBACC)      /* Can not access a needed shared library          */
                case .LIBBAD:      return StrError(ELIBBAD)      /* Accessing a corrupted shared library            */
                case .LIBEXEC:     return StrError(ELIBEXEC)     /* Cannot exec a shared library directly           */
                case .LIBMAX:      return StrError(ELIBMAX)      /* Attempting to link in too many shared libraries */
                case .LIBSCN:      return StrError(ELIBSCN)      /* .lib section in a.out corrupted                 */
                case .LNRNG:       return StrError(ELNRNG)       /* Link number out of range                        */
                case .MEDIUMTYPE:  return StrError(EMEDIUMTYPE)  /* Wrong medium type                               */
                case .NAVAIL:      return StrError(ENAVAIL)      /* No XENIX semaphores available                   */
                case .NOANO:       return StrError(ENOANO)       /* No anode                                        */
                case .NOCSI:       return StrError(ENOCSI)       /* No CSI structure available                      */
                case .NOKEY:       return StrError(ENOKEY)       /* Required key not available                      */
                case .NOMEDIUM:    return StrError(ENOMEDIUM)    /* No medium found                                 */
                case .NONET:       return StrError(ENONET)       /* Machine is not on the network                   */
                case .NOPKG:       return StrError(ENOPKG)       /* Package not installed                           */
                case .NOTNAM:      return StrError(ENOTNAM)      /* Not a XENIX named type file                     */
                case .NOTUNIQ:     return StrError(ENOTUNIQ)     /* Name not unique on network                      */
                case .REMCHG:      return StrError(EREMCHG)      /* Remote address changed                          */
                case .REMOTEIO:    return StrError(EREMOTEIO)    /* Remote I/O error                                */
                case .RESTART:     return StrError(ERESTART)     /* Interrupted system call should be restarted     */
                case .RFKILL:      return StrError(ERFKILL)      /* Operation not possible due to RF-kill           */
                case .SRMNT:       return StrError(ESRMNT)       /* Srmount error                                   */
                case .STRPIPE:     return StrError(ESTRPIPE)     /* Streams pipe error                              */
                case .UCLEAN:      return StrError(EUCLEAN)      /* Structure needs cleaning                        */
                case .UNATCH:      return StrError(EUNATCH)      /* Protocol driver not attached                    */
                case .XFULL:       return StrError(EXFULL)       /* Exchange full                                   */
                default: break
            }
        #endif

        return "\(errorCode): Unknown Error"
    }

    /*==========================================================================================================*/
    /// The numeric code of the error.
    ///
    public var errorCode:   Int32 {
        switch self {
            case .ACCES:          return EACCES          /* Permission denied                               */
            case .ADDRINUSE:      return EADDRINUSE      /* Address already in use                          */
            case .ADDRNOTAVAIL:   return EADDRNOTAVAIL   /* Can't assign requested address                  */
            case .AFNOSUPPORT:    return EAFNOSUPPORT    /* Address family not supported by protocol family */
            case .AGAIN:          return EAGAIN          /* Resource temporarily unavailable                */
            case .ALREADY:        return EALREADY        /* Operation already in progress                   */
            case .BADF:           return EBADF           /* Bad file descriptor                             */
            case .BADMSG:         return EBADMSG         /* Bad message                                     */
            case .BUSY:           return EBUSY           /* Device / Resource busy                          */
            case .CANCELED:       return ECANCELED       /* Operation canceled                              */
            case .CHILD:          return ECHILD          /* No child processes                              */
            case .CONNABORTED:    return ECONNABORTED    /* Software caused connection abort                */
            case .CONNREFUSED:    return ECONNREFUSED    /* Connection refused                              */
            case .CONNRESET:      return ECONNRESET      /* Connection reset by peer                        */
            case .DEADLK:         return EDEADLK         /* Resource deadlock avoided                       */
            case .DESTADDRREQ:    return EDESTADDRREQ    /* Destination address required                    */
            case .DOM:            return EDOM            /* Numerical argument out of domain                */
            case .DQUOT:          return EDQUOT          /* Disc quota exceeded                             */
            case .EXIST:          return EEXIST          /* File exists                                     */
            case .FAULT:          return EFAULT          /* Bad address                                     */
            case .FBIG:           return EFBIG           /* File too large                                  */
            case .HOSTDOWN:       return EHOSTDOWN       /* Host is down                                    */
            case .HOSTUNREACH:    return EHOSTUNREACH    /* No route to host                                */
            case .IDRM:           return EIDRM           /* Identifier removed                              */
            case .ILSEQ:          return EILSEQ          /* Illegal byte sequence                           */
            case .INPROGRESS:     return EINPROGRESS     /* Operation now in progress                       */
            case .INTR:           return EINTR           /* Interrupted system call                         */
            case .INVAL:          return EINVAL          /* Invalid argument                                */
            case .IO:             return EIO             /* Input/output error                              */
            case .ISCONN:         return EISCONN         /* Socket is already connected                     */
            case .ISDIR:          return EISDIR          /* Is a directory                                  */
            case .LOOP:           return ELOOP           /* Too many levels of symbolic links               */
            case .MFILE:          return EMFILE          /* Too many open files                             */
            case .MLINK:          return EMLINK          /* Too many links                                  */
            case .MSGSIZE:        return EMSGSIZE        /* Message too long                                */
            case .MULTIHOP:       return EMULTIHOP       /* Reserved                                        */
            case .NAMETOOLONG:    return ENAMETOOLONG    /* File name too long                              */
            case .NETDOWN:        return ENETDOWN        /* Network is down                                 */
            case .NETRESET:       return ENETRESET       /* Network dropped connection on reset             */
            case .NETUNREACH:     return ENETUNREACH     /* Network is unreachable                          */
            case .NFILE:          return ENFILE          /* Too many open files in system                   */
            case .NOBUFS:         return ENOBUFS         /* No buffer space available                       */
            case .NODATA:         return ENODATA         /* No message available on STREAM                  */
            case .NODEV:          return ENODEV          /* Operation not supported by device               */
            case .NOENT:          return ENOENT          /* No such file or directory                       */
            case .NOEXEC:         return ENOEXEC         /* Exec format error                               */
            case .NOLCK:          return ENOLCK          /* No locks available                              */
            case .NOLINK:         return ENOLINK         /* Reserved                                        */
            case .NOMEM:          return ENOMEM          /* Cannot allocate memory                          */
            case .NOMSG:          return ENOMSG          /* No message of desired type                      */
            case .NOPROTOOPT:     return ENOPROTOOPT     /* Protocol not available                          */
            case .NOSPC:          return ENOSPC          /* No space left on device                         */
            case .NOSR:           return ENOSR           /* No STREAM resources                             */
            case .NOSTR:          return ENOSTR          /* Not a STREAM                                    */
            case .NOSYS:          return ENOSYS          /* Function not implemented                        */
            case .NOTBLK:         return ENOTBLK         /* Block device required                           */
            case .NOTCONN:        return ENOTCONN        /* Socket is not connected                         */
            case .NOTDIR:         return ENOTDIR         /* Not a directory                                 */
            case .NOTEMPTY:       return ENOTEMPTY       /* Directory not empty                             */
            case .NOTRECOVERABLE: return ENOTRECOVERABLE /* State not recoverable                           */
            case .NOTSOCK:        return ENOTSOCK        /* Socket operation on non-socket                  */
            case .NOTSUP:         return ENOTSUP         /* Operation not supported                         */
            case .NOTTY:          return ENOTTY          /* Inappropriate ioctl for device                  */
            case .NXIO:           return ENXIO           /* Device not configured                           */
            case .OPNOTSUPP:      return EOPNOTSUPP      /* Operation not supported on socket               */
            case .OVERFLOW:       return EOVERFLOW       /* Value too large to be stored in data type       */
            case .OWNERDEAD:      return EOWNERDEAD      /* Previous owner died                             */
            case .PERM:           return EPERM           /* Operation not permitted                         */
            case .PFNOSUPPORT:    return EPFNOSUPPORT    /* Protocol family not supported                   */
            case .PIPE:           return EPIPE           /* Broken pipe                                     */
            case .PROTO:          return EPROTO          /* Protocol error                                  */
            case .PROTONOSUPPORT: return EPROTONOSUPPORT /* Protocol not supported                          */
            case .PROTOTYPE:      return EPROTOTYPE      /* Protocol wrong type for socket                  */
            case .RANGE:          return ERANGE          /* Result too large                                */
            case .REMOTE:         return EREMOTE         /* Too many levels of remote in path               */
            case .ROFS:           return EROFS           /* Read-only file system                           */
            case .SHUTDOWN:       return ESHUTDOWN       /* Can't send after socket shutdown                */
            case .SOCKTNOSUPPORT: return ESOCKTNOSUPPORT /* Socket type not supported                       */
            case .SPIPE:          return ESPIPE          /* Illegal seek                                    */
            case .SRCH:           return ESRCH           /* No such process                                 */
            case .STALE:          return ESTALE          /* Stale NFS file handle                           */
            case .TIME:           return ETIME           /* STREAM ioctl timeout                            */
            case .TIMEDOUT:       return ETIMEDOUT       /* Operation timed out                             */
            case .TOBIG:          return E2BIG           /* Argument list too long                          */
            case .TOOMANYREFS:    return ETOOMANYREFS    /* Too many references: can't splice               */
            case .TXTBSY:         return ETXTBSY         /* Text file busy                                  */
            case .USERS:          return EUSERS          /* Too many users                                  */
            case .WOULDBLOCK:     return EWOULDBLOCK     /* Operation would block                           */
            case .XDEV:           return EXDEV           /* Cross-device link                               */
            default: break
        }

        #if os(macOS) || os(tvOS) || os(iOS) || os(watchOS)
            // These only exist on Apple OS'.
            switch self {
                case .AUTH:           return EAUTH           /* Authentication error                            */
                case .BADARCH:        return EBADARCH        /* Bad CPU type in executable                      */
                case .BADEXEC:        return EBADEXEC        /* Bad executable                                  */
                case .BADMACHO:       return EBADMACHO       /* Malformed Macho file                            */
                case .BADRPC:         return EBADRPC         /* RPC struct is bad                               */
                case .DEVERR:         return EDEVERR         /* Device error, e.g. paper out                    */
                case .FTYPE:          return EFTYPE          /* Inappropriate file type or format               */
                case .LAST:           return ELAST           /* Must be equal largest errno                     */
                case .NEEDAUTH:       return ENEEDAUTH       /* Need authenticator                              */
                case .NOATTR:         return ENOATTR         /* Attribute not found                             */
                case .NOPOLICY:       return ENOPOLICY       /* No such policy registered                       */
                case .PROCLIM:        return EPROCLIM        /* Too many processes                              */
                case .PROCUNAVAIL:    return EPROCUNAVAIL    /* Bad procedure for program                       */
                case .PROGMISMATCH:   return EPROGMISMATCH   /* Program version wrong                           */
                case .PROGUNAVAIL:    return EPROGUNAVAIL    /* RPC prog. not avail                             */
                case .PWROFF:         return EPWROFF         /* Device power is off                             */
                case .QFULL:          return EQFULL          /* Interface output queue is full                  */
                case .RPCMISMATCH:    return ERPCMISMATCH    /* RPC version wrong                               */
                case .SHLIBVERS:      return ESHLIBVERS      /* Shared library version mismatch                 */
                default: break
            }
        #endif

        #if os(Linux)
            // These only exist on Linux.
            switch self {
                case .ADV:         return EADV         /* Advertise error                                 */
                case .BADE:        return EBADE        /* Invalid exchange                                */
                case .BADFD:       return EBADFD       /* File descriptor in bad state                    */
                case .BADR:        return EBADR        /* Invalid request descriptor                      */
                case .BADRQC:      return EBADRQC      /* Invalid request code                            */
                case .BADSLT:      return EBADSLT      /* Invalid slot                                    */
                case .BFONT:       return EBFONT       /* Bad font file format                            */
                case .CHRNG:       return ECHRNG       /* Channel number out of range                     */
                case .COMM:        return ECOMM        /* Communication error on send                     */
                case .DEADLOCK:    return EDEADLOCK    /* Resource deadlock avoided                       */
                case .DOTDOT:      return EDOTDOT      /* RFS specific error                              */
                case .HWPOISON:    return EHWPOISON    /* Memory page has hardware error                  */
                case .ISNAM:       return EISNAM       /* Is a named type file                            */
                case .KEYEXPIRED:  return EKEYEXPIRED  /* Key has expired                                 */
                case .KEYREJECTED: return EKEYREJECTED /* Key was rejected by service                     */
                case .KEYREVOKED:  return EKEYREVOKED  /* Key has been revoked                            */
                case .L2HLT:       return EL2HLT       /* Level 2 halted                                  */
                case .L2NSYNC:     return EL2NSYNC     /* Level 2 not synchronized                        */
                case .L3HLT:       return EL3HLT       /* Level 3 halted                                  */
                case .L3RST:       return EL3RST       /* Level 3 reset                                   */
                case .LIBACC:      return ELIBACC      /* Can not access a needed shared library          */
                case .LIBBAD:      return ELIBBAD      /* Accessing a corrupted shared library            */
                case .LIBEXEC:     return ELIBEXEC     /* Cannot exec a shared library directly           */
                case .LIBMAX:      return ELIBMAX      /* Attempting to link in too many shared libraries */
                case .LIBSCN:      return ELIBSCN      /* .lib section in a.out corrupted                 */
                case .LNRNG:       return ELNRNG       /* Link number out of range                        */
                case .MEDIUMTYPE:  return EMEDIUMTYPE  /* Wrong medium type                               */
                case .NAVAIL:      return ENAVAIL      /* No XENIX semaphores available                   */
                case .NOANO:       return ENOANO       /* No anode                                        */
                case .NOCSI:       return ENOCSI       /* No CSI structure available                      */
                case .NOKEY:       return ENOKEY       /* Required key not available                      */
                case .NOMEDIUM:    return ENOMEDIUM    /* No medium found                                 */
                case .NONET:       return ENONET       /* Machine is not on the network                   */
                case .NOPKG:       return ENOPKG       /* Package not installed                           */
                case .NOTNAM:      return ENOTNAM      /* Not a XENIX named type file                     */
                case .NOTUNIQ:     return ENOTUNIQ     /* Name not unique on network                      */
                case .REMCHG:      return EREMCHG      /* Remote address changed                          */
                case .REMOTEIO:    return EREMOTEIO    /* Remote I/O error                                */
                case .RESTART:     return ERESTART     /* Interrupted system call should be restarted     */
                case .RFKILL:      return ERFKILL      /* Operation not possible due to RF-kill           */
                case .SRMNT:       return ESRMNT       /* Srmount error                                   */
                case .STRPIPE:     return ESTRPIPE     /* Streams pipe error                              */
                case .UCLEAN:      return EUCLEAN      /* Structure needs cleaning                        */
                case .UNATCH:      return EUNATCH      /* Protocol driver not attached                    */
                case .XFULL:       return EXFULL       /* Exchange full                                   */
                default: break
            }
        #endif

        return -1
    }

    /*==========================================================================================================*/
    /// The description provided when the error was created.
    ///
    public var description: String {
        switch self {
            case .ACCES(         description: let desc): return desc /* Permission denied                               */
            case .ADDRINUSE(     description: let desc): return desc /* Address already in use                          */
            case .ADDRNOTAVAIL(  description: let desc): return desc /* Can't assign requested address                  */
            case .AFNOSUPPORT(   description: let desc): return desc /* Address family not supported by protocol family */
            case .AGAIN(         description: let desc): return desc /* Resource temporarily unavailable                */
            case .ALREADY(       description: let desc): return desc /* Operation already in progress                   */
            case .BADF(          description: let desc): return desc /* Bad file descriptor                             */
            case .BADMSG(        description: let desc): return desc /* Bad message                                     */
            case .BUSY(          description: let desc): return desc /* Device / Resource busy                          */
            case .CANCELED(      description: let desc): return desc /* Operation canceled                              */
            case .CHILD(         description: let desc): return desc /* No child processes                              */
            case .CONNABORTED(   description: let desc): return desc /* Software caused connection abort                */
            case .CONNREFUSED(   description: let desc): return desc /* Connection refused                              */
            case .CONNRESET(     description: let desc): return desc /* Connection reset by peer                        */
            case .DEADLK(        description: let desc): return desc /* Resource deadlock avoided                       */
            case .DESTADDRREQ(   description: let desc): return desc /* Destination address required                    */
            case .DOM(           description: let desc): return desc /* Numerical argument out of domain                */
            case .DQUOT(         description: let desc): return desc /* Disc quota exceeded                             */
            case .EXIST(         description: let desc): return desc /* File exists                                     */
            case .FAULT(         description: let desc): return desc /* Bad address                                     */
            case .FBIG(          description: let desc): return desc /* File too large                                  */
            case .HOSTDOWN(      description: let desc): return desc /* Host is down                                    */
            case .HOSTUNREACH(   description: let desc): return desc /* No route to host                                */
            case .IDRM(          description: let desc): return desc /* Identifier removed                              */
            case .ILSEQ(         description: let desc): return desc /* Illegal byte sequence                           */
            case .INPROGRESS(    description: let desc): return desc /* Operation now in progress                       */
            case .INTR(          description: let desc): return desc /* Interrupted system call                         */
            case .INVAL(         description: let desc): return desc /* Invalid argument                                */
            case .IO(            description: let desc): return desc /* Input/output error                              */
            case .ISCONN(        description: let desc): return desc /* Socket is already connected                     */
            case .ISDIR(         description: let desc): return desc /* Is a directory                                  */
            case .LOOP(          description: let desc): return desc /* Too many levels of symbolic links               */
            case .MFILE(         description: let desc): return desc /* Too many open files                             */
            case .MLINK(         description: let desc): return desc /* Too many links                                  */
            case .MSGSIZE(       description: let desc): return desc /* Message too long                                */
            case .MULTIHOP(      description: let desc): return desc /* Reserved                                        */
            case .NAMETOOLONG(   description: let desc): return desc /* File name too long                              */
            case .NETDOWN(       description: let desc): return desc /* Network is down                                 */
            case .NETRESET(      description: let desc): return desc /* Network dropped connection on reset             */
            case .NETUNREACH(    description: let desc): return desc /* Network is unreachable                          */
            case .NFILE(         description: let desc): return desc /* Too many open files in system                   */
            case .NOBUFS(        description: let desc): return desc /* No buffer space available                       */
            case .NODATA(        description: let desc): return desc /* No message available on STREAM                  */
            case .NODEV(         description: let desc): return desc /* Operation not supported by device               */
            case .NOENT(         description: let desc): return desc /* No such file or directory                       */
            case .NOEXEC(        description: let desc): return desc /* Exec format error                               */
            case .NOLCK(         description: let desc): return desc /* No locks available                              */
            case .NOLINK(        description: let desc): return desc /* Reserved                                        */
            case .NOMEM(         description: let desc): return desc /* Cannot allocate memory                          */
            case .NOMSG(         description: let desc): return desc /* No message of desired type                      */
            case .NOPROTOOPT(    description: let desc): return desc /* Protocol not available                          */
            case .NOSPC(         description: let desc): return desc /* No space left on device                         */
            case .NOSR(          description: let desc): return desc /* No STREAM resources                             */
            case .NOSTR(         description: let desc): return desc /* Not a STREAM                                    */
            case .NOSYS(         description: let desc): return desc /* Function not implemented                        */
            case .NOTBLK(        description: let desc): return desc /* Block device required                           */
            case .NOTCONN(       description: let desc): return desc /* Socket is not connected                         */
            case .NOTDIR(        description: let desc): return desc /* Not a directory                                 */
            case .NOTEMPTY(      description: let desc): return desc /* Directory not empty                             */
            case .NOTRECOVERABLE(description: let desc): return desc /* State not recoverable                           */
            case .NOTSOCK(       description: let desc): return desc /* Socket operation on non-socket                  */
            case .NOTSUP(        description: let desc): return desc /* Operation not supported                         */
            case .NOTTY(         description: let desc): return desc /* Inappropriate ioctl for device                  */
            case .NXIO(          description: let desc): return desc /* Device not configured                           */
            case .OPNOTSUPP(     description: let desc): return desc /* Operation not supported on socket               */
            case .OVERFLOW(      description: let desc): return desc /* Value too large to be stored in data type       */
            case .OWNERDEAD(     description: let desc): return desc /* Previous owner died                             */
            case .PERM(          description: let desc): return desc /* Operation not permitted                         */
            case .PFNOSUPPORT(   description: let desc): return desc /* Protocol family not supported                   */
            case .PIPE(          description: let desc): return desc /* Broken pipe                                     */
            case .PROTO(         description: let desc): return desc /* Protocol error                                  */
            case .PROTONOSUPPORT(description: let desc): return desc /* Protocol not supported                          */
            case .PROTOTYPE(     description: let desc): return desc /* Protocol wrong type for socket                  */
            case .RANGE(         description: let desc): return desc /* Result too large                                */
            case .REMOTE(        description: let desc): return desc /* Too many levels of remote in path               */
            case .ROFS(          description: let desc): return desc /* Read-only file system                           */
            case .SHUTDOWN(      description: let desc): return desc /* Can't send after socket shutdown                */
            case .SOCKTNOSUPPORT(description: let desc): return desc /* Socket type not supported                       */
            case .SPIPE(         description: let desc): return desc /* Illegal seek                                    */
            case .SRCH(          description: let desc): return desc /* No such process                                 */
            case .STALE(         description: let desc): return desc /* Stale NFS file handle                           */
            case .TIME(          description: let desc): return desc /* STREAM ioctl timeout                            */
            case .TIMEDOUT(      description: let desc): return desc /* Operation timed out                             */
            case .TOBIG(         description: let desc): return desc /* Argument list too long                          */
            case .TOOMANYREFS(   description: let desc): return desc /* Too many references: can't splice               */
            case .TXTBSY(        description: let desc): return desc /* Text file busy                                  */
            case .USERS(         description: let desc): return desc /* Too many users                                  */
            case .WOULDBLOCK(    description: let desc): return desc /* Operation would block                           */
            case .XDEV(          description: let desc): return desc /* Cross-device link                               */
            default: break
        }

        #if os(macOS) || os(tvOS) || os(iOS) || os(watchOS)
            // These only exist on Apple OS'.
            switch self {
                case .AUTH(          description: let desc): return desc /* Authentication error                            */
                case .BADARCH(       description: let desc): return desc /* Bad CPU type in executable                      */
                case .BADEXEC(       description: let desc): return desc /* Bad executable                                  */
                case .BADRPC(        description: let desc): return desc /* RPC struct is bad                               */
                case .DEVERR(        description: let desc): return desc /* Device error, e.g. paper out                    */
                case .FTYPE(         description: let desc): return desc /* Inappropriate file type or format               */
                case .LAST(          description: let desc): return desc /* Must be equal largest errno                     */
                case .NEEDAUTH(      description: let desc): return desc /* Need authenticator                              */
                case .NOATTR(        description: let desc): return desc /* Attribute not found                             */
                case .NOPOLICY(      description: let desc): return desc /* No such policy registered                       */
                case .PROCLIM(       description: let desc): return desc /* Too many processes                              */
                case .PROCUNAVAIL(   description: let desc): return desc /* Bad procedure for program                       */
                case .PROGMISMATCH(  description: let desc): return desc /* Program version wrong                           */
                case .PROGUNAVAIL(   description: let desc): return desc /* RPC prog. not avail                             */
                case .PWROFF(        description: let desc): return desc /* Device power is off                             */
                case .QFULL(         description: let desc): return desc /* Interface output queue is full                  */
                case .RPCMISMATCH(   description: let desc): return desc /* RPC version wrong                               */
                case .SHLIBVERS(     description: let desc): return desc /* Shared library version mismatch                 */
                default: break
            }
        #endif

        #if os(Linux)
            // These only exist on Linux.
            switch self {
                case .ADV(        description: let desc): return desc /* Advertise error                                 */
                case .BADE(       description: let desc): return desc /* Invalid exchange                                */
                case .BADFD(      description: let desc): return desc /* File descriptor in bad state                    */
                case .BADR(       description: let desc): return desc /* Invalid request descriptor                      */
                case .BADRQC(     description: let desc): return desc /* Invalid request code                            */
                case .BADSLT(     description: let desc): return desc /* Invalid slot                                    */
                case .BFONT(      description: let desc): return desc /* Bad font file format                            */
                case .CHRNG(      description: let desc): return desc /* Channel number out of range                     */
                case .COMM(       description: let desc): return desc /* Communication error on send                     */
                case .DEADLOCK(   description: let desc): return desc /* Resource deadlock avoided                       */
                case .DOTDOT(     description: let desc): return desc /* RFS specific error                              */
                case .HWPOISON(   description: let desc): return desc /* Memory page has hardware error                  */
                case .ISNAM(      description: let desc): return desc /* Is a named type file                            */
                case .KEYEXPIRED( description: let desc): return desc /* Key has expired                                 */
                case .KEYREJECTED(description: let desc): return desc /* Key was rejected by service                     */
                case .KEYREVOKED( description: let desc): return desc /* Key has been revoked                            */
                case .L2HLT(      description: let desc): return desc /* Level 2 halted                                  */
                case .L2NSYNC(    description: let desc): return desc /* Level 2 not synchronized                        */
                case .L3HLT(      description: let desc): return desc /* Level 3 halted                                  */
                case .L3RST(      description: let desc): return desc /* Level 3 reset                                   */
                case .LIBACC(     description: let desc): return desc /* Can not access a needed shared library          */
                case .LIBBAD(     description: let desc): return desc /* Accessing a corrupted shared library            */
                case .LIBEXEC(    description: let desc): return desc /* Cannot exec a shared library directly           */
                case .LIBMAX(     description: let desc): return desc /* Attempting to link in too many shared libraries */
                case .LIBSCN(     description: let desc): return desc /* .lib section in a.out corrupted                 */
                case .LNRNG(      description: let desc): return desc /* Link number out of range                        */
                case .MEDIUMTYPE( description: let desc): return desc /* Wrong medium type                               */
                case .NAVAIL(     description: let desc): return desc /* No XENIX semaphores available                   */
                case .NOANO(      description: let desc): return desc /* No anode                                        */
                case .NOCSI(      description: let desc): return desc /* No CSI structure available                      */
                case .NOKEY(      description: let desc): return desc /* Required key not available                      */
                case .NOMEDIUM(   description: let desc): return desc /* No medium found                                 */
                case .NONET(      description: let desc): return desc /* Machine is not on the network                   */
                case .NOPKG(      description: let desc): return desc /* Package not installed                           */
                case .NOTNAM(     description: let desc): return desc /* Not a XENIX named type file                     */
                case .NOTUNIQ(    description: let desc): return desc /* Name not unique on network                      */
                case .REMCHG(     description: let desc): return desc /* Remote address changed                          */
                case .REMOTEIO(   description: let desc): return desc /* Remote I/O error                                */
                case .RESTART(    description: let desc): return desc /* Interrupted system call should be restarted     */
                case .RFKILL(     description: let desc): return desc /* Operation not possible due to RF-kill           */
                case .SRMNT(      description: let desc): return desc /* Srmount error                                   */
                case .STRPIPE(    description: let desc): return desc /* Streams pipe error                              */
                case .UCLEAN(     description: let desc): return desc /* Structure needs cleaning                        */
                case .UNATCH(     description: let desc): return desc /* Protocol driver not attached                    */
                case .XFULL(      description: let desc): return desc /* Exchange full                                   */
                default: break
            }
        #endif

        return "Unknown Error"
    }

    /*==========================================================================================================*/
    /// Returns the error for the given code.
    /// 
    /// - Parameter code: the OS error code.
    /// - Returns: The matching error.
    ///
    public static func getErrorFor(code: Int32) -> CErrors {
        switch code {
            case EACCES:          return CErrors.ACCES()          /* Permission denied                               */
            case EADDRINUSE:      return CErrors.ADDRINUSE()      /* Address already in use                          */
            case EADDRNOTAVAIL:   return CErrors.ADDRNOTAVAIL()   /* Can't assign requested address                  */
            case EAFNOSUPPORT:    return CErrors.AFNOSUPPORT()    /* Address family not supported by protocol family */
            case EAGAIN:          return CErrors.AGAIN()          /* Resource temporarily unavailable                */
            case EALREADY:        return CErrors.ALREADY()        /* Operation already in progress                   */
            case EBADF:           return CErrors.BADF()           /* Bad file descriptor                             */
            case EBADMSG:         return CErrors.BADMSG()         /* Bad message                                     */
            case EBUSY:           return CErrors.BUSY()           /* Device / Resource busy                          */
            case ECANCELED:       return CErrors.CANCELED()       /* Operation canceled                              */
            case ECHILD:          return CErrors.CHILD()          /* No child processes                              */
            case ECONNABORTED:    return CErrors.CONNABORTED()    /* Software caused connection abort                */
            case ECONNREFUSED:    return CErrors.CONNREFUSED()    /* Connection refused                              */
            case ECONNRESET:      return CErrors.CONNRESET()      /* Connection reset by peer                        */
            case EDEADLK:         return CErrors.DEADLK()         /* Resource deadlock avoided                       */
            case EDESTADDRREQ:    return CErrors.DESTADDRREQ()    /* Destination address required                    */
            case EDOM:            return CErrors.DOM()            /* Numerical argument out of domain                */
            case EDQUOT:          return CErrors.DQUOT()          /* Disc quota exceeded                             */
            case EEXIST:          return CErrors.EXIST()          /* File exists                                     */
            case EFAULT:          return CErrors.FAULT()          /* Bad address                                     */
            case EFBIG:           return CErrors.FBIG()           /* File too large                                  */
            case EHOSTDOWN:       return CErrors.HOSTDOWN()       /* Host is down                                    */
            case EHOSTUNREACH:    return CErrors.HOSTUNREACH()    /* No route to host                                */
            case EIDRM:           return CErrors.IDRM()           /* Identifier removed                              */
            case EILSEQ:          return CErrors.ILSEQ()          /* Illegal byte sequence                           */
            case EINPROGRESS:     return CErrors.INPROGRESS()     /* Operation now in progress                       */
            case EINTR:           return CErrors.INTR()           /* Interrupted system call                         */
            case EINVAL:          return CErrors.INVAL()          /* Invalid argument                                */
            case EIO:             return CErrors.IO()             /* Input/output error                              */
            case EISCONN:         return CErrors.ISCONN()         /* Socket is already connected                     */
            case EISDIR:          return CErrors.ISDIR()          /* Is a directory                                  */
            case ELOOP:           return CErrors.LOOP()           /* Too many levels of symbolic links               */
            case EMFILE:          return CErrors.MFILE()          /* Too many open files                             */
            case EMLINK:          return CErrors.MLINK()          /* Too many links                                  */
            case EMSGSIZE:        return CErrors.MSGSIZE()        /* Message too long                                */
            case EMULTIHOP:       return CErrors.MULTIHOP()       /* Reserved                                        */
            case ENAMETOOLONG:    return CErrors.NAMETOOLONG()    /* File name too long                              */
            case ENETDOWN:        return CErrors.NETDOWN()        /* Network is down                                 */
            case ENETRESET:       return CErrors.NETRESET()       /* Network dropped connection on reset             */
            case ENETUNREACH:     return CErrors.NETUNREACH()     /* Network is unreachable                          */
            case ENFILE:          return CErrors.NFILE()          /* Too many open files in system                   */
            case ENOBUFS:         return CErrors.NOBUFS()         /* No buffer space available                       */
            case ENODATA:         return CErrors.NODATA()         /* No message available on STREAM                  */
            case ENODEV:          return CErrors.NODEV()          /* Operation not supported by device               */
            case ENOENT:          return CErrors.NOENT()          /* No such file or directory                       */
            case ENOEXEC:         return CErrors.NOEXEC()         /* Exec format error                               */
            case ENOLCK:          return CErrors.NOLCK()          /* No locks available                              */
            case ENOLINK:         return CErrors.NOLINK()         /* Reserved                                        */
            case ENOMEM:          return CErrors.NOMEM()          /* Cannot allocate memory                          */
            case ENOMSG:          return CErrors.NOMSG()          /* No message of desired type                      */
            case ENOPROTOOPT:     return CErrors.NOPROTOOPT()     /* Protocol not available                          */
            case ENOSPC:          return CErrors.NOSPC()          /* No space left on device                         */
            case ENOSR:           return CErrors.NOSR()           /* No STREAM resources                             */
            case ENOSTR:          return CErrors.NOSTR()          /* Not a STREAM                                    */
            case ENOSYS:          return CErrors.NOSYS()          /* Function not implemented                        */
            case ENOTBLK:         return CErrors.NOTBLK()         /* Block device required                           */
            case ENOTCONN:        return CErrors.NOTCONN()        /* Socket is not connected                         */
            case ENOTDIR:         return CErrors.NOTDIR()         /* Not a directory                                 */
            case ENOTEMPTY:       return CErrors.NOTEMPTY()       /* Directory not empty                             */
            case ENOTRECOVERABLE: return CErrors.NOTRECOVERABLE() /* State not recoverable                           */
            case ENOTSOCK:        return CErrors.NOTSOCK()        /* Socket operation on non-socket                  */
            case ENOTSUP:         return CErrors.NOTSUP()         /* Operation not supported                         */
            case ENOTTY:          return CErrors.NOTTY()          /* Inappropriate ioctl for device                  */
            case ENXIO:           return CErrors.NXIO()           /* Device not configured                           */
            case EOPNOTSUPP:      return CErrors.OPNOTSUPP()      /* Operation not supported on socket               */
            case EOVERFLOW:       return CErrors.OVERFLOW()       /* Value too large to be stored in data type       */
            case EOWNERDEAD:      return CErrors.OWNERDEAD()      /* Previous owner died                             */
            case EPERM:           return CErrors.PERM()           /* Operation not permitted                         */
            case EPFNOSUPPORT:    return CErrors.PFNOSUPPORT()    /* Protocol family not supported                   */
            case EPIPE:           return CErrors.PIPE()           /* Broken pipe                                     */
            case EPROTO:          return CErrors.PROTO()          /* Protocol error                                  */
            case EPROTONOSUPPORT: return CErrors.PROTONOSUPPORT() /* Protocol not supported                          */
            case EPROTOTYPE:      return CErrors.PROTOTYPE()      /* Protocol wrong type for socket                  */
            case ERANGE:          return CErrors.RANGE()          /* Result too large                                */
            case EREMOTE:         return CErrors.REMOTE()         /* Too many levels of remote in path               */
            case EROFS:           return CErrors.ROFS()           /* Read-only file system                           */
            case ESHUTDOWN:       return CErrors.SHUTDOWN()       /* Can't send after socket shutdown                */
            case ESOCKTNOSUPPORT: return CErrors.SOCKTNOSUPPORT() /* Socket type not supported                       */
            case ESPIPE:          return CErrors.SPIPE()          /* Illegal seek                                    */
            case ESRCH:           return CErrors.SRCH()           /* No such process                                 */
            case ESTALE:          return CErrors.STALE()          /* Stale NFS file handle                           */
            case ETIME:           return CErrors.TIME()           /* STREAM ioctl timeout                            */
            case ETIMEDOUT:       return CErrors.TIMEDOUT()       /* Operation timed out                             */
            case E2BIG:           return CErrors.TOBIG()          /* Argument list too long                          */
            case ETOOMANYREFS:    return CErrors.TOOMANYREFS()    /* Too many references: can't splice               */
            case ETXTBSY:         return CErrors.TXTBSY()         /* Text file busy                                  */
            case EUSERS:          return CErrors.USERS()          /* Too many users                                  */
            case EWOULDBLOCK:     return CErrors.WOULDBLOCK()     /* Operation would block                           */
            case EXDEV:           return CErrors.XDEV()           /* Cross-device link                               */
            default: break
        }

        #if os(macOS) || os(tvOS) || os(iOS) || os(watchOS)
            // These only exist on Apple OS'.
            switch code {
                case EAUTH:           return CErrors.AUTH()           /* Authentication error                            */
                case EBADARCH:        return CErrors.BADARCH()        /* Bad CPU type in executable                      */
                case EBADEXEC:        return CErrors.BADEXEC()        /* Bad executable                                  */
                case EBADRPC:         return CErrors.BADRPC()         /* RPC struct is bad                               */
                case EBADMACHO:       return CErrors.BADMACHO()       /* Malformed Macho file                            */
                case EDEVERR:         return CErrors.DEVERR()         /* Device error, e.g. paper out                    */
                case EFTYPE:          return CErrors.FTYPE()          /* Inappropriate file type or format               */
                case ELAST:           return CErrors.LAST()           /* Must be equal largest errno                     */
                case ENEEDAUTH:       return CErrors.NEEDAUTH()       /* Need authenticator                              */
                case ENOATTR:         return CErrors.NOATTR()         /* Attribute not found                             */
                case ENOPOLICY:       return CErrors.NOPOLICY()       /* No such policy registered                       */
                case EPROCLIM:        return CErrors.PROCLIM()        /* Too many processes                              */
                case EPROCUNAVAIL:    return CErrors.PROCUNAVAIL()    /* Bad procedure for program                       */
                case EPROGMISMATCH:   return CErrors.PROGMISMATCH()   /* Program version wrong                           */
                case EPROGUNAVAIL:    return CErrors.PROGUNAVAIL()    /* RPC prog. not avail                             */
                case EPWROFF:         return CErrors.PWROFF()         /* Device power is off                             */
                case EQFULL:          return CErrors.QFULL()          /* Interface output queue is full                  */
                case ERPCMISMATCH:    return CErrors.RPCMISMATCH()    /* RPC version wrong                               */
                case ESHLIBVERS:      return CErrors.SHLIBVERS()      /* Shared library version mismatch                 */
                default: break
            }
        #endif

        #if os(Linux)
            // These only exist on Linux.
            switch code {
                case EADV:         return CErrors.ADV()         /* Advertise error                                 */
                case EBADE:        return CErrors.BADE()        /* Invalid exchange                                */
                case EBADFD:       return CErrors.BADFD()       /* File descriptor in bad state                    */
                case EBADR:        return CErrors.BADR()        /* Invalid request descriptor                      */
                case EBADRQC:      return CErrors.BADRQC()      /* Invalid request code                            */
                case EBADSLT:      return CErrors.BADSLT()      /* Invalid slot                                    */
                case EBFONT:       return CErrors.BFONT()       /* Bad font file format                            */
                case ECHRNG:       return CErrors.CHRNG()       /* Channel number out of range                     */
                case ECOMM:        return CErrors.COMM()        /* Communication error on send                     */
                case EDEADLOCK:    return CErrors.DEADLOCK()    /* Resource deadlock avoided                       */
                case EDOTDOT:      return CErrors.DOTDOT()      /* RFS specific error                              */
                case EHWPOISON:    return CErrors.HWPOISON()    /* Memory page has hardware error                  */
                case EISNAM:       return CErrors.ISNAM()       /* Is a named type file                            */
                case EKEYEXPIRED:  return CErrors.KEYEXPIRED()  /* Key has expired                                 */
                case EKEYREJECTED: return CErrors.KEYREJECTED() /* Key was rejected by service                     */
                case EKEYREVOKED:  return CErrors.KEYREVOKED()  /* Key has been revoked                            */
                case EL2HLT:       return CErrors.L2HLT()       /* Level 2 halted                                  */
                case EL2NSYNC:     return CErrors.L2NSYNC()     /* Level 2 not synchronized                        */
                case EL3HLT:       return CErrors.L3HLT()       /* Level 3 halted                                  */
                case EL3RST:       return CErrors.L3RST()       /* Level 3 reset                                   */
                case ELIBACC:      return CErrors.LIBACC()      /* Can not access a needed shared library          */
                case ELIBBAD:      return CErrors.LIBBAD()      /* Accessing a corrupted shared library            */
                case ELIBEXEC:     return CErrors.LIBEXEC()     /* Cannot exec a shared library directly           */
                case ELIBMAX:      return CErrors.LIBMAX()      /* Attempting to link in too many shared libraries */
                case ELIBSCN:      return CErrors.LIBSCN()      /* .lib section in a.out corrupted                 */
                case ELNRNG:       return CErrors.LNRNG()       /* Link number out of range                        */
                case EMEDIUMTYPE:  return CErrors.MEDIUMTYPE()  /* Wrong medium type                               */
                case ENAVAIL:      return CErrors.NAVAIL()      /* No XENIX semaphores available                   */
                case ENOANO:       return CErrors.NOANO()       /* No anode                                        */
                case ENOCSI:       return CErrors.NOCSI()       /* No CSI structure available                      */
                case ENOKEY:       return CErrors.NOKEY()       /* Required key not available                      */
                case ENOMEDIUM:    return CErrors.NOMEDIUM()    /* No medium found                                 */
                case ENONET:       return CErrors.NONET()       /* Machine is not on the network                   */
                case ENOPKG:       return CErrors.NOPKG()       /* Package not installed                           */
                case ENOTNAM:      return CErrors.NOTNAM()      /* Not a XENIX named type file                     */
                case ENOTUNIQ:     return CErrors.NOTUNIQ()     /* Name not unique on network                      */
                case EREMCHG:      return CErrors.REMCHG()      /* Remote address changed                          */
                case EREMOTEIO:    return CErrors.REMOTEIO()    /* Remote I/O error                                */
                case ERESTART:     return CErrors.RESTART()     /* Interrupted system call should be restarted     */
                case ERFKILL:      return CErrors.RFKILL()      /* Operation not possible due to RF-kill           */
                case ESRMNT:       return CErrors.SRMNT()       /* Srmount error                                   */
                case ESTRPIPE:     return CErrors.STRPIPE()     /* Streams pipe error                              */
                case EUCLEAN:      return CErrors.UCLEAN()      /* Structure needs cleaning                        */
                case EUNATCH:      return CErrors.UNATCH()      /* Protocol driver not attached                    */
                case EXFULL:       return CErrors.XFULL()       /* Exchange full                                   */
                default: break
            }
        #endif

        return .UNKNOWN(code: code)
    }
}
