#if ($HEADER_COMMENTS)
//
// ===========================================================================
//     PROJECT: ${PROJECT_NAME}
//    FILENAME: ${FILE_NAME}
//         IDE: AppCode
//      AUTHOR: ${USER_NAME}
//        DATE: ${MONTH_NAME_FULL} ${DAY}, ${YEAR}
//
#if ($ORGANIZATION_NAME && $ORGANIZATION_NAME != "")
// Copyright © ${YEAR} ${ORGANIZATION_NAME}#if (!$ORGANIZATION_NAME.endsWith(".")).#end All rights reserved.
#end
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
#end

import Foundation
import CoreFoundation
#[[#if]]# canImport(Darwin)
    import Darwin
#[[#elseif]]# canImport(Glibc)
    import Glibc
#[[#elseif]]# canImport(WinSDK)
    import WinSDK
#[[#endif]]#
