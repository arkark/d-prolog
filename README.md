D-Prolog
===

[![Build Status](https://travis-ci.com/ArkArk/d-prolog.svg?branch=master)](https://travis-ci.com/ArkArk/d-prolog)
[![codecov.io](https://codecov.io/gh/ArkArk/d-prolog/coverage.svg?branch=master)](https://codecov.io/gh/ArkArk/d-prolog)
[![license: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://github.com/ArkArk/d-prolog/blob/master/LICENSE)

A simple Prolog implementation in Dlang.

[![](demo/family.gif)](https://asciinema.org/a/204818)

## Specification

### Tokens

```
<token>         ::= <atom> | <number> | <variable> | <left paren> | <right paren> | <left bracket> | <right bracket> | <period>
<atom>          ::= regex( [a-z][_0-9a-zA-Z]* ) | regex( `[^`]*` ) | (<special>)+
<number>        ::= regex( 0 | [1-9][0-9]* )
<variable>      ::= regex( [_A-Z][_0-9a-zA-Z]* )
<left paren>    ::= "("
<right paren>   ::= ")"
<left bracket>  ::= "["
<right bracket> ::= "]"
<period>        ::= "."
<special>       ::= ":" | "?" | "&" | ";" | "," | "|" | "=" | "<" | ">" | "+" | "-" | "*" | "/" | "\"
```

- `<number>` is 64-bit integer.

### Syntax

```
<program>       ::= (<clause>)*
<clause>        ::= [<fact> | <rule> | <query>] <period>
<fact>          ::= <term>
<rule>          ::= <term> ":-" <compound term>
<query>         ::= "?-" <compound term>
<compound term> ::= <term> (("," | ";") <term>)*
<term>          ::= <left paren> <term> <right paren> | <atom> | <number> | <variable> | <structure>
<structure>     ::= <functor> <left paren> <term> ("," <term>)* <right paren> | <term> <operator> <term> | <operator> <term> | <term> <operator> | <list>
<functor>       ::= <atom>
<operator>      ::= <atom>
<list>          ::= <left bracket> [<term> ("," <term>)* ["|" <list>]] <right bracket>
```

### System Operators

| Precedence | Type | Name |
| ---------: | :--: | :--- |
| 1200 | xfx | `:-` |
| 1200 | fx | `?-` |
| 1100 | xfy | `;`, `\|` |
| 1000 | xfy | `,` |
| 700 | xfx | `=`, `==`, `<`, `=<`, `>`, `>=`, `=:=`, `=\=`, `is` |
| 500 | yfx | `+`, `-` |
| 400 | yfx | `*`, `div`, `mod` |
| 200 | fy | `+`, `-` |

ref: [4.25 Operators | SWI Prolog](http://www.swi-prolog.org/pldoc/man?section=operators)

## Development

### Requirements

- [DMD](https://dlang.org/): a compiler for D programming language
- [DUB](http://code.dlang.org/): a package manager for D programming language

### Build

```console
$ dub build
```
The destination path of the output binary is `./build`.

### Run

with no option:
```console
$ dub run
```

with some options:
```console
$ dub run -- -f example/family.pro -v
```

##### Options:

- `-f`, `--file=VALUE`:  Read `VALUE` as a user initialization file
- `-v`, `--verbose`:  Print diagnostic output
- `-h`, `--help`:  Show help information

### Tests

```console
$ dub test
```

### Remaining Tasks

Look at the [issues](https://github.com/ArkArk/d-prolog/issues).

## License

[MIT](https://github.com/ArkArk/d-prolog/blob/master/LICENSE)
