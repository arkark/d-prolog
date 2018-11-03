module dprolog.data.token.operator.UnaryOperator;

import dprolog.data.token;

import std.stdio;
import std.format;
import std.functional;

abstract class UnaryOperator : Operator {
  private this(dstring lexeme, long precedence, string type, long line, long column)  {
    super(lexeme, precedence, type, line, column);
  }
  Number calc(Number x);
  override string toString() const {
    return format!"UnaryOperator(lexeme: \"%s\", precedence: %s, type: %s)"(lexeme, precedence, type);
  }
}

UnaryOperator makeUnaryOperator(alias fun)(dstring lexeme, long precedence, string type, long line = -1, long column = -1)
if (is(typeof(unaryFun!fun(Number.init)) == Number)) {
  return new class(lexeme, precedence, type, line, column) UnaryOperator {
    this(dstring lexeme, long precedence, string type, long line, long column) {
      super(lexeme, precedence, type, line, column);
    }
    override Number calc(Number x) {
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
  UnaryOperator subOp = makeUnaryOperator!"-a"("-", 200, "fy");

  import std.bigint;
  Number num(long value) {
    return new Number(BigInt(value));
  }

  assert(plusOp.calc(num(10)) == num(+10));
  assert(subOp.calc(num(10)) == num(-10));
  assert(subOp.calc(subOp.calc(num(10))) == num(-(-10)));
}
