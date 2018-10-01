module dprolog.data.token.LBracket;

import dprolog.data.token;

import std.format;

class LBracket : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"LBracket(lexeme: \"%s\")"(lexeme);
  }

}
