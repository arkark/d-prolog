# D-Prolog Note

## Tokens

```
<token>         ::= <atom> | <number> | <variable> | <operator> | <left paren> | <right paren> | <left bracket> | <right bracket> | <period>
<atom>          ::= regex( [a-z][_0-9a-zA-Z]* ) | regex( `[^`]*` ) | (<special>)+
<number>        ::= regex( 0 | [1-9][0-9]* )
<variable>      ::= regex( [_A-Z][_0-9a-zA-Z]* )
<operator>      ::= ( System Operators を参照 )
<left paren>    ::= "("
<right paren>   ::= ")"
<left bracket>  ::= "["
<right bracket> ::= "]"
<period>        ::= "."
<special>       ::= ":" | "?" | "&" | ";" | "," | "|" | "=" | "<" | ">" | "+" | "-" | "*" | "/" | "\"
```

- `<number>`に32-bit整数を用いる。実数には対応しない。

## Syntax

```
<program>         ::= (<clause>)*
<clause>          ::= <fact> | <rule> | <query>
<fact>            ::= <term> <period>
<rule>            ::= <term> ":-" <compound term> <period>
<query>           ::= "?-" <compound term> <period>
<compound term>   ::= <term> (("," | ";") <term>)*
<term>            ::= <left paren> <term> <right paren> | <atom> | <number> | <variable> | <structure> | <list>
<structure>       ::= <functor> <left paren> <term> ("," <term>)* <right paren> | <term> <operator> <term> | <operator> <term>
<functor>         ::= <atom>
<list>            ::= <left bracket> [<term> ("," <term>)*] ["|" <list>] <right bracket>
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
