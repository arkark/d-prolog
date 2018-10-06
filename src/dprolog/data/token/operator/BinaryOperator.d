module dprolog.data.token.operator.BinaryOperator;

import dprolog.data.token;

import std.stdio;
import std.functional;

abstract class BinaryOperator : Operator {
  private this(dstring lexeme, long precedence, string type, long line, long column)  {
    super(lexeme, precedence, type, line, column);
  }
  Number calc(Number x, Number y);
}

BinaryOperator makeBinaryOperator(alias fun)(dstring lexeme, long precedence, string type, long line = -1, long column = -1)
if (is(typeof(binaryFun!fun(Number.init, Number.init)) == Number)) {
  return new class(lexeme, precedence, type, line, column) BinaryOperator {
    this(dstring lexeme, long precedence, string type, long line, long column) {
      super(lexeme, precedence, type, line, column);
    }
    override Number calc(Number x, Number y) {
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

  Number num(long value) {
    return new Number(value);
  }

  assert(plusOp.calc(num(121), num(12)) == num(121 + 12));
  assert(multOp.calc(num(921), num(19)) == num(921 * 19));
}
