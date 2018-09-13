module dprolog.data.Token;

import dprolog.util.functions;

import std.conv;
import std.format;
import std.range;
import std.algorithm;
import std.functional;
import std.typecons;

/*

Token -> Atom | Number | Variable | Operator | LParen | RParen | LBracket | RBracket | Period

*/

abstract class Token {

  static immutable dstring specialCharacters = ":?&;,|=<>+-*/\\";

  immutable long line;
  immutable long column;
  immutable dstring lexeme;
  this(dstring lexeme, long line, long column) {
    this.lexeme = lexeme;
    this.line = line;
    this.column = column;
  }

  bool isUnderscore() {
    return lexeme == "_";
  }

  override hash_t toHash() {
    hash_t hash = 0u;
    foreach(c; lexeme) {
      hash = c.hashOf(hash);
    }
    return hash;
  }

  override string toString() const {
    return format!"Token(lexeme: \"%s\")"(lexeme);
  }

}

class Atom : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    auto that = cast(Atom) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Atom(lexeme: \"%s\")"(lexeme);
  }

  static immutable Atom emptyAtom = cast(immutable) new Atom("", -1, -1); // 空リストに用いる

}

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

class Variable : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    auto that = cast(Variable) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Variable(lexeme: \"%s\")"(lexeme);
  }
}

class Functor : Atom {

  this(Atom atom) {
    super(atom.lexeme, atom.line, atom.column);
  }

  override bool opEquals(Object o) {
    auto that = cast(Functor) o;
    return that && this.lexeme==that.lexeme;
  }

  override string toString() const {
    return format!"Functor(lexeme: \"%s\")"(lexeme);
  }

}

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

  static Operator getOperator(Atom atom, Notation notation) {
    string[] types = getTypes(notation);
    auto ary = systemOperatorList.find!(
      op => op.lexeme==atom.lexeme && types.canFind(op.type)
    );
    return ary.empty ? null : new Operator(ary.front, atom.line, atom.column);
  }

  static private string[] getTypes(Notation notation) {
    final switch(notation) {
      case Notation.Prefix  : return ["fx", "fy"];
      case Notation.Infix   : return ["xfx", "xfy", "yfx"];
      case Notation.Postfix : return ["xf", "yf"];
    }
  }

  private this(immutable Operator op, long line, long column) {
    super(op.lexeme, line, column);
    this.precedence = op.precedence;
    this.type = op.type;
  }

  private this(dstring lexeme, long precedence, string type)  {
    super(lexeme, -1, -1);
    this.precedence = precedence;
    this.type = type;
  }

  enum Notation {
    Prefix, Infix, Postfix
  }

  static immutable Operator rulifier    = cast(immutable) new Operator(":-", 1200, "xfx");
  static immutable Operator querifier   = cast(immutable) new Operator("?-", 1200, "fx");
  static immutable Operator semicolon = cast(immutable) new Operator(";", 1100, "xfy");
  static immutable Operator comma = cast(immutable) new Operator(",", 1000, "xfy");
  static immutable Operator pipe        = cast(immutable) new Operator("|", 1100, "xfy");

  static private immutable immutable(Operator)[] systemOperatorList = [
    rulifier,
    querifier,
    semicolon,
    pipe,
    comma,
    cast(immutable) new Operator("=", 700, "xfx"),
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

class LParen : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"LParen(lexeme: \"%s\")"(lexeme);
  }

}

class RParen : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"RParen(lexeme: \"%s\")"(lexeme);
  }

}

class LBracket : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"LBracket(lexeme: \"%s\")"(lexeme);
  }

}

class RBracket : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"RBracket(lexeme: \"%s\")"(lexeme);
  }

}

class Period : Token {

  this(dstring lexeme, long line, long column) {
    super(lexeme, line, column);
  }

  override bool opEquals(Object o) {
    return true;
  }

  override string toString() const {
    return format!"Period(lexeme: \"%s\")"(lexeme);
  }

}
