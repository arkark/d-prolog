module dprolog.data.token.Number;

import dprolog.data.token;

import std.format;
import std.conv;

class Number : Token {

  private immutable long value;
  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
    this.value = lexeme.to!long;
  }

  Number opUary(string op)()
  if (op=="+" || op=="-") {
    mixin("return new Number(" ~ op ~ "this.value);");
  }

  Number opBinary(string op)(Number that)
  if (op=="+" || op=="-" || op=="*" || op=="/" || op=="%") {
    mixin("return new Number(this.value" ~ op ~ "that.value);");
  }

  override bool opEquals(Object o) {
    auto that = cast(Number) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Number(value: %s)"(value);
  }

}
