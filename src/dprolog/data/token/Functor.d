module dprolog.data.token.Functor;

import dprolog.data.token;

import std.format;

class Functor : Atom {

  this(Atom atom) {
    super(atom.lexeme, atom.line, atom.column);
  }

  override bool opEquals(Object o) {
    auto that = cast(Functor) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Functor(lexeme: \"%s\")"(lexeme);
  }

}
