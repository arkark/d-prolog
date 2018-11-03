module dprolog.data.token.Number;

import dprolog.data.token;

import std.stdio;
import std.conv;
import std.algorithm;
import std.range;
import std.format;
import std.bigint;

class Number : Token {

  private immutable BigInt value;
  this(dstring lexeme, long line, long column) {
    string literal = lexeme.to!string;
    if (isBinaryLiteral(literal)) {
      literal = convertBinaryToHexadecimal(literal);
    }
    this(BigInt(literal), line, column);
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

private:
  static bool isBinaryLiteral(string binary) {
    return binary.startsWith("0b") && binary.length > 2 && binary.drop(2).all!"a=='0' || a=='1'";
  }
  static string convertBinaryToHexadecimal(string binary) in(isBinaryLiteral(binary)) do {
    int[] nums = binary.drop(2).retro.map!(c => c.to!string.to!int).array;
    int[] hexadecimals = [];
    foreach(i; 0..int.max) {
      if (4*i >= nums.length) break;
      int h = 0;
      foreach(j; 0..4) {
        if (4*i+j >= nums.length) break;
        h += nums[4*i+j]<<j;
      }
      hexadecimals ~= h;
    }
    return "0x" ~ hexadecimals.map!(h => h.to!string(16)).retro.join.to!string;
  }

  unittest {
    writeln(__FILE__, ": test convertBinaryToHexadecimal");

    assert(convertBinaryToHexadecimal("0b0") == "0x0");
    assert(convertBinaryToHexadecimal("0b1010") == "0xA");
    assert(convertBinaryToHexadecimal("0b111111") == "0x3F");
  }

}
