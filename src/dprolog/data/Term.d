module dprolog.data.Term;

import dprolog.data.token;
import dprolog.util.functions;

import std.stdio;
import std.format;
import std.algorithm;
import std.range;

class Term {
  Token token;
  Term[] children;
  immutable bool isDetermined;
  immutable bool isCompound;

  this(Token token, Term[] children) {
    this.token = token;
    this.children = children;
    this.isDetermined = (token.instanceOf!Atom && children.all!(c => c.isDetermined)) || token.instanceOf!Number;
    this.isCompound = token==Operator.comma || token==Operator.semicolon;
  }

  @property bool isAtom() const {
    return token.instanceOf!Atom && !token.instanceOf!Functor && !token.instanceOf!Operator;
  }

  @property bool isNumber() const {
    return token.instanceOf!Number;
  }

  @property bool isVariable() const {
    return token.instanceOf!Variable;
  }

  @property bool isStructure() const {
    return token.instanceOf!Functor || token.instanceOf!Operator;
  }

  override string toString() const {
    if (isCompound) {
      return format!"( %s %s %s )"(children.front, token.lexeme, children.back);
    } else if (isStructure) {
      if (token == Operator.pipe) {
        return format!"[%s]"(toListString());
      } else {
        return format!"%s(%-(%s, %))"(token.lexeme, children);
      }
    } else {
      if (token == Atom.emptyList) {
        return "[]";
      } else {
        return format!"%s"(token.lexeme);
      }
    }
  }
  private string toListString() const in {
    assert(token == Operator.pipe);
    assert(children.length == 2);
  } do {
    if (children.back.token == Atom.emptyList) {
      return format!"%s"(children.front);
    } else if (children.back.token == Operator.pipe) {
      return format!"%s, %s"(children.front, children.back.toListString());
    } else {
      return format!"%s%s%s"(children.front, token.lexeme, children.back);
    }
  }

  invariant {
    assert(
      (token.instanceOf!Atom                      ) ||
      (token.instanceOf!Number   && children.empty) ||
      (token.instanceOf!Variable && children.empty)
    );
    assert(token != Operator.rulifier);
    assert(token != Operator.querifier);
    assert(isDetermined == ((token.instanceOf!Atom && children.all!(c => c.isDetermined)) || token.instanceOf!Number));
  }


  /* ---------- Unit Tests ---------- */

  unittest {
    writeln(__FILE__, ": test");

    Atom atom = new Atom("a", -1, -1);
    Number num = new Number("1", -1, -1);
    Variable var = new Variable("X", -1, -1);
    Functor fun = new Functor(atom);
    Operator pipe = cast(Operator) Operator.pipe;
    Operator comma = cast(Operator) Operator.comma;

    Term atomT = new Term(atom, []);
    Term numT = new Term(num, []);
    Term varT = new Term(var, []);
    Term funT = new Term(fun, [atomT, varT, numT]);
    Term listT = new Term(pipe, [funT,  new Term(pipe, [numT, varT])]);
    Term comT = new Term(comma, [listT, funT]);

    assert(atomT.isDetermined);
    assert(numT.isDetermined);
    assert(!varT.isDetermined);
    assert(!funT.isDetermined);
    assert(!listT.isDetermined);
    assert(!listT.children.back.isDetermined);
    assert(!listT.children.back.children.back.isDetermined);
    assert(!comT.isDetermined);

    assert(!atomT.isCompound);
    assert(!numT.isCompound);
    assert(!varT.isCompound);
    assert(!funT.isCompound);
    assert(!listT.isCompound);
    assert(!listT.children.back.isCompound);
    assert(!listT.children.back.children.back.isCompound);
    assert(comT.isCompound);

    import std.range, std.array, std.algorithm, std.functional;
    bool validate(Term term, long index) {
      return term.adjoin!(
        /* case: 0 */ t => t.isAtom,
        /* case: 1 */ t => t.isNumber,
        /* case: 2 */ t => t.isVariable,
        /* case: 3 */ t => t.isStructure
      ).array.enumerate.all!(a => a.value == (a.index == index));
    }

    assert(validate(atomT, 0));
    assert(validate(numT, 1));
    assert(validate(varT, 2));
    assert(validate(funT, 3));
    assert(validate(listT, 3));
    assert(validate(listT.children.back, 3));
    assert(validate(listT.children.back.children.back, 2));
    assert(validate(comT, 3));
  }
}
