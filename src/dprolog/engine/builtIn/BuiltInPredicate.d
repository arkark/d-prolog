module dprolog.engine.builtIn.BuiltInPredicate;

import dprolog.data.Term;
import dprolog.data.Variant;
import dprolog.data.Predicate;
import dprolog.engine.Executor;
import dprolog.engine.UnificationUF;
import dprolog.engine.builtIn.BuiltIn;

import std.range;
import std.concurrency : Generator, yield;

@property BuiltInPredicate_ BuiltInPredicate() {
  static BuiltInPredicate_ instance;
  if (!instance) {
    instance = new BuiltInPredicate_();
  }
  return instance;
}

private class BuiltInPredicate_ : BuiltIn {
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
        auto result = predicate.unificate(variant, unionFind, unificateRecFun);
        if (result.found) return result;
      }
    }
    return UnificateResult(false, false);
  }

private:
  void setPredicates() {
    // cut
    auto cutPred = buildPredicate(
      "!", 0,
      delegate UnificateResult(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        unionFind.yield;
        return UnificateResult(true, true);
      }
    );

    // true
    auto truePred = buildPredicate(
      "true", 0,
      delegate UnificateResult(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        unionFind.yield;
        return UnificateResult(true, false);
      }
    );

    // false
    auto falsePred = buildPredicate(
      "false", 0,
      delegate UnificateResult(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        return UnificateResult(false, false);
      }
    );

    // fail
    auto failPred = buildPredicate(
      "fail", 0,
      delegate UnificateResult(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        return UnificateResult(false, false);
      }
    );

    // repeat
    auto repeatPred = buildPredicate(
      "repeat", 0,
      delegate UnificateResult(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        while(true) {
          unionFind.yield;
        }
      }
    );

    // not
    auto notPred = buildPredicate(
      "not", 1,
      delegate UnificateResult(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        assert(variant.children.length == 1);
        auto child = variant.children.front;

        auto g = new Generator!UnificationUF({
          unificateRecFun(child, unionFind);
        }, 1<<20);
        if(g.empty) {
          unionFind.yield;
          return UnificateResult(true, false);
        } else {
          return UnificateResult(false, false);
        }
      }
    );

    _predicates = [
      cutPred,
      truePred,
      falsePred,
      failPred,
      repeatPred,
      notPred,
    ];
  }

  Predicate buildPredicate(
    dstring lexeme,
    size_t arity,
    UnificateResult delegate(Variant, UnificationUF, UnificateRecFun) unificateFun
  ) {
    return new class() Predicate {

      override bool isMatch(const Term term) {
        return term.isAtom && term.token.lexeme == lexeme && term.children.length == arity;
      }

      override UnificateResult unificate(Variant variant, UnificationUF unionFind, UnificateRecFun unificateRecFun) {
        return unificateFun(variant, unionFind, unificateRecFun);
      }

    };
  }
}
