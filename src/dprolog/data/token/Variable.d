module dprolog.data.token.Variable;

import dprolog.data.token;

import std.format;

class Variable : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    auto that = cast(Variable) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Variable(lexeme: \"%s\")"(lexeme);
  }
}
