module dprolog.data.token.Period;

import dprolog.data.token;

import std.format;

class Period : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"Period(lexeme: \"%s\")"(lexeme);
  }

}
