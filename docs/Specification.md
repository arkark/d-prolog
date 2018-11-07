Specification
===

## Tokens

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

## Syntax

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

## System Operators

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
