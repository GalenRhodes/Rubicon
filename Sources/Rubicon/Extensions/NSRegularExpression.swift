import Foundation

extension NSRegularExpression {
    typealias MatchClosure = (NSTextCheckingResult?, MatchingFlags, inout Bool) throws -> Void

    func enumerateMatches(in string: String,
                          options: MatchingOptions = [],
                          range: Range<String.Index>,
                          using block: MatchClosure) rethrows {
        try withoutActuallyEscaping(block) { (_block) in
            var error: Error? = nil
            let nsRange       = NSRange(range, in: string)

            enumerateMatches(in: string,
                             options: options,
                             range: nsRange) { (results: NSTextCheckingResult?,
                                                flags: MatchingFlags,
                                                stop: UnsafeMutablePointer<ObjCBool>) in
                var _stop: Bool = false
                do {
                    try _block(results, flags, &_stop)
                }
                catch let e {
                    error = e
                    _stop = true
                }
                stop.pointee = ObjCBool(_stop)
            }

            if let e = error { throw e }
        }
    }
}
