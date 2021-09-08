import Foundation

/*==============================================================================================================*/
/// Because that's a LONG freaking name to type.
///
public typealias RegEx = NSRegularExpression
/*==============================================================================================================*/
/// Because that's a LONG freaking name to type.
///
public typealias RegExResult = NSTextCheckingResult

/*==============================================================================================================*/
/// Convienience function to build an instance of
/// <code>[RegEx](https://developer.apple.com/documentation/foundation/nsregularexpression/)</code> that includes
/// the option to have anchors ('^' and '$') match the beginning and end of lines instead of the entire input.
///
/// - Parameter pattern: the regular expression pattern.
/// - Returns: The instance of
///            <code>[RegEx](https://developer.apple.com/documentation/foundation/nsregularexpression/)</code>
/// - Throws: Exception if the pattern is an invalid regular expression pattern.
///
public func regexML(pattern: String) throws -> RegEx {
    try RegEx(pattern: pattern, options: [ RegEx.Options.anchorsMatchLines ])
}

extension NSRegularExpression {
    public typealias MatchClosure = (NSTextCheckingResult?, MatchingFlags, inout Bool) throws -> Void

    @inlinable public func enumerateMatches(in string: String,
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

extension NSRegularExpression.Options {
    @inlinable static func convert(from options: RegularExpression.Options) -> Self {
        var o: Self = []
        if options.contains(.caseInsensitive) { o.insert(.caseInsensitive) }
        if options.contains(.allowCommentsAndWhitespace) { o.insert(.allowCommentsAndWhitespace) }
        if options.contains(.ignoreMetacharacters) { o.insert(.ignoreMetacharacters) }
        if options.contains(.dotMatchesLineSeparators) { o.insert(.dotMatchesLineSeparators) }
        if options.contains(.anchorsMatchLines) { o.insert(.anchorsMatchLines) }
        if options.contains(.useUnixLineSeparators) { o.insert(.useUnixLineSeparators) }
        if options.contains(.useUnicodeWordBoundaries) { o.insert(.useUnicodeWordBoundaries) }
        return o
    }
}

extension NSRegularExpression.MatchingOptions {
    @inlinable static func convert(from options: RegularExpression.MatchingOptions) -> Self {
        var o: Self = []
        if options.contains(.reportProgress) { o.insert(.reportProgress) }
        if options.contains(.reportCompletion) { o.insert(.reportCompletion) }
        if options.contains(.anchored) { o.insert(.anchored) }
        if options.contains(.withTransparentBounds) { o.insert(.withTransparentBounds) }
        if options.contains(.withoutAnchoringBounds) { o.insert(.withoutAnchoringBounds) }
        return o
    }
}
