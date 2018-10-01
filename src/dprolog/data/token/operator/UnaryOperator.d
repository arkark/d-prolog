module dprolog.data.token.operator.UnaryOperator;

import dprolog.data.token;

import std.stdio;
import std.functional;

abstract class UnaryOperator : Operator {
  private this(dstring lexeme, long precedence, string type, long line, long column)  {
    super(lexeme, precedence, type, line, column);
  }
  long compute(long x);
}

UnaryOperator makeUnaryOperator(alias fun)(dstring lexeme, long precedence, string type, long line = -1, long column = -1)
if (is(typeof(unaryFun!fun(long.init)) == long)) {
  return new class(lexeme, precedence, type, line, column) UnaryOperator {
    this(dstring lexeme, long precedence, string type, long line, long column) {
      super(lexeme, precedence, type, line, column);
    }
    override long compute(long x) {
      return unaryFun!fun(x);
    }
    override protected Operator make(long line, long column) const {
      return makeUnaryOperator!fun(this.lexeme, this.precedence, this.type, line, column);
    }
  };
}

unittest {
  writeln(__FILE__, ": test UnaryOperator");

  UnaryOperator plusOp = makeUnaryOperator!"+a"("+", 200, "fy");
  UnaryOperator multOp = makeUnaryOperator!"-a"("-", 200, "fy");

  assert(plusOp.compute(10) == +10);
  assert(multOp.compute(10) == -10);
  assert(multOp.compute(multOp.compute(10)) == -(-10));
}
