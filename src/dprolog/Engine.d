
module dprolog.Engine;

import dprolog.data.Token,
       dprolog.data.Term,
       dprolog.data.Clause,
       dprolog.data.Variant,
       dprolog.converter.Converter,
       dprolog.converter.Lexer,
       dprolog.converter.Parser,
       dprolog.converter.ClauseBuilder,
       dprolog.util.util,
       dprolog.util.UnionFind;

import std.stdio,
       std.conv,
       std.range,
       std.array,
       std.algorithm,
       std.typecons,
       std.functional,
       std.container : DList;

class Engine {

private:
  Lexer _lexer                 = new Lexer;
  Parser _parser               = new Parser;
  ClauseBuilder _clauseBuilder = new ClauseBuilder;

  Clause[] _storage;

  alias UF = UnionFind!(
    Variant,
    (Variant a, Variant b) => !a.isVariable ? -1 : !b.isVariable ? 1 : 0
  );

  DList!dstring _messageList;

public:
  this() {
    clear();
  }

  void execute(dstring src) {
    clearMessage();
    Clause[] clauseList = toClauseList(src);
    if (clauseList !is null) {
      clauseList.each!(clause => executeClause(clause));
    }
  }

  bool emptyMessage() {
    return _messageList.empty;
  }

  void showMessage() in {
    assert(!emptyMessage);
  } do {
    writeln(_messageList.front);
    _messageList.removeFront;
  }

  void clear() {
    _lexer.clear;
    _parser.clear;
    _clauseBuilder.clear;
    _storage = [];
    clearMessage();
  }

private:

  Clause[] toClauseList(dstring src) {
    auto convert(S, T)(Converter!(S, T) converter) {
      return (S src) {
        if (src is null) return null;
        converter.run(src);
        if (converter.hasError) {
          addMessage(converter.errorMessage);
          return null;
        }
        return converter.get;
      };
    }
    return src.pipe!(
      a => convert(_lexer)(a),
      a => convert(_parser)(a),
      a => convert(_clauseBuilder)(a)
    );
  }

  void executeClause(Clause clause) {
    writeln("execute: ", clause); //
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
    Variant first, second;
    UF unionFind = buildUnionFind(query, first, second);
    if (query.first.isDetermined) {
      addMessage(first.pipe!isTrue(unionFind).to!string ~ ".");
    } else {
      addMessage(first.pipe!isTrue(unionFind).to!string ~ ".");

      // temporary code
      string[] rec(Variant v) {
        if (v.isVariable) {
          Variant root = unionFind.root(v);
          return [[
            v.term.to!string,
            "=",
            {
              Term po(Variant var) {
                return new Term(
                  var.term.token,
                  var.children.map!(
                    c => c.isVariable ? unionFind.root(c).pipe!po : c.term
                  ).array
                );
              }

              return root.pipe!po.to!string;
            }()
          ].join(" ")];
        } else {
          return v.children.map!rec.join.array;
        }
      }

      addMessage(first.pipe!rec.join(", ") ~ ".");
    }
  }

  bool isTrue(Variant variant, ref UF unionFind) {
    const Term term = variant.term;
    if (term.token == Operator.comma) {
      // conjunction
      return variant.children.front.pipe!isTrue(unionFind) && variant.children.back.pipe!isTrue(unionFind);
    } else if (term.token == Operator.semicolon) {
      // disjunction
      return variant.children.front.pipe!isTrue(unionFind) || variant.children.back.pipe!isTrue(unionFind);
    } else {
      foreach(clause; _storage) {
        Variant first, second;
        UF newUnionFind = unionFind ~ buildUnionFind(clause, first, second);
        bool flag = clause.castSwitch!(
          (Fact fact)   => match(variant, first, newUnionFind),
          (Rule rule)   => match(variant, first, newUnionFind) && second.pipe!isTrue(newUnionFind)
        );
        if (flag) {
          unionFind = newUnionFind;
          return true;
        }
      }
      return false;
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

  void addMessage(T)(T message) {
    _messageList.insertBack(message.to!dstring);
  }

  void clearMessage() {
    _messageList.clear;
  }

  invariant {
    assert(_storage.all!(clause => clause.instanceOf!Fact || clause.instanceOf!Rule));
  }

  /*unittest {
    writeln(__FILE__, ": test");

    dstring src1 = "hoge(aaa). po(X, Y) :- hoge(X), hoge(Y).";
    dstring src2 = "?- po(aaa)."; // => true
    dstring src3 = "?- po(X, Y)."; // => false

    Engine engine = new Engine;
    engine.execute(src1);
    engine.execute(src2);
    while(!engine.emptyMessage) engine.showMessage;
    engine.execute(src3);
    while(!engine.emptyMessage) engine.showMessage;
  }*/

}
