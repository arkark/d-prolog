module dprolog.data.token.Number;

import dprolog.data.token;

import std.conv;
import std.format;
import std.bigint;

class Number : Token {

  private immutable BigInt value;
  this(dstring lexeme, long line, long column) {
    this(BigInt(lexeme.to!string), line, column);
  }
  this(BigInt value, long line = -1, long column = -1) {
    super(value.to!dstring, line, column);
    this.value = value;
  }

  Number opUnary(string op)()
  if (op=="+" || op=="-") {
    return new Number(mixin(op ~ "this.value"));
  }

  Number opBinary(string op)(Number that)
  if (op=="+" || op=="-" || op=="*" || op=="/" || op=="%") {
    return new Number(mixin("this.value" ~ op ~ "that.value"));
  }

  override bool opEquals(Object o) {
    auto that = cast(Number) o;
    return that && this.lexeme==that.lexeme;
  }

  BigInt opCmp(Number that) const {
    return this.value - that.value;
  }

  override string toString() const {
    return format!"Number(value: %s)"(value);
  }

}
