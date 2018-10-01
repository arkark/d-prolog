module dprolog.data.token.operator.BinaryOperator;

import dprolog.data.token;

import std.stdio;
import std.functional;

abstract class BinaryOperator : Operator {
  private this(dstring lexeme, long precedence, string type, long line, long column)  {
    super(lexeme, precedence, type, line, column);
  }
  long compute(long x, long y);
}

BinaryOperator makeBinaryOperator(alias fun)(dstring lexeme, long precedence, string type, long line = -1, long column = -1)
if (is(typeof(binaryFun!fun(long.init, long.init)) == long)) {
  return new class(lexeme, precedence, type, line, column) BinaryOperator {
    this(dstring lexeme, long precedence, string type, long line, long column) {
      super(lexeme, precedence, type, line, column);
    }
    override long compute(long x, long y) {
      return binaryFun!fun(x, y);
    }
    override protected Operator make(long line, long column) const {
      return makeBinaryOperator!fun(this.lexeme, this.precedence, this.type, line, column);
    }
  };
}

unittest {
  writeln(__FILE__, ": test BinaryOperator");

  BinaryOperator plusOp = makeBinaryOperator!"a + b"("+", 500, "yfx");
  BinaryOperator multOp = makeBinaryOperator!"a * b"("*", 500, "yfx");

  assert(plusOp.compute(121, 12) == 121 + 12);
  assert(multOp.compute(921, 19) == 921 * 19);
}
