# Format String Syntax

Every method which produces formatted output requires a _format string_ and an _argument list_. The format string is a String which
may contain fixed text and one or more embedded format specifiers. Consider the following example:

```Swift
let aDate: Date = Date()
"Duke~s Birthday: %1$tm %1$te,%1$tY".format(aDate)
```

This format string is the first argument to the format method. It contains three format specifiers `"%1$tm"`, `"%1$te"`, and `"%1$tY"`
which indicate how the arguments should be processed and where they should be inserted in the text. The remaining portions of the
format string are fixed text including `"Dukes Birthday: "` and any other spaces or punctuation. The argument list consists of all
arguments passed to the method after the format string. In the above example, the argument list is of size one and consists of the
Date object aDate.

<dl>
    <dt>The format specifiers for general, character, and numeric types have the following syntax:

```text
%[argument_index$][flags][width][.precision]conversion
```

</dt>
<dd>The optional argument_index is a decimal integer indicating the position of the argument in the argument list. The first 
argument is referenced by `"1$"`, the second by `"2$"`, etc.</dd>

<dd>The optional flags is a set of characters that modify the output format. The set of valid flags depends on the conversion.</dd>

<dd>The optional width is a positive decimal integer indicating the minimum number of characters to be written to the output.</dd>

<dd>The optional precision is a non-negative decimal integer usually used to restrict the number of characters. The specific 
behavior depends on the conversion.</dd>

<dd>The required conversion is a character indicating how the argument should be formatted. The set of valid conversions for a given
argument depends on the argument~s data type.</dd>

<dt>The format specifiers for types which are used to represents dates and times have the following syntax:

```text
%[argument_index$][flags][width]conversion
```

</dt>
<dd>The optional argument_index, flags and width are defined as above.</dd>

<dd>The required conversion is a two character sequence. The first character is `t` or `T`. The second character indicates the 
format to be used. These characters are similar to but not completely identical to those defined by GNU date and POSIX strftime
(3c).</dd>

<dt>The format specifiers which do not correspond to arguments have the following syntax:

```test
%[flags][width]conversion
```

</dt>
<dd>The optional flags and width is defined as above.</dd>

<dd>The required conversion is a character indicating content to be inserted in the output.</dd>
</dl>

## Conversions

Conversions are divided into the following categories:

1. **General** - may be applied to any argument type
2. **Character** - may be applied to basic types which represent Unicode characters: char, Character, byte, Byte, short, and Short.
   This conversion may also be applied to the types int and Integer when Character.isValidCodePoint(int) returns true
3. **Numeric**
    1. **Integral** - may be applied to Java integral types: byte, Byte, short, Short, int and Integer, long, Long, and BigInteger
       (but not char or Character)
    2. **Floating Point** - may be applied to Java floating-point types: float, Float, double, Double, and BigDecimal
4. **Date/Time** - may be applied to Java types which are capable of encoding a date or time: long, Long, Calendar, Date and
   TemporalAccessor
5. **Percent** - produces a literal `%` (`\u0025`)
6. **Line Separator** - produces the platform-specific line separator

The following table summarizes the supported conversions. Conversions denoted by an upper-case character _(i.e. `B`, `H`, `S`,
`C`, `X`, `E`, `G`, `A`, and `T`)_ are the same as those for the corresponding lower-case conversion characters except that the
result is converted to upper case according to the rules of the prevailing Locale. The result is equivalent to the following
invocation of `String.uppercased()`.

```Swift
    out.uppercased() 
```

Conversion         | Argument Category | Description
-------------------|-------------------|-------------
`b`, `B`           | general           | If the argument `arg` is `nil`, then the result is `"false"`. If arg is a `Bool`, then the result is the string returned by `String(describing: arg)`. Otherwise, the result is `true`.
`h`, `H`           | general           | If the argument `arg` is `nil`, then the result is `"nil"`. If arg implements `BinaryInteger`
`s`, `S`           | general           | If the argument `arg` is `nil`, then the result is `"nil"`. If arg implements Formattable, then arg.formatTo is invoked. Otherwise, the result is obtained by invoking arg.toString().
`c`, `C`           | character         | The result is a Unicode character
`d`                | integral          | The result is formatted as a decimal integer
`o`                | integral          | The result is formatted as an octal integer
`x`, `X`           | integral          | The result is formatted as a hexadecimal integer
`e`, `E`           | floating point    | The result is formatted as a decimal number in computerized scientific notation
`f`                | floating point    | The result is formatted as a decimal number
`g`, `G`           | floating point    | The result is formatted using computerized scientific notation or decimal format, depending on the precision and the value after rounding.
`a`, `A`           | floating point    | The result is formatted as a hexadecimal floating-point number with a significand and an exponent. This conversion is not supported for the BigDecimal type despite the latter~s being in the floating point argument category.
`t`, `T`           | date/time         | Prefix for date and time conversion characters. See Date/Time Conversions.
`%`                | percent           | The result is a literal `%` (`\u0025`)
`n`, `N`, `r`, `R` | line separator    | The result is the platform-specific line separator Any characters not explicitly defined as conversions are illegal and are reserved for future extensions.

###Date/Time Conversions

The following date and time conversion suffix characters are defined for the `t` and `T` conversions. The types are similar to but
not completely identical to those defined by GNU date and POSIX strftime(3c). Additional conversion types are provided to access
Java-specific functionality (e.g. `L` for milliseconds within the second).

The following conversion characters are used for formatting times:

`H` Hour of the day for the 24-hour clock, formatted as two digits with a leading zero as necessary i.e. 00 - 23.
`I` Hour for the 12-hour clock, formatted as two digits with a leading zero as necessary, i.e. 01 - 12.
`k` Hour of the day for the 24-hour clock, i.e. 0 - 23.
`l` Hour for the 12-hour clock, i.e. 1 - 12.
`M` Minute within the hour formatted as two digits with a leading zero as necessary, i.e. 00 - 59.
`S` Seconds within the minute, formatted as two digits with a leading zero as necessary, i.e. 00 - 60 (`"60"` is a special value
required to support leap seconds).
`L` Millisecond within the second formatted as three digits with leading zeros as necessary, i.e. 000 - 999.
`N` Nanosecond within the second, formatted as nine digits with leading zeros as necessary, i.e. 000000000 - 999999999.
`p` Locale-specific morning or afternoon marker in lower case, e.g.`"am"` or `"pm"`. Use of the conversion prefix `T` forces this output
to upper case.
`z` RFC 822 style numeric time zone offset from GMT, e.g. -0800. This value will be adjusted as necessary for Daylight Saving Time.
For long, Long, and Date the time zone used is the default time zone for this instance of the Java virtual machine.
`Z` A string representing the abbreviation for the time zone. This value will be adjusted as necessary for Daylight Saving Time. For
long, Long, and Date the time zone used is the default time zone for this instance of the Java virtual machine. The Formatter~s
locale will supersede the locale of the argument (if any).
`s` Seconds since the beginning of the epoch starting at 1 January 1970 00:00:00 UTC, i.e. Long.MIN_VALUE/1000 to
Long.MAX_VALUE/1000.
`Q` Milliseconds since the beginning of the epoch starting at 1 January 1970 00:00:00 UTC, i.e. Long.MIN_VALUE to Long.MAX_VALUE.
The following conversion characters are used for formatting dates:

`B` Locale-specific full month name, e.g. `"January"`, `"February"`.
`b` Locale-specific abbreviated month name, e.g. `"Jan"`, `"Feb"`.
`h` Same as `b`.
`A` Locale-specific full name of the day of the week, e.g. `"Sunday"`, `"Monday"`
`a` Locale-specific short name of the day of the week, e.g. `"Sun"`, `"Mon"`
`C` Four-digit year divided by 100, formatted as two digits with leading zero as necessary, i.e. 00 - 99
`Y` Year, formatted as at least four digits with leading zeros as necessary, e.g. 0092 equals 92 CE for the Gregorian calendar.
`y` Last two digits of the year, formatted with leading zeros as necessary, i.e. 00 - 99.
`j` Day of year, formatted as three digits with leading zeros as necessary, e.g. 001 - 366 for the Gregorian calendar.
`m` Month, formatted as two digits with leading zeros as necessary, i.e. 01 - 13.
`d` Day of month, formatted as two digits with leading zeros as necessary, i.e. 01 - 31
`e` Day of month, formatted as two digits, i.e. 1 - 31. The following conversion characters are used for formatting common date/time
compositions.

`R` Time formatted for the 24-hour clock as `"%tH:%tM"`
`T` Time formatted for the 24-hour clock as `"%tH:%tM:%tS"`.
`r` Time formatted for the 12-hour clock as `"%tI:%tM:%tS %Tp"`. The location of the morning or afternoon marker (`%Tp`) may be
locale-dependent.
`D` Date formatted as `"%tm/%td/%ty"`.
`F` ISO 8601 complete date formatted as `"%tY-%tm-%td"`.
`c` Date and time formatted as `"%ta %tb %td %tT %tZ %tY"`, e.g. `"Sun Jul 20 16:17:00 EDT 1969"`. Any characters not explicitly defined
as date/time conversion suffixes are illegal and are reserved for future extensions.

Flags

The following table summarizes the supported flags. y means the flag is supported for the indicated argument types.

Flag General Character Integral Floating Point Date/Time Description
`-` y y y y y The result will be left-justified.
`#` y1 - y3 y - The result should use a conversion-dependent alternate form
`+` - - y4 y - The result will always include a sign
`  `    - - y4 y - The result will include a leading space for positive values
`0` - - y y - The result will be zero-padded
`,` - - y2 y5 - The result will include locale-specific grouping separators
`(`    - - y4 y5 - The result will enclose negative numbers in parentheses 1 Depends on the definition of Formattable.

2 For `d` conversion only.

3 For `o`, `x`, and `X` conversions only.

4 For `d`, `o`, `x`, and `X` conversions applied to BigInteger or `d` applied to byte, Byte, short, Short, int and Integer, long,
and Long.

5 For `e`, `E`, `f`, `g`, and `G` conversions only.

Any characters not explicitly defined as flags are illegal and are reserved for future extensions.

Width

The width is the minimum number of characters to be written to the output. For the line separator conversion, width is not
applicable; if it is provided, an exception will be thrown.

Precision

For general argument types, the precision is the maximum number of characters to be written to the output.

For the floating-point conversions `a`, `A`, `e`, `E`, and `f` the precision is the number of digits after the radix point. If the
conversion is `g` or `G`, then the precision is the total number of digits in the resulting magnitude after rounding.

For character, integral, and date/time argument types and the percent and line separator conversions, the precision is not
applicable; if a precision is provided, an exception will be thrown.

Argument Index

The argument index is a decimal integer indicating the position of the argument in the argument list. The first argument is
referenced by `"1$"`, the second by `"2$"`, etc.

Another way to reference arguments by position is to use the `<` (`\u003c`) flag, which causes the argument for the previous format
specifier to be re-used. For example, the following two statements would produce identical strings:

Calendar c = ...; String s1 = String.format("Duke~s Birthday: %1$tm %1$te,%1$tY", c);

String s2 = String.format("Duke~s Birthday: %1$tm %<te,%<tY", c);

