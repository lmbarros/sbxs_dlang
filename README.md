# SBXS

A library of things I wanted and took the time to write. Tends to be
biased towards graphics and games and other fun stuff.

I will happily make breaking changes. I will not make it easy for other
people use it (no DUB package for example). This may change in the
future, but for now, that's how it is. Anyway, the code is here and the
license (MIT) isn't bad.

Feel free to use and submit pull requests (especially bug fixes).

Written in the [D programming language](https://dlang.org) (AKA
dlang), by Leandro Motta Barros.


## Quick compilation guide

### Linux

First: `premake5 gmake`. Or, to specify a D compiler other than DMD:
`premake --dc=gdc gmake` (or `ldc`).


Then, for a standard, debug build: `make -j8`

For a test build: `make -j8 config=test

For a release build: `make -j8 config=release`

### Windows

Never tried, though it is a target I intend to eventually support.

### Mac

Should be supported, ideally, but I don't even have a Mac.

## Engine

The `engine` module provides a reasonably simple to use game engine-like
infrastructure.

### Back ends

A back end is simply a `struct` (assumed to actually have value
semantics) having other `struct`s as members, each of which implementing
a different subsystem.

A subsystem may have a minimal set of features it must implement to be
considered "compliant" (for example, it may have to provide some certain
types or to implement certain methods). I am not providing any way to
check if this minimal interface is properly implemented. I assume that
if a back end has a `display` member it means that it implements the
minimal interface in place. In the future I may add some traits-like
checks to verify this (at the moment I don't even have documented what
constitutes this minimal interface!).

In addition to this basic interface, some engine features are provided
if the backend implements some additional requisites. These are looked
for using design by introspection.

By the way, I spell "back end" but, in code, I use `backend` instead of
`backEnd`. I try to be very consistent regarding this inconsistency.
