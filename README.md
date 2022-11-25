# RUBICON

Rubicon is a set of classes, structures, enums, extensions, tools, and utilities to make
Swift development easier, cleaner, and less verbose.

In general there were a host of code patterns that I found myself doing over and over again and so I collected them into this library as extensions, classes, structures, and utility functions.

For example, using [NSRegularExpression](https://developer.apple.com/documentation/foundation/nsregularexpression) can be a pain because all of the indexes assume [NSString's](https://developer.apple.com/documentation/foundation/nsstring) UTF-16 structure and therefore use [Int](https://developer.apple.com/documentation/swift/int) and [NSRange](https://developer.apple.com/documentation/foundation/nsrange). So I created a new wrapper around NSRegularExpression called [RegularExpression](https://github.com/GalenRhodes/Rubicon/blob/master/Sources/Rubicon/RegularExpression.swift) that uses [String.Index](https://developer.apple.com/documentation/swift/string/index) and [Range](https://developer.apple.com/documentation/swift/range)<String.Index> instead.

## API Documentation

Documentation of the API can be found here: [Rubion API](http://galenrhodes.com/Rubicon/)

## Copyright

[Copyright © 2022 Galen Rhodes. All rights reserved.](LICENSE)
