module dprolog.engine.Engine;

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
import dprolog.engine.BuiltIn;
import dprolog.engine.Reader;

import std.stdio;
import std.format;
import std.conv;
import std.range;
import std.array;
import std.algorithm;
import std.typecons;
import std.functional;
import std.container : DList;

class Engine {

private:
  Lexer _lexer;
  Parser _parser;
  ClauseBuilder _clauseBuilder;

  BuildIn _builtIn;
  Reader _reader;

  Clause[] _storage;

  alias UF = UnionFind!(
    Variant,
    (Variant a, Variant b) => !a.isVariable ? -1 : !b.isVariable ? 1 : 0
  );

  DList!dstring _messageList;

  bool _isHalt = false;
  bool _verboseMode = false;

public:
  this() {
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
    _builtIn = new BuildIn(this);
    _reader = new Reader(this);
    clear();
  }

  void execute(dstring src) in {
    assert(!isHalt);
  } do {
    clearMessage();
    Clause[] clauseList = toClauseList(src);
    if (clauseList !is null) {
      foreach(clause; clauseList) {
        if (isHalt) break;
        executeClause(clause);
      }
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

  void halt() {
    _isHalt = true;
  }

  bool isHalt() @property {
    return _isHalt;
  }

  void setVerbose(bool verbose) {
    _verboseMode = verbose;
  }

  void readFile(dstring filePath) {
    _reader.read(filePath);
  }

  void addMessage(T)(T message) {
    _messageList.insertBack(message.to!dstring);
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
    if (_verboseMode) {
      addMessage(format!"execute: %s"(clause));
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
    if (_builtIn.traverse(query.first)) {
      // when matching a built-in pattern
      return;
    }

    Variant first, second;
    UF unionFind = buildUnionFind(query, first, second);
    UF[] result = unificate(first, unionFind);
    if (query.first.isDetermined) {
      addMessage((!result.empty).to!string ~ ".");
    } else {
      addMessage((!result.empty).to!string ~ ".");

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
        addMessage(rec(first, uf).join(", ") ~ end);
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
