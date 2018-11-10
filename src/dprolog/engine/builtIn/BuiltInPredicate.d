module dprolog.engine.builtIn.BuiltInPredicate;

import dprolog.data.Term;
import dprolog.data.Variant;
import dprolog.data.Predicate;
import dprolog.engine.UnificationUF;
import dprolog.engine.builtIn.BuiltIn;

import std.typecons;
import std.concurrency : yield;

@property BuiltInPredicate_ BuiltInPredicate() {
  static BuiltInPredicate_ instance;
  if (!instance) {
    instance = new BuiltInPredicate_();
  }
  return instance;
}

private class BuiltInPredicate_ : BuiltIn {
  alias UnificateResult = Tuple!(bool, "found", bool, "isCutted");
  alias UnificateRecFun = Predicate.UnificateRecFun;

private:
  Predicate[] _predicates;

public:
  this() {
    super();
    setPredicates();
  }

  UnificateResult unificateTraverse(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
    const Term term = variant.term;
    foreach(predicate; _predicates) {
      if (predicate.isMatch(term)) {
        return UnificateResult(
          true,
          predicate.unificate(variant, unionFind, unificateRecFun)
        );
      }
    }
    return UnificateResult(false, false);
  }

private:
  void setPredicates() {
    // cut
    auto cut = buildPredicate(
      "!",
      0,
      (Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        unionFind.yield;
        return true; // cut flag
      }
    );

    _predicates = [
      cut,
    ];
  }

  Predicate buildPredicate(
    dstring lexeme,
    size_t arity,
    bool delegate(Variant, UnificationUF, UnificateRecFun) unificateFun
  ) {
    return new class() Predicate {

      override bool isMatch(const Term term) {
        return term.isAtom && term.token.lexeme == lexeme && term.children.length == arity;
      }

      override bool unificate(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        return unificateFun(variant, unionFind, unificateRecFun);
      }

    };
  }
}
