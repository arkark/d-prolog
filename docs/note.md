# D-Prolog Note

## Tokens

```
<token>    ::= <atom> | <number> | <variable> | <operator>
<atom>     ::= regex( [a-z][_0-9a-zA-Z]* ) | regex( `[^`]*` )
<number>   ::= (省略)
<variable> ::= regex( [_A-Z][_0-9a-zA-Z]* )
<operator> ::= (省略)
```

D-Prologでは`<atom>`に特殊文字の列は認めない。

## Syntax

```
<program>         ::= (<clause>)*
<clause>          ::= <fact> | <rule> | <query>
<fact>            ::= <term> "."
<rule>            ::= <term> ":-" <compound term> "."
<query>           ::= "?-" <compound term> "."
<compound term>   ::= <compound term 1>
<compound term 1> ::= <compound term 2> (";" <compound term 2>)*
<compound term 2> ::= <term> ("," <term>)*
<term>            ::= "(" <term> ")" | <atom> | <number> | <variable> | <structure> | <list>
<structure>       ::= <functor> "(" <term> ("," <term>)* ")" | <term> <operator> <term>
<functor>         ::= <atom>
<list>            ::= "[" [<term> ("," <term>)*] ["|" <list>] "]"
```

## System Operators

| Precedence | Type | Name |
| ---------: | :--: | :--- |
| 1200 | xfx | `-->`, `:-` |
| 1200 | fx | `:-`, `?-` |
| 1150 | fx | `dynamic`, `discontiguous`, `initialization`, `meta_predicate`, `module_transparent`, `multifile`, `public`, `thread_local`, `thread_initialization`, `volatile` |
| 1100 | xfy | `;`, ` | ` |
| 1050 | xfy | `->`, `*->` |
| 1000 | xfy | `,` |
| 990 | xfx | `:=` |
| 900 | fy | `\+` |
| 700 | xfx | `<`, `=`, `=..`, `=@=`, `\=@=`, `=:=`, `=<`, `==`, `=\=`, `>`, `>=`, `@<`, `@=<`, `@>`, `@>=`, `\=`, `\==`, `as`, `is`, `>:<`, `:<` |
| 600 | xfy | `:` |
| 500 | yfx | `+`, `-`, `/\`, `\/`, `xor` |
| 500 | fx | `?` |
| 400 | yfx | `*`, `/`, `//`, `div`, `rdiv`, `<<`, `>>`, `mod`, `rem` |
| 200 | xfx | `**` |
| 200 | xfy | `^` |
| 200 | fy | `+`, `-`, `\` |
| 100 | yfx | `.` |
| 1 | fx | `$` |

すべては実装しない。

ref: [4.25 Operators | SWI Prolog](http://www.swi-prolog.org/pldoc/man?section=operators)
