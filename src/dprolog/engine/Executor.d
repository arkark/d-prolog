module dprolog.engine.Executor;

import dprolog.data.token;
import dprolog.data.Term;
import dprolog.data.Clause;
import dprolog.data.Variant;
import dprolog.data.Message;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.converter.Parser;
import dprolog.converter.ClauseBuilder;
import dprolog.util.functions;
import dprolog.util.UnionFind;
import dprolog.util.Maybe;
import dprolog.util.Either;
import dprolog.engine.Engine;
import dprolog.engine.Evaluator;
import dprolog.engine.UnificationUF;

import std.format;
import std.conv;
import std.range;
import std.array;
import std.algorithm;
import std.functional;

class Executor {

private:
  Engine _engine;

  Lexer _lexer;
  Parser _parser;
  ClauseBuilder _clauseBuilder;

  Evaluator _evaluator;

  Clause[] _storage;

public:
  this(Engine engine) {
    _engine = engine;
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
    _evaluator = new Evaluator;
    clear();
  }

  void execute(dstring src) in(!_engine.isHalt) do {
    toClauseList(src).apply!((clauseList) {
      foreach(clause; clauseList) {
        if (_engine.isHalt) break;
        executeClause(clause);
      }
    });
  }

  void clear() {
    _lexer.clear;
    _parser.clear;
    _clauseBuilder.clear;
    _storage = [];
  }

private:
  Maybe!(Clause[]) toClauseList(dstring src) {
    auto convert(S, T)(Converter!(S, T) converter) {
      return (S src) {
        converter.run(src);
        if (converter.hasError) {
          _engine.addMessage(converter.errorMessage);
          return None!T;
        }
        return converter.get.Just;
      };
    }
    return Just(src).bind!(
      a => convert(_lexer)(a)
    ).bind!(
      a => convert(_parser)(a)
    ).bind!(
      a => convert(_clauseBuilder)(a)
    );
  }

  void executeClause(Clause clause) {
    if (_engine.verboseMode) {
      _engine.addMessage(Message(format!"execute: %s"(clause)));
    }
    clause.castSwitch!(
      (Fact fact)   => executeFact(fact),
      (Rule rule)   => executeRule(rule),
      (Query query) => executeQuery(query)
    );
  }

  void executeFact(Fact fact) {
    if (_engine.traverseBuiltIn(fact.first)) {
      // when matching a built-in pattern
      return;
    }
    _storage ~= fact;
  }

  void executeRule(Rule rule) {
    _storage ~= rule;
  }

  void executeQuery(Query query) {
    if (_engine.traverseBuiltIn(query.first)) {
      // when matching a built-in pattern
      return;
    }

    Variant first, second;
    UnificationUF unionFind = buildUnionFind(query, first, second);
    UnificationUF[] result = unificate(first, unionFind);
    if (query.first.isDetermined) {
      _engine.addMessage(Message((!result.empty).to!string ~ "."));
    } else {
      _engine.addMessage(Message((!result.empty).to!string ~ "."));

      // temporary code
      string[] rec(Variant v, UnificationUF uf) {
        if (v.isVariable) {
          Variant root = uf.root(v);
          return [[
            v.term.to!string,
            "=",
            {
              Term po(Variant var) {
                return new Term(
                  var.term.token,
                  var.children.map!(
                    c => c.isVariable ? uf.root(c).pipe!po : c.term
                  ).array
                );
              }

              return root.pipe!po.to!string;
            }()
          ].join(" ")];
        } else {
          return v.children.map!(u => rec(u, uf)).join.array;
        }
      }

      foreach(i, uf; result) {
        string end = i==result.length-1 ? "." : ";";
        _engine.addMessage(Message(rec(first, uf).join(", ") ~ end));
      }
    }
  }

  UnificationUF[] unificate(Variant variant, UnificationUF unionFind) {
    const Term term = variant.term;
    if (term.token == Operator.comma) {
      // conjunction
      UnificationUF[] ufs = unificate(variant.children.front, unionFind);
      return ufs.map!(
        uf => unificate(variant.children.back, uf)
      ).join.array;
    } else if (term.token == Operator.semicolon) {
      // disjunction
      UnificationUF[] ufs1 = unificate(variant.children.front, unionFind);
      UnificationUF[] ufs2 = unificate(variant.children.back, unionFind);
      return ufs1 ~ ufs2;
    } else if (term.token == Operator.equal) {
      // unification
      UnificationUF newUnionFind = unionFind.clone;
      if (match(variant.children.front, variant.children.back, newUnionFind)) {
        return [newUnionFind];
      } else {
        return [];
      }
    } else if (term.token == Operator.eval) {
      // arithmetic evaluation
      auto result = _evaluator.calc(variant.children.back, unionFind);
      if (result.isLeft) {
        _engine.addMessage(result.left);
        return [];
      } else {
        Number y = result.right;
        Variant xVar = unionFind.root(variant.children.front);
        return xVar.term.token.castSwitch!(
          (Variable x) {
            UnificationUF newUnionFind = unionFind.clone;
            Variant yVar = new Variant(-1, new Term(y, []), []);
            newUnionFind.add(yVar);
            newUnionFind.unite(xVar, yVar);
            return [newUnionFind];
          },
          (Number x) => x == y ? [unionFind] : [],
          (Object _) => new UnificationUF[0]
        );
      }
    } else if (term.token.instanceOf!ComparisonOperator) {
      // arithmetic comparison
      auto op = cast(ComparisonOperator) term.token;
      auto result = _evaluator.calc(variant.children.front, unionFind).bind!(
        x => _evaluator.calc(variant.children.back, unionFind).fmap!(
          y => op.calc(x, y)
        )
      );
      if (result.isLeft) {
        _engine.addMessage(result.left);
        return [];
      } else {
        return result.right ? [unionFind] : [];
      }
    } else {
      UnificationUF[] ufs;
      foreach(clause; _storage) {
        Variant first, second;
        UnificationUF newUnionFind = unionFind ~ buildUnionFind(clause, first, second);
        if (match(variant, first, newUnionFind)) {
          ufs ~= clause.castSwitch!(
            (Fact fact) => [newUnionFind],
            (Rule rule) => unificate(second, newUnionFind)
          );
        }
      }
      return ufs;
    }
  }

  bool match(Variant left, Variant right, UnificationUF unionFind) {

    if (!left.isVariable && !right.isVariable) {
      return left.term.token == right.term.token && left.children.length==right.children.length && zip(left.children, right.children).all!(a => match(a[0], a[1], unionFind));
    } else {
      Variant l = unionFind.root(left);
      Variant r = unionFind.root(right);
      if (unionFind.same(l, r)) {
        return true;
      } else if (!l.isVariable && !r.isVariable) {
        return match(l, r, unionFind);
      } else {
        unionFind.unite(l, r);
        return true;
      }
    }
  }

  UnificationUF buildUnionFind(Clause clause, ref Variant first, ref Variant second) {
    static long idGen = 0;
    static long idGen_underscore = 0;
    const long id = ++idGen;

    UnificationUF uf = new UnificationUF;

    Variant rec(Term term) {
      Variant v = new Variant(
        term.token.isUnderscore ? ++idGen_underscore :
        term.isVariable         ? id
                                : -1,
        term,
        term.children.map!(c => rec(c)).array
      );
      uf.add(v);
      return v;
    }

    clause.castSwitch!(
      (Fact fact) {
        first = rec(fact.first);
      },
      (Rule rule) {
        first = rec(rule.first);
        second = rec(rule.second);
      },
      (Query query) {
        first = rec(query.first);
      }
    );

    return uf;
  }

  invariant {
    assert(_storage.all!(clause => clause.instanceOf!Fact || clause.instanceOf!Rule));
  }

}
