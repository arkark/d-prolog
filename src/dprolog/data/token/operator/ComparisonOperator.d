module dprolog.data.token.operator.ComparisonOperator;

import dprolog.data.token;

import std.stdio;
import std.functional;

abstract class ComparisonOperator : Operator {
  private this(dstring lexeme, long precedence, string type, long line, long column)  {
    super(lexeme, precedence, type, line, column);
  }
  bool compute(long x, long y);
}

ComparisonOperator makeComparisonOperator(alias fun)(dstring lexeme, long precedence, string type, long line = -1, long column = -1)
if (is(typeof(binaryFun!fun(long.init, long.init)) == bool)) {
  return new class(lexeme, precedence, type, line, column) ComparisonOperator {
    this(dstring lexeme, long precedence, string type, long line, long column) {
      super(lexeme, precedence, type, line, column);
    }
    override bool compute(long x, long y) {
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

  assert(lessOp.compute(1, 10) == (1 < 10));
  assert(lessOp.compute(10, 1) == (10 < 1));
  assert(lessOp.compute(1, 1) == (1 < 1));
  assert(eqOp.compute(1, 1) == (1 == 1));
  assert(eqOp.compute(1, -1) == (1 == -1));
  assert(neqOp.compute(1, 1) == (1 != 1));
  assert(neqOp.compute(1, -1) == (1 != -1));
}
