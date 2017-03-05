# D-Prolog Note

## Tokens

```
<token>    ::= <atom> | <number> | <variable> | <operator>
<atom>     ::= regex( [a-z][_0-9a-zA-Z]* ) | regex( `[^`]*` )
<number>   ::= regex( 0 | [1-9][0-9]* )
<variable> ::= regex( [_A-Z][_0-9a-zA-Z]* )
<operator> ::= (省略)
```

- `<atom>`に特殊文字の列は認めない。
- 後述のSystem Operatorsは`<operator>`として区別する。
- `<number>`に32-bit整数を用いる。実数には対応しない。

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
<structure>       ::= <functor> "(" <term> ("," <term>)* ")" | <term> <operator> <term> | <operator> <term>
<functor>         ::= <atom>
<list>            ::= "[" [<term> ("," <term>)*] ["|" <list>] "]"
```

## System Operators

| Precedence | Type | Name |
| ---------: | :--: | :--- |
| 1200 | xfx | `:-` |
| 1200 | fx | `?-` |
| 1100 | xfy | `;`, `|` |
| 1000 | xfy | `,` |
| 700 | xfx | `=`, `==`, `<`, `=<`, `>`, `>=`, `=:=`, `=\=`, `is` |
| 500 | yfx | `+`, `-` |
| 400 | yfx | `*`, `div`, `mod` |
| 200 | fy | `+`, `-` |

ref: [4.25 Operators | SWI Prolog](http://www.swi-prolog.org/pldoc/man?section=operators)
