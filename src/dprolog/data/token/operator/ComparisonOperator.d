module dprolog.data.token.operator.ComparisonOperator;

import dprolog.data.token;

import std.stdio;
import std.format;
import std.functional;

abstract class ComparisonOperator : Operator {
  private this(dstring lexeme, long precedence, string type, long line, long column)  {
    super(lexeme, precedence, type, line, column);
  }
  bool calc(Number x, Number y);
  override string toString() const {
    return format!"ComparisonOperator(lexeme: \"%s\", precedence: %s, type: %s)"(lexeme, precedence, type);
  }
}

ComparisonOperator makeComparisonOperator(alias fun)(dstring lexeme, long precedence, string type, long line = -1, long column = -1)
if (is(typeof(binaryFun!fun(Number.init, Number.init)) == bool)) {
  return new class(lexeme, precedence, type, line, column) ComparisonOperator {
    this(dstring lexeme, long precedence, string type, long line, long column) {
      super(lexeme, precedence, type, line, column);
    }
    override bool calc(Number x, Number y) {
      return binaryFun!fun(x, y);
    }
    override protected Operator make(long line, long column) const {
      return makeComparisonOperator!fun(this.lexeme, this.precedence, this.type, line, column);
    }
  };
}

unittest {
  writeln(__FILE__, ": test ComparisonOperator");

  ComparisonOperator lessOp = makeComparisonOperator!"a < b"("<", 700, "xfx");
  ComparisonOperator eqOp = makeComparisonOperator!"a == b"("=:=", 700, "xfx");
  ComparisonOperator neqOp = makeComparisonOperator!"a != b"("=\\=", 700, "xfx");

  import std.bigint;
  Number num(long value) {
    return new Number(BigInt(value));
  }

  assert(lessOp.calc(num(1), num(10)) == (1 < 10));
  assert(lessOp.calc(num(10), num(1)) == (10 < 1));
  assert(lessOp.calc(num(1), num(1)) == (1 < 1));
  assert(eqOp.calc(num(1), num(1)) == (1 == 1));
  assert(eqOp.calc(num(1), num(-1)) == (1 == -1));
  assert(neqOp.calc(num(1), num(1)) == (1 != 1));
  assert(neqOp.calc(num(1), num(-1)) == (1 != -1));
}
