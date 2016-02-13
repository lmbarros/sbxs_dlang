# SBXS

A library of things I wanted to write. Tends to be biased towards
graphics and games and other fun stuff.

I will happily make breaking changes. I will not make it easy for other
people use it (no DUB package for example). This may change in the
future, but for now, that's what it is. Anyway, the code is here and the
license isn't bad.

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
