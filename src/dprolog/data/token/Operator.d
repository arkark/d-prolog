module dprolog.data.token.Operator;

import dprolog.data.token;
import dprolog.util.Maybe;

import std.functional;
import std.format;
import std.algorithm;
import std.range;

class Operator : Atom {

  immutable long precedence;
  immutable string type;
  Notation notation() @property {
    switch(type) {
      case "fx" : case "fy" :             return Notation.Prefix;
      case "xfx": case "xfy": case "yfx": return Notation.Infix;
      case "xf" : case "yf" :             return Notation.Postfix;
      default: assert(false);
    }
  }

  override bool opEquals(Object o) {
    auto that = cast(Operator) o;
    return that && this.lexeme==that.lexeme && this.precedence==that.precedence && this.type==that.type;
  }

  override string toString() const {
    return format!"Operator(lexeme: \"%s\", precedence: %s, type: %s)"(lexeme, precedence, type);
  }

  static Maybe!Operator getOperator(Atom atom, Notation notation) {
    string[] types = getTypes(notation);
    auto ary = systemOperatorList.find!(
      op => op.lexeme==atom.lexeme && types.canFind(op.type)
    );
    return ary.empty ? None!Operator : Just(ary.front.make(atom.line, atom.column));
  }

  static private string[] getTypes(Notation notation) {
    final switch(notation) {
      case Notation.Prefix  : return ["fx", "fy"];
      case Notation.Infix   : return ["xfx", "xfy", "yfx"];
      case Notation.Postfix : return ["xf", "yf"];
    }
  }

  private this(dstring lexeme, long precedence, string type, long line = -1, long column = -1)  {
    super(lexeme, line, column);
    this.precedence = precedence;
    this.type = type;
  }

  protected Operator make(long line, long column) const {
    return new Operator(this.lexeme, this.precedence, this.type, line, column);
  }

  enum Notation {
    Prefix, Infix, Postfix
  }

  static immutable {
    Operator rulifier = cast(immutable) new Operator(":-", 1200, "xfx");
    Operator querifier = cast(immutable) new Operator("?-", 1200, "fx");
    Operator semicolon = cast(immutable) new Operator(";", 1100, "xfy");
    Operator comma = cast(immutable) new Operator(",", 1000, "xfy");
    Operator pipe = cast(immutable) new Operator("|", 1100, "xfy");
    Operator equal = cast(immutable) new Operator("=", 700, "xfx");
  }

  static private immutable immutable(Operator)[] systemOperatorList = [
    rulifier,
    querifier,
    semicolon,
    pipe,
    comma,
    equal,
    cast(immutable) new Operator("==", 700, "xfx"),
    cast(immutable) new Operator("<", 700, "xfx"),
    cast(immutable) new Operator("=<", 700, "xfx"),
    cast(immutable) new Operator(">", 700, "xfx"),
    cast(immutable) new Operator(">=", 700, "xfx"),
    cast(immutable) new Operator("=:=", 700, "xfx"),
    cast(immutable) new Operator("=\\=", 700, "xfx"),
    cast(immutable) new Operator("is", 700, "xfx"),
    cast(immutable) new Operator("+", 500, "yfx"),
    cast(immutable) new Operator("-", 500, "yfx"),
    cast(immutable) new Operator("*", 400, "yfx"),
    cast(immutable) new Operator("div", 400, "yfx"),
    cast(immutable) new Operator("mod", 400, "yfx"),
    cast(immutable) new Operator("+", 200, "fy"),
    cast(immutable) new Operator("-", 200, "fy")
  ];

}
