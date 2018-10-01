module dprolog.data.token.RParen;

import dprolog.data.token;

import std.format;

class RParen : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"RParen(lexeme: \"%s\")"(lexeme);
  }

}
