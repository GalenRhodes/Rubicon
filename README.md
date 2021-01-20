# RUBICON
Rubicon is a set of classes, structures, enums, extensions, tools, and utilities to make
Swift development easier, cleaner, and less verbose.

# API Documentation
Documentation of the API can be found here: [Rubion API](http://galenrhodes.com/Rubicon/)

# Why the name Rubicon?
> To cross the Rubicon is a metaphor which means to take an irrevocable step that commits one to a specific course. When Julius Caesar was about to cross the tiny Rubicon River in 49 B.C.E., he quoted from a play by Menander to say "anerriphtho kybos!" or "let the die be cast" in Greek.

[Gill, N.S. "Meaning Behind the Phrase to Cross the Rubicon." ThoughtCo, Aug. 27, 2020, thoughtco.com/meaning-cross-the-rubicon-117548.](https://www.thoughtco.com/meaning-cross-the-rubicon-117548)

# Swifty Stuff
Here's just a few of the places where I've taken advantage of Swift's features.

## NSRecursiveLock -> RecursiveLock
Even though they've included a version of [NSRecursiveLock](https://developer.apple.com/documentation/foundation/nsrecursivelock) in the open source version of Swift I still get nervous that one day all the NS* classes will suddenly disappear. So I created a wrapper around NSRecursiveLock called simply "RecursiveLock". That way if I suddenly have to recreate it at least I won't have to rename it.

Also as part of RecursiveLock I've create a method called:
```Swift
func withLock<T>(_ lambda: () throws -> T) rethrows -> T
```

So that rather than the standard design pattern of:

```Swift
do {
    lock.lock()
    defer { lock.unlock() }
    /* Do something here. */
}
```

We can now just do this:

```Swift
lock.withLock {
    /* Do something here. */
}
```

It will even allow returned values and throws.
```Swift
let val = try lock.withLock {
    try iReturnAValueOrThrowAnError()
}
```

## NSCondition -> Conditional
For the same reasons as above I created a wrapper around [NSCondition](https://developer.apple.com/documentation/foundation/nscondition) called simply "Conditional".

Also, along with the `withLock(_:)` method above, I've also included a new method called:
```Swift
public func withLockWait<T>(broadcastBeforeWait: Bool = false, _ cond: () -> Bool, do block: () throws -> T) rethrows -> T
```

This method takes two enclosures. One to test the condition and the other to execute once the condition is met.

So instead of saying:
```Swift
do {
    lock.lock()
    defer {
        lock.broadcast()
        lock.unlock()
    }
    while !someCondition() {
        lock.wait()
    }
    /* Do something here! */
}
```

You can now simply say this:
```Swift
lock.withLockWait {
    someCondition()
} do: {
    /* Do something here! */
}
```

So much more clear!

If you need to call `broadcast()` before calling `wait()` then simply pass `true` to `broadcastBeforeWait:` like so:

```Swift
lock.withLockWait(broadcastBeforeWait: true) {
    someCondition()
} do: {
    /* Do something here! */
}
```
 
That would be the same as:
```Swift
do {
    lock.lock()
    defer {
        lock.broadcast()
        lock.unlock()
    }
    while !someCondition() {
        lock.broadcast()
        lock.wait()
    }
    /* Do something here! */
}
```

Also, the version of `withLock(_:)` in Conditional calls `broadcast()` right before it calls `unlock()`.
