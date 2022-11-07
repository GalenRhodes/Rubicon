#parse("Swift File Header.swift")

import Foundation
import CoreFoundation
#[[#if]]# canImport(Darwin)
    import Darwin
#[[#elseif]]# canImport(Glibc)
    import Glibc
#[[#elseif]]# canImport(WinSDK)
    import WinSDK
#[[#endif]]#

public class ${NAME} {
}
