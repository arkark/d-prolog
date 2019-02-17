Getting Started
===

## Start D-Prolog

```sh
$ dprolog
?-
```

With an initialization file:
```sh
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
Input `ctrl+c` or `ctrl+d` to exit from the mode for adding rules.

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
?- X = 10. % A decimal literal
X = 10.

?- X = 0b1010. % A binary literal
X = 10.

?- X = 0xff. % A hexadecimal literal
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

```sh
$ dprolog -f list.pro
```

Conjunctions:
```prolog
?- member(X, [1, 2, 3]), member(X, [3, 4]).
X = 3;
false.
```

Disjunctions:
```prolog
?- member(X, [1, 2, 3]); member(X, [3, 4]).
X = 1;
X = 2;
X = 3;
X = 3;
X = 4;
false.
```

Conjuctions and disjunctions:
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

---

If you want to know more about D-Prolog, see [Specification](Specification.md).