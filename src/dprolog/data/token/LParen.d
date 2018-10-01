module dprolog.data.token.LParen;

import dprolog.data.token;

import std.format;

class LParen : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"LParen(lexeme: \"%s\")"(lexeme);
  }

}
