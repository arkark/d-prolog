module dprolog.data.token.RBracket;

import dprolog.data.token;

import std.format;

class RBracket : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"RBracket(lexeme: \"%s\")"(lexeme);
  }

}
