D-Prolog
===

[![Build Status](https://travis-ci.com/ArkArk/d-prolog.svg?branch=master)](https://travis-ci.com/ArkArk/d-prolog)
[![codecov.io](https://codecov.io/gh/ArkArk/d-prolog/coverage.svg?branch=master)](https://codecov.io/gh/ArkArk/d-prolog)
[![license: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://github.com/ArkArk/d-prolog/blob/master/LICENSE)
[![Files](https://tokei.rs/b1/github/ArkArk/d-prolog?category=files)](https://github.com/ArkArk/d-prolog)
[![Lines of code](https://tokei.rs/b1/github/ArkArk/d-prolog?category=code)](https://github.com/ArkArk/d-prolog)
[![GitHub version](https://badge.fury.io/gh/arkark%2Fd-prolog.svg)](https://badge.fury.io/gh/arkark%2Fd-prolog)

A Prolog implementation in D language.

[![](demo/demo.gif)](https://asciinema.org/a/210436)

## Install

### Download binary

Download the [latest](https://github.com/ArkArk/d-prolog/releases/) `dprolog` binary.

### Install from source

```sh
$ git clone https://github.com/ArkArk/d-prolog.git
$ cd d-prolog
```
and build (refer to [Development](#development)).

## Usage

See `docs/`.
- [Getting Started](docs/GettingStarted.md)
- [Specification](docs/Specification.md)

## Development

### Requirements

- [DMD](https://dlang.org/download.html#dmd): A compiler for D programming language
- [DUB](http://code.dlang.org/): A package manager for D programming language
- [Linenoise](https://github.com/antirez/linenoise)

#### Install Linenoise

```sh
$ git clone https://github.com/antirez/linenoise.git
$ cd linenoise
$ gcc -c -o linenoise.o linenoise.c
$ ar rcs liblinenoise.a linenoise.o
```

and move `liblinenoise.a` to `lib/` or somewhere D can find it (e.g. `/usr/lib/`).

### Build

```sh
$ dub build
```
The destination directory of the output binary is `bin`.

### Run

With no option:
```sh
$ dub run
```

With some options:
```sh
$ dub run -- -f example/family.pro --verbose
```

### Tests

```sh
$ dub test
```

### Release

```sh
$ git tag <version>
$ ./release.sh
```

### Future Work

- Support for Windows
- Adding more tests

## License

[MIT](https://github.com/ArkArk/d-prolog/blob/master/LICENSE)
