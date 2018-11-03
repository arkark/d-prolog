D-Prolog
===

[![Build Status](https://travis-ci.com/ArkArk/d-prolog.svg?branch=master)](https://travis-ci.com/ArkArk/d-prolog)
[![codecov.io](https://codecov.io/gh/ArkArk/d-prolog/coverage.svg?branch=master)](https://codecov.io/gh/ArkArk/d-prolog)
[![license: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://github.com/ArkArk/d-prolog/blob/master/LICENSE)

A Prolog implementation in D language.

[![](demo/family.gif)](https://asciinema.org/a/204818)

## Getting Started

### Start D-Prolog

```console
$ dprolog
?-
```

with an initialization file:
```console
$ dprolog -f family.pro
?-
```
```prolog
?- male(X).
X = bob;
X = tom;
X = jim.
```

### Example files

- `example/family.pro`
- `example/list.pro`

### Options

- `-f`, `--file=VALUE`:  Read `VALUE` as a user initialization file
- `-v`, `--verbose`:  Print diagnostic output
- `-h`, `--help`:  Show help information

### Load a file while running

Input a query `?- [<file path>].` while running as follows:
```prolog
?- [`family.pro`].
```
```prolog
?- [`/path/to/file.pro`].
```

### Add rules from the console

Input a query `?- [user].`, and you will be able to add rules from the console:
```prolog
?- [user].
|: hoge(poyo).
|:
```
Input `ctrl+c` or `ctrl+d` to exit from the adding rules mode.

```prolog
?- hoge(X).
X = poyo.
```

### Comments

The %-style line comments are supported.

```prolog
?- X = 1. % This is a comment.
X = 1.
```

### Lists

```prolog
?- X = [a, b, c].
X = [a, b, c].

?- X = [a | [b, c]].
X = [a, b, c].
```

### integers and arithmetic operations

```prolog
?- X = 10. % a decimal literal
X = 10.

?- X = 0b1010. % a binary literal
X = 10.

?- X = 0xff. % a hexadecimal literal
X = 255.
```

```prolog
?- X is 1 + 2.
X = 3.

?- X = 10, Y is X * X - 1.
X = 10, Y = 99.

?- 10 < 100.
true.
```

### Conjunctions and Disjunctions

```console
$ dprolog -f list.pro
```

conjunctions:
```prolog
?- member(X, [1, 2, 3]), member(X, [3, 4]).
X = 3.
```

disjunctions:
```prolog
?- member(X, [1, 2, 3]); member(X, [3, 4]).
X = 1;
X = 2;
X = 3;
X = 3;
X = 4.
```

conjuctions and disjunctions:
```prolog
?- member(X, [1, 2, 3]); member(X, [3, 4]), X > 3.
X = 1;
X = 2;
X = 3;
X = 4.

?- (member(X, [1, 2, 3]); member(X, [3, 4])), X > 3.
X = 4.
```

### Stop D-Prolog
```prolog
?- halt.
```

## Development

### Requirements

- [DMD](https://dlang.org/download.html#dmd): a compiler for D programming language
- [DUB](http://code.dlang.org/): a package manager for D programming language
- [Linenoise](https://github.com/antirez/linenoise)

#### Install Linenoise

```console
$ git clone https://github.com/antirez/linenoise.git
$ cd linenoise
$ gcc -c -o linenoise.o linenoise.c
$ ar rcs liblinenoise.a linenoise.o
```

and move `liblinenoise.a` to `./lib/` or somewhere D can find it (e.g. `/usr/lib/`).

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

### Tests

```console
$ dub test
```

### Remaining Tasks

Look at the [issues](https://github.com/ArkArk/d-prolog/issues).

## Specification

### Tokens

```
<token>         ::= <atom> | <number> | <variable> | <left paren> | <right paren> | <left bracket> | <right bracket> | <period>
<atom>          ::= regex( [a-z][_0-9a-zA-Z]* ) | regex( `[^`]*` ) | (<special>)+
<number>        ::= regex( 0|[1-9][0-9]* ) | regex( 0[bB][0-1]+ ) | regex( 0[xX][0-9a-fA-F]+ )
<variable>      ::= regex( [_A-Z][_0-9a-zA-Z]* )
<left paren>    ::= "("
<right paren>   ::= ")"
<left bracket>  ::= "["
<right bracket> ::= "]"
<period>        ::= "."
<special>       ::= ":" | "?" | "&" | ";" | "," | "|" | "=" | "<" | ">" | "+" | "-" | "*" | "/" | "\"
```

- `<number>` is an arbitrary-precision integer.

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

- `+`, `-`, `*`, `div`, `mod`: arithmetic functions
- `<`, `=<`, `>`, `>=`, `=:=`, `=\=`: arithmetic comparison predicates

## License

[MIT](https://github.com/ArkArk/d-prolog/blob/master/LICENSE)
