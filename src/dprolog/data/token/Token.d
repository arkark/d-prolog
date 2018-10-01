module dprolog.data.token.Token;

import std.format;

abstract class Token {

  static immutable dstring specialCharacters = ":?&;,|=<>+-*/\\";

  immutable long line;
  immutable long column;
  immutable dstring lexeme;
  this(dstring lexeme, long line, long column) {
    this.lexeme = lexeme;
    this.line = line;
    this.column = column;
  }

  bool isUnderscore() {
    return lexeme == "_";
  }

  override hash_t toHash() {
    hash_t hash = 0u;
    foreach(c; lexeme) {
      hash = c.hashOf(hash);
    }
    return hash;
  }

  override string toString() const {
    return format!"Token(lexeme: \"%s\")"(lexeme);
  }

}
