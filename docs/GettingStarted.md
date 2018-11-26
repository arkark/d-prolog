Getting Started
===

## Start D-Prolog

```bash
$ dprolog
?-
```

with an initialization file:
```bash
$ dprolog -f example/family.pro
?-
```
```prolog
?- male(X).
X = bob;
X = tom;
X = jim.
```

## Stop D-Prolog

```prolog
?- halt.
```
or input `ctrl+c` or `ctrl+d` to stop D-Prolog.

## Options

- `-h`, `--help`:  Print a help message
- `-v`, `--version`: Print version of dprolog
- `-f`, `--file=VALUE`:  Read `VALUE` as an initialization file
- `--verbose`:  Print diagnostic output

## Example Prolog files

- `example/family.pro`
- `example/list.pro`
- `example/factorial.pro`
- `example/if.pro`

## Load a file while running

Input a query `?- [<file path>].` while running as follows:
```prolog
?- [`file.pro`].
```
```prolog
?- [`/path/to/file.pro`].
```

## Add rules from the console

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

## Comments

The %-style line comments are supported.

```prolog
?- X = 1. % This is a comment.
X = 1.
```

## Lists

```prolog
?- X = [a, b, c].
X = [a, b, c].

?- X = [a | [b, c]].
X = [a, b, c].
```

## Integers and Arithmetic Operations

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

## Conjunctions and Disjunctions

```bash
$ dprolog -f list.pro
```

conjunctions:
```prolog
?- member(X, [1, 2, 3]), member(X, [3, 4]).
X = 3;
false.
```

disjunctions:
```prolog
?- member(X, [1, 2, 3]); member(X, [3, 4]).
X = 1;
X = 2;
X = 3;
X = 3;
X = 4;
false.
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

## Cut Operator

```prolog
?- X = 1; X = 2.
X = 1;
X = 2.

?- X = 1, !; X = 2.
X = 1.
```

Load `example/if.pro`, then
```prolog
?- if(true, X = 1, X = 2).
X = 1.

?- if(false, X = 1, X = 2).
X = 2.
```
