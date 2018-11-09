module dprolog.engine.Executor;

import dprolog.data.token;
import dprolog.data.Term;
import dprolog.data.Clause;
import dprolog.data.Variant;
import dprolog.util.Message;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.converter.Parser;
import dprolog.converter.ClauseBuilder;
import dprolog.util.functions;
import dprolog.util.Maybe;
import dprolog.util.Either;
import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.engine.builtIn.BuiltInCommand;
import dprolog.engine.Evaluator;
import dprolog.engine.UnificationUF;
import dprolog.core.Linenoise;

import std.format;
import std.conv;
import std.range;
import std.array;
import std.algorithm;
import std.functional;
import std.concurrency : Generator, yield;

@property Executor_ Executor() {
  static Executor_ instance;
  if (!instance) {
    instance = new Executor_();
  }
  return instance;
}

private class Executor_ {

private:
  Lexer _lexer;
  Parser _parser;
  ClauseBuilder _clauseBuilder;

  Clause[] _storage;

public:
  this() {
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
    clear();
  }

  void execute(dstring src) in(!Engine.isHalt) do {
    toClauseList(src).apply!((clauseList) {
      foreach(clause; clauseList) {
        if (Engine.isHalt) break;
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
          Messenger.add(converter.errorMessage);
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
    if (Engine.verboseMode) {
      Messenger.writeln(VerboseMessage(format!"execute: %s"(clause)));
    }
    clause.castSwitch!(
      (Fact fact)   => executeFact(fact),
      (Rule rule)   => executeRule(rule),
      (Query query) => executeQuery(query)
    );
  }

  void executeFact(Fact fact) {
    _storage ~= fact;
  }

  void executeRule(Rule rule) {
    _storage ~= rule;
  }

  void executeQuery(Query query) {
    if (BuiltInCommand.traverse(query.first)) {
      // when matching a built-in pattern
      return;
    }

    Variant first, second;
    UnificationUF unionFind = buildUnionFind(query, first, second);
    auto result = new Generator!UnificationUF(
      () => unificate(first, unionFind),
      1<<20
    );
    if (query.first.isDetermined) {
      Messenger.writeln(DefaultMessage((!result.empty).to!string ~ "."));
    } else {

      string[] rec(Variant v, UnificationUF uf, ref bool[string] exists) {
        if (v.isVariable && !v.term.token.isUnderscore) {
          Variant root = uf.root(v);
          string lexeme = v.term.to!string;
          if (lexeme in exists) {
            return [];
          } else {
            exists[lexeme] = true;
          }
          return [
            lexeme,
            "=",
            {
              Term f(Variant var) {
                if (var.isVariable) {
                  auto x = uf.root(var);
                  return x == var ? x.term : x.pipe!f;
                } else {
                  return new Term(
                    var.term.token,
                    var.children.map!f.array
                  );
                }
              }

              return root.pipe!f.to!string;
            }()
          ].join(" ").only.array;
        } else {
          return v.children.map!(u => rec(u, uf, exists)).join.array;
        }
      }

      if (result.empty) {
        Messenger.showAll();
        Messenger.writeln(DefaultMessage("false."));
      } else {

        if (query.hasOnlyUnderscore()) {
          Messenger.showAll();
          Messenger.writeln(DefaultMessage("true."));
        } else {

          while(!result.empty) {
            auto uf = result.front;
            result.popFront;
            Messenger.showAll();
            bool[string] exists;
            string answer = rec(first, uf, exists).join(", ");
            if (result.empty) {
              Messenger.writeln(DefaultMessage(answer ~ "."));
            } else {
              auto line = Linenoise.nextLine(answer ~ "; ");
              if (line.isJust) {
              } else {
                Messenger.writeln(InfoMessage("% Execution Aborted"));
                break;
              }
            }
          }

        }

      }
    }
  }

  // fiber function
  void unificate(Variant variant, UnificationUF unionFind) {
    const Term term = variant.term;
    if (term.token == Operator.comma) {
      // conjunction
      new Generator!UnificationUF(
        () => unificate(variant.children.front, unionFind),
        1<<20
      ).array.each!(
        uf => unificate(variant.children.back, uf)
      );
    } else if (term.token == Operator.semicolon) {
      // disjunction
      unificate(variant.children.front, unionFind);
      unificate(variant.children.back, unionFind);
    } else if (term.token == Operator.equal) {
      // unification
      UnificationUF newUnionFind = unionFind.clone;
      if (match(variant.children.front, variant.children.back, newUnionFind)) {
        newUnionFind.yield;
      }
    } else if (term.token == Operator.equalEqual) {
      // equality comparison
      if (unionFind.same(variant.children.front, variant.children.back)) {
        unionFind.yield;
      }
    } else if (term.token == Operator.eval) {
      // arithmetic evaluation
      auto result = Evaluator.calc(variant.children.back, unionFind);
      if (result.isLeft) {
        Messenger.add(result.left);
      } else {
        Number y = result.right;
        Variant xVar = unionFind.root(variant.children.front);
        xVar.term.token.castSwitch!(
          (Variable x) {
            UnificationUF newUnionFind = unionFind.clone;
            Variant yVar = new Variant(-1, new Term(y, []), []);
            newUnionFind.add(yVar);
            newUnionFind.unite(xVar, yVar);
            newUnionFind.yield;
          },
          (Number x) {
            if (x == y) unionFind.yield;
          },
          (Object _) {
          }
        );
      }
    } else if (term.token.instanceOf!ComparisonOperator) {
      // arithmetic comparison
      auto op = cast(ComparisonOperator) term.token;
      auto result = Evaluator.calc(variant.children.front, unionFind).bind!(
        x => Evaluator.calc(variant.children.back, unionFind).fmap!(
          y => op.calc(x, y)
        )
      );
      if (result.isLeft) {
        Messenger.add(result.left);
      } else {
        if (result.right) unionFind.yield;
      }
    } else {
      foreach(clause; _storage) {
        Variant first, second;
        UnificationUF newUnionFind = unionFind ~ buildUnionFind(clause, first, second);
        if (match(variant, first, newUnionFind)) {
          clause.castSwitch!(
            (Fact fact) => newUnionFind.yield,
            (Rule rule) => unificate(second, newUnionFind)
          );
        }
      }
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
