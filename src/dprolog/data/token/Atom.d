module dprolog.data.token.Atom;

import dprolog.data.token;

import std.format;

class Atom : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    auto that = cast(Atom) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Atom(lexeme: \"%s\")"(lexeme);
  }

  static immutable Atom emptyList = cast(immutable) new Atom("", -1, -1); // for using an empty list

}
