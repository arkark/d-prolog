module dprolog.engine.Executor;

import dprolog.data.Token;
import dprolog.data.Term;
import dprolog.data.Clause;
import dprolog.data.Variant;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.converter.Parser;
import dprolog.converter.ClauseBuilder;
import dprolog.util.functions;
import dprolog.util.UnionFind;
import dprolog.util.Maybe;
import dprolog.engine.Engine;

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

  Clause[] _storage;

  alias UF = UnionFind!(
    Variant,
    (Variant a, Variant b) => !a.isVariable ? -1 : !b.isVariable ? 1 : 0
  );

public:
  this(Engine engine) {
    _engine = engine;
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
    clear();
  }

  void execute(dstring src) in {
    assert(!_engine.isHalt);
  } do {
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
      _engine.addMessage(format!"execute: %s"(clause));
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
    UF unionFind = buildUnionFind(query, first, second);
    UF[] result = unificate(first, unionFind);
    if (query.first.isDetermined) {
      _engine.addMessage((!result.empty).to!string ~ ".");
    } else {
      _engine.addMessage((!result.empty).to!string ~ ".");

      // temporary code
      string[] rec(Variant v, UF uf) {
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
        _engine.addMessage(rec(first, uf).join(", ") ~ end);
      }
    }
  }

  UF[] unificate(Variant variant, UF unionFind) {
    const Term term = variant.term;
    if (term.token == Operator.comma) {
      // conjunction
      UF[] ufs = unificate(variant.children.front, unionFind);
      return ufs.map!(
        uf => unificate(variant.children.back, uf)
      ).join.array;
    } else if (term.token == Operator.semicolon) {
      // disjunction
      UF[] ufs1 = unificate(variant.children.front, unionFind);
      UF[] ufs2 = unificate(variant.children.back, unionFind);
      return ufs1 ~ ufs2;
    } else {
      UF[] ufs;
      foreach(clause; _storage) {
        Variant first, second;
        UF newUnionFind = unionFind ~ buildUnionFind(clause, first, second);
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

  bool match(Variant left, Variant right, UF unionFind) {

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

  UF buildUnionFind(Clause clause, ref Variant first, ref Variant second) {
    static long idGen = 0;
    static long idGen_underscore = 0;
    const long id = ++idGen;

    UF uf = new UF;

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
