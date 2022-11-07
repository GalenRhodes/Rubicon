An immutable representation of a compiled regular expression that you apply to Unicode strings.

## Overview

The fundamental matching method for RegularExpression is a Block iterator method that allows clients to supply a Block object which will be invoked each time the regular  expression matches a portion of the target string. There are additional convenience methods for returning all the matches as an array, the total number of matches, the first match, and the range of the first match.

An individual match is represented by an instance of the `RegularExpression.Match` class, which carries information about the overall matched range (via its range property), and the range of each individual capture group via instances of the `RegularExpression.Group` class.

#### Concurrency and Thread Safety

RegularExpression is designed to be immutable and thread safe, so that a single instance can be used in matching operations on multiple threads at once. However, the string on which it is operating should not be mutated during the course of a matching operation, whether from another thread or from within the Block used in the iteration.

#### Regular Expression Syntax

The following tables describe the character expressions used by the regular expression to match patterns within a string, the pattern operators that specify how many times a  pattern is matched and additional matching restrictions, and the last table specifies flags that can be included in the regular expression pattern that specify search behavior over multiple lines (these flags can also be specified using the `RegularExpression.Options` option flags).

#### Regular Expression Metacharacters

`Table 1` describe the character sequences used to match characters within a string.

**Table 1** Regular Expression Metacharacters

|       Character Expression       | Description                                                  |
| :------------------------------: | :----------------------------------------------------------- |
|               `\a`               | Match a BELL, `\u0007`                                       |
|               `\A`               | Match at the beginning of the input. Differs from `^` in that `\A` will not match after a new line within the input. |
|     `\b, outside of a [Set]`     | Match if the current position is a word boundary. Boundaries occur at the transitions between word (`\w`) and non-word (`\W`) characters, with combining marks ignored. For better word boundaries, see `RegularExpression.Options.useUnicodeWordBoundaries`. |
|       `\b, within a [Set]`       | Match a BACKSPACE, `\u0008`.                                 |
|               `\B`               | Match if the current position is not a word boundary.        |
|              `\cX`               | Match a `control-X` character                                |
|               `\d`               | Match any character with the Unicode General Category of Nd (Number, Decimal Digit.) |
|               `\D`               | Match any character that is not a decimal digit.             |
|               `\e`               | Match an `ESCAPE`, `\u001B`.                                 |
|               `\E`               | Terminates a `\Q ... \E` quoted sequence.                    |
|               `\f`               | Match a FORM FEED, `\u000C`.                                 |
|               `\G`               | Match if the current position is at the end of the previous match. |
|               `\n`               | Match a `LINE FEED`, `\u000A`.                               |
| `\N{`*UNICODE CHARACTER NAME*`}` | Match the named character.                                   |
| `\p{`*UNICODE PROPERTY NAME*`}`  | Match any character with the specified Unicode Property.     |
| `\P{`*UNICODE PROPERTY NAME*`}`  | Match any character not having the specified Unicode Property. |
|               `\Q`               | Quotes all following characters until `\E`.                  |
|               `\r`               | Match a CARRIAGE RETURN, \u000D.                             |
|               `\s`               | Match a white space character. White space is defined as [\t\n\f\r\p{Z}]. |
|               `\S`               | Match a non-white space character.                           |
|               `\t`               | Match a HORIZONTAL TABULATION, `\u0009`.                     |
|            `\u`*hhhh*            | Match the character with the hex value *hhhh*.               |
|          `\U`*hhhhhhhh*          | Match the character with the hex value *hhhhhhhh*. Exactly eight hex digits must be provided, even though the largest Unicode code point is `\U0010ffff`. |
|               `\w`               | Match a word character. Word characters are [\p{Ll}\p{Lu}\p{Lt}\p{Lo}\p{Nd}]. |
|               `\W`               | Match a non-word character.                                  |
|          `\x{`*hhhh*`}`          | Match the character with hex value *hhhh*. From one to six hex digits may be supplied. |
|             `\x*hh*`             | Match the character with two digit hex value *hh*.           |
|               `\X`               | Match a Grapheme Cluster.                                    |
|               `\Z`               | Match if the current position is at the end of input, but before the final line terminator, if one exists. |
|               `\z`               | Match if the current position is at the end of input.        |
|              `\`*n*              | Back Reference. Match whatever the *n*th capturing group matched. *n* must be a number `≥ 1` and `≤` total number of capture groups in the pattern. |
|            `\0`*ooo*             | Match an Octal character. *ooo* is from one to three octal digits. `0377` is the largest allowed Octal character. The leading zero is required; it distinguishes Octal constants from back references. |
|         `[`*pattern*`]`          | Match any one character from the pattern.                    |
|               `.`                | Match any character. See `RegularExpression.Options.dotMatchesLineSeparators` and the `\s` character expression in Table 4. |
|               `^`                | Match at the beginning of a line. See `RegularExpression.Options.anchorsMatchLines` and the `\m` character expression in Table 4. |
|               `$`                | Match at the end of a line. See `RegularExpression.Options.anchorsMatchLines` and the `\m` character expression in Table 4. |
|               `\`                | Quotes the following character. Characters that must be quoted to be treated as literals are `* ? + [ ( ) { } ^ $ | \ . /` |

#### Regular Expression Operators

`Table 2` defines the regular expression operators.

**Table 2** Regular Expression Operators

|        Operator         | Description                                                  |
| :---------------------: | :----------------------------------------------------------- |
|           `|`           | Alternation. *A*`|`*B* matches either *A* or *B*.            |
|           `*`           | Match `0` or more times. Match as many times as possible.    |
|           `+`           | Match `1` or more times. Match as many times as possible.    |
|           `?`           | Match zero or one times. Prefer one.                         |
|        `{`*n*`}`        | Match exactly *n* times.                                     |
|       `{`*n*`,}`        | Match at least *n* times. Match as many times as possible.   |
|     `{`*n*`,`*m*`}`     | Match between *n* and *m* times. Match as many times as possible, but not more than *m*. |
|          `*?`           | Match `0` or more times. Match as few times as possible.     |
|          `+?`           | Match 1 or more times. Match as few times as possible.       |
|          `??`           | Match zero or one times. Prefer zero.                        |
|       `{`*n*`}?`        | Match exactly n times.                                       |
|       `{`*n*`,}?`       | Match at least n times, but no more than required for an overall pattern match. |
|    `{`*n*`,`*m*`}?`     | Match between n and m times. Match as few times as possible, but not less than n. |
|          `*+`           | Match 0 or more times. Match as many times as possible when first encountered. Do not retry with fewer, even if overall match fails (possessive match). |
|          `++`           | Match 1 or more times (possessive match).                    |
|          `?+`           | Match zero or one times (possessive match).                  |
|       `{`*n*`}+`        | Match exactly *n* times.                                     |
|       `{`*n*`,}+`       | Match at least *n* times (possessive match).                 |
|    `{`*n*`,`*m*`}+`     | Match between *n* and *m* times (possessive match).          |
|       `(`*...*`)`       | Capturing parentheses. Range of input that matched the parenthesized subexpression is available after the match. |
|      `(?:`*...*`)`      | Non-capturing parentheses. Groups the included pattern, but does not provide capturing of matching text. Somewhat more efficient than capturing parentheses. |
|      `(?>`*...*`)`      | Atomic-match parentheses. First match of the parenthesized subexpression is the only one tried; if it does not lead to an overall pattern match, back up the search for a match to a position before the "`(?>`" |
|       `(?# ... )`       | Free-format comment `(?# comment )`.                         |
|       `(?= ... )`       | Look-ahead assertion. True if the parenthesized pattern matches at the current input position, but does not advance the input position. |
|       `(?! ... )`       | Negative look-ahead assertion. True if the parenthesized pattern does not match at the current input position. Does not advance the input position. |
|      `(?<= ... )`       | Look-behind assertion. True if the parenthesized pattern matches text preceding the current input position, with the last character of the match being the input character just before the current position. Does not alter the input position. The length of possible strings matched by the look-behind pattern must not be unbounded (no * or + operators.) |
|      `(?<! ... )`       | Negative Look-behind assertion. True if the parenthesized pattern does not match text preceding the current input position, with the last character of the match being the input character just before the current position. Does not alter the input position. The length of possible strings matched by the look-behind pattern must not be unbounded (no * or + operators.) |
| `(?ismwx-ismwx:...` `)` | Flag settings. Evaluate the parenthesized expression with the specified flags enabled or -disabled. The flags are defined in Flag Options. |
|    `(?ismwx-ismwx)`     | Flag settings. Change the flag settings. Changes apply to the portion of the pattern following the setting. For example, (?i) changes to a case insensitive match.The flags are defined in Flag Options. |

#### Template Matching Format

The `NSRegularExpression` class provides find-and-replace methods for both immutable and mutable strings using the technique of template matching.  `Table 3` describes the syntax.

**Table 3** Template Matching Format

| Character | Descriptions                                                 |
| :-------: | :----------------------------------------------------------- |
|  `$`*n*   | The text of capture group n will be substituted for $*n*. *n* must be `>= 0` and not greater than the number of capture groups. A `$` not followed by a digit has no special meaning, and will appear in the substitution text as itself, a `$`. |
|    `\`    | Treat the following character as a literal, suppressing any special meaning. Backslash escaping in substitution text is only required for '$' and '\', but may be used on any other character without bad effects. |

The replacement string is treated as a template, with `$0` being replaced by the contents of the matched range, `$1` by the contents of the first capture group, and so on. Additional digits beyond the maximum required to represent the number of capture groups will be treated as ordinary characters, as will a `$` not followed by digits. Backslash will escape both `$` and `\`.

#### Flag Options

The following flags control various aspects of regular expression matching. These flag values may be specified within the pattern using the `(?ismx-ismx)` pattern options. Equivalent behaviors can be specified for the entire pattern when an `RegularExpression` is initialized, using the `RegularExpression.Options` option flags.

**Table 4** Flag Options

| Flag (Pattern) | Description                                                  |
| :------------: | :----------------------------------------------------------- |
|      `i`       | If set, matching will take place in a case-insensitive manner. |
|      `x`       | If set, allow use of white space and #comments within patterns |
|      `s`       | If set, a "`.`" in a pattern will match a line terminator in the input text. By default, it will not. Note that a `carriage-return / line-feed pair` in text behave as a single line terminator, and will match a single "`.`" in a regular expression pattern |
|      `m`       | Control the behavior of "`^`" and "`$`" in a pattern. By default these will only match at the start and end, respectively, of the input text. If this flag is set, "`^`" and "`$`" will also match at the start and end of each line within the input text. |
|      `w`       | Controls the behavior of `\b` in a pattern. If set, word boundaries are found according to the definitions of word found in Unicode UAX 29, Text Boundaries. By default, word boundaries are identified by means of a simple classification of characters as either “word” or “non-word”, which approximates traditional regular expression behavior. The results obtained with the two options can be quite different in runs of spaces and other non-word characters. |

## Performance Tips

RegularExpression implements a nondeterministic finite automaton matching engine. As such, complex regular expression patterns containing multiple * or + operators may result in poor performance when attempting to perform matches — particularly failing to match a given input. For more information, see the [“Performance Tips” section of the ICU User Guide](https://unicode-org.github.io/icu/userguide/strings/regexp.html).

- Note: `RegularExpression` conforms to the International Components for Unicode ([ICU](https://unicode-org.github.io/icu/)) specification for [regular expressions](https://unicode-org.github.io/icu/userguide/strings/regexp.html).