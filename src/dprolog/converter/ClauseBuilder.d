module dprolog.converter.ClauseBuilder;

import dprolog.data.token;
import dprolog.data.AST;
import dprolog.data.Clause;
import dprolog.data.Term;
import dprolog.data.Message;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.converter.Parser;
import dprolog.util.functions;

import std.stdio;
import std.conv;
import std.range;
import std.array;
import std.algorithm;
import std.functional;
import std.container : DList;

// ClauseBuilder: ASTRoot -> Clause[]

class ClauseBuilder : Converter!(ASTRoot, Clause[]) {

private:
  bool _isBuilded;
  DList!Clause _resultClauses;

  bool _hasError;
  Message _errorMessage;

public:

  this() {
    clear();
  }

  void run(ASTRoot astRoot) {
    clear();
    build(astRoot);
  }

  Clause[] get() in {
    assert(_isBuilded);
  } do {
    return _resultClauses.array;
  }

  void clear() {
    _isBuilded = false;
    _resultClauses.clear();
    _hasError = false;
  }

  bool hasError() {
    return _hasError;
  }

  Message errorMessage() in {
    assert(hasError);
  } do {
    return _errorMessage;
  }

private:

  void build(ASTRoot astRoot) {
    foreach(ast; astRoot.children) {
      assert(ast.token.instanceOf!Period);
      assert(ast.children.length <= 1);
      if (ast.children.empty) continue;

      Clause clause = ast.children.front.pipe!toClause;
      if (hasError) break;
      _resultClauses.insertBack(clause);
    }
    _isBuilded = true;
  }

  Clause toClause(AST ast) {
    if (ast.pipe!isRule) {
      return ast.pipe!toRule;
    } else if (ast.pipe!isQuery) {
      return ast.pipe!toQuery;
    } else {
      return ast.pipe!toFact;
    }
  }

  bool isRule(AST ast) {
    return ast.token == Operator.rulifier;
  }

  bool isQuery(AST ast) {
    return ast.token == Operator.querifier;
  }

  Fact toFact(AST ast) {
    Term first = ast.pipe!toTerm;
    if (hasError) return null;
    if (first.isCompound) setErrorMessage(ast.tokenList);
    if (hasError) return null;
    return new Fact(first);
  }

  Rule toRule(AST ast) {
    assert(ast.children.length == 2);
    Term first  = ast.children.front.pipe!toTerm;
    Term second = ast.children.back.pipe!toTerm;
    if (hasError) return null;
    if (first.isCompound) setErrorMessage(ast.tokenList);
    if (hasError) return null;
    return new Rule(first, second);
  }

  Query toQuery(AST ast) {
    assert(ast.children.length == 1);
    Term first = ast.children.front.pipe!toTerm;
    if (hasError) return null;
    return new Query(first);
  }

  Term toTerm(AST ast) {
    if (ast.token.instanceOf!Functor) {
      // Structure
      assert(ast.children.length==1);
      return ast.children.front.pipe!toArguments.pipe!(
        children => hasError ? null : new Term(ast.token, children)
      );
    } else if (ast.token.instanceOf!Operator) {
      // Operator
      if (
        ast.token == Operator.rulifier  ||
        ast.token == Operator.querifier ||
        ast.token == Operator.pipe
      ) {
        setErrorMessage(ast.tokenList);
        return null;
      }
      assert(ast.children.length==1 || ast.children.length==2);
      return ast.children.map!(c => c.pipe!toTerm).array.pipe!(
        children => hasError ? null : new Term(ast.token, children)
      );
    } else if (ast.token.instanceOf!LBracket) {
      // List
      assert(ast.children.length == 1);
      return ast.children.front.pipe!toList;
    } else {
      // Atom, Number, Variable
      assert(ast.children.empty);
      return new Term(ast.token, []);
    }
  }

  Term[] toArguments(AST ast) {
    if (ast.token == Operator.comma) {
      assert(ast.children.length == 2);
      return ast.children.front.pipe!toArguments ~ ast.children.back.pipe!toArguments;
    } else {
      return [ast.pipe!toTerm];
    }
  }

  Term toList(AST ast) {
    if (ast.token == Operator.pipe) {
      assert(ast.children.length == 2);

      Term back = ast.children.back.pipe!((b) {
        if (b.token.instanceOf!LBracket) {
          assert(b.children.length == 1);
          Term back = b.children.front.pipe!toList;
          if (hasError) return null;
          if (back.token != Operator.pipe && back.token != Atom.emptyList) {
            Term empty = new Term(cast(Token) Atom.emptyList, []);
            back = new Term(cast(Token) Operator.pipe, [back, empty]);
          }
          return back;
        } else if (ast.children.back.token.instanceOf!Variable) {
          return new Term(ast.children.back.token, []);
        } else {
          setErrorMessage(ast.tokenList);
          return null;
        }
      });
      if (hasError) return null;

      Term front = ast.children.front.pipe!toList;
      if (hasError) return null;
      if (front.token == Operator.pipe) {
        Term buildList(Term parent) {
          assert(parent.token == Operator.pipe);
          if (parent.children.back.token != Operator.pipe) {
            assert(parent.children.back.token == Atom.emptyList);
            return new Term(parent.token, [parent.children.front, back]);
          } else {
            return new Term(parent.token, [parent.children.front, buildList(parent.children.back)]);
          }
        }
        return buildList(front);
      } else {
        return new Term(ast.token, [front, back]);
      }
    } else if (ast.token == Operator.comma) {
      assert(ast.children.length == 2);
      Term front = ast.children.front.pipe!toTerm;
      Term back  = ast.children.back.pipe!toList;
      if (back.token != Operator.pipe) {
        Term empty = new Term(cast(Token) Atom.emptyList, []);
        back = new Term(cast(Token) Operator.pipe, [back, empty]);
      }
      return new Term(cast(Token) Operator.pipe, [front, back]);
    } else if (ast.token == Atom.emptyList) {
      return ast.pipe!toTerm;
    } else {
      Term front = ast.pipe!toTerm;
      Term back  = new Term(cast(Token) Atom.emptyList, []);
      return new Term(cast(Token) Operator.pipe, [front, back]);
    }
  }

  void setErrorMessage(Token[] tokens) in {
    assert(!tokens.empty);
  } do {
    dstring str = tokens.map!(t => t.lexeme).join(" ");
    _errorMessage = Message("SyntaxError(" ~tokens.front.line.to!dstring~ ", " ~tokens.front.column.to!dstring~ "): \"" ~str~ "\"");
    _hasError = true;
  }


  /* ---------- Unit Tests ---------- */

  unittest {
    writeln(__FILE__, ": test fact/rule/query");

    auto lexer = new Lexer;
    auto parser = new Parser;
    auto clauseBuilder = new ClauseBuilder;

    dstring src = "hoge(aaa). po(X) :- hoge(X). ?- po(aaa).";
    lexer.run(src);
    parser.run(lexer.get);
    ASTRoot root = parser.get;

    AST fact  = root.children[0].children.front;
    AST rule  = root.children[1].children.front;
    AST query = root.children[2].children.front;

    assert(!clauseBuilder.isRule(fact)  && !clauseBuilder.isQuery(fact) );
    assert( clauseBuilder.isRule(rule)  && !clauseBuilder.isQuery(rule) );
    assert(!clauseBuilder.isRule(query) &&  clauseBuilder.isQuery(query));
  }

  unittest {
    writeln(__FILE__, ": test build 1");

    dstring src = "hoge(a, b, c, d).";

    auto lexer = new Lexer;
    auto parser = new Parser;
    auto clauseBuilder = new ClauseBuilder;

    lexer.run(src);
    parser.run(lexer.get);
    clauseBuilder.run(parser.get);
    assert(!clauseBuilder.hasError);

    Clause[] clauseList = clauseBuilder.get;
    assert(clauseList.length == 1);
    assert(clauseList.front.instanceOf!Fact);

    Term term = (cast(Fact) clauseList.front).first;
    assert(term.isStructure);
    assert(term.children.length == 4);
    assert(term.children.all!(t => t.children.empty && t.isAtom));
  }

  unittest {
    writeln(__FILE__, ": test build 2");

    dstring src = "hoge(X) :- po1(X, Y), po2(X, Y); po3(X), po4(X).";

    auto lexer = new Lexer;
    auto parser = new Parser;
    auto clauseBuilder = new ClauseBuilder;

    lexer.run(src);
    parser.run(lexer.get);
    clauseBuilder.run(parser.get);
    assert(!clauseBuilder.hasError);

    Clause[] clauseList = clauseBuilder.get;
    assert(clauseList.length == 1);
    assert(clauseList.front.instanceOf!Rule);

    Term term = (cast(Rule) clauseList.front).second;
    assert(term.isCompound && term.token==Operator.semicolon);
    assert(term.children.length==2);
    assert(term.children.all!(t => t.isCompound && t.token==Operator.comma));
    assert(term.children.all!(
      a => a.children.length==2 && a.children.all!(
        b => !b.isCompound && b.isStructure && b.children.all!(
          c => !c.isCompound && c.isVariable
        )
      )
    ));
  }

  unittest {
    writeln(__FILE__, ": test build 3");

    dstring src = "?- X is 1 * 2 + 3 mod 4.";

    auto lexer = new Lexer;
    auto parser = new Parser;
    auto clauseBuilder = new ClauseBuilder;

    lexer.run(src);
    parser.run(lexer.get);
    clauseBuilder.run(parser.get);
    assert(!clauseBuilder.hasError);

    Clause[] clauseList = clauseBuilder.get;
    assert(clauseList.length == 1);
    assert(clauseList.front.instanceOf!Query);

    Term term = (cast(Query) clauseList.front).first;
    assert(!term.isCompound && term.isStructure && term.token.lexeme=="is");
    assert(term.children.length == 2);
    assert(term.children.front.isVariable);
    assert(term.children.back.pipe!(
      t => t.isStructure && t.token.lexeme=="+"
    ));
    assert(term.children.back.children.length == 2);
    assert(term.children.back.children.front.pipe!(
      t => t.isStructure && t.token.lexeme=="*"
    ));
    assert(term.children.back.children.back.pipe!(
      t => t.isStructure && t.token.lexeme=="mod"
    ));
  }

  unittest {
    writeln(__FILE__, ": test build 4");

    dstring src = "[1, 2|[3|[4, 5|[6]]]].";
    // => "[1|[2|[3|[4|[5|[6|[]]]]]]]."

    auto lexer = new Lexer;
    auto parser = new Parser;
    auto clauseBuilder = new ClauseBuilder;

    lexer.run(src);
    parser.run(lexer.get);
    clauseBuilder.run(parser.get);
    assert(!clauseBuilder.hasError);

    Clause[] clauseList = clauseBuilder.get;
    assert(clauseList.length == 1);
    assert(clauseList.front.instanceOf!Fact);

    Term first = (cast(Fact) clauseList.front).first;

    bool validate(Term term, long n)  {
      return n==0 ? (() =>
        term.isAtom && term.token == Atom.emptyList
      )() : (() =>
        term.isStructure &&
        term.token == Operator.pipe &&
        term.children.front.isNumber &&
        validate(term.children.back, n-1)
      )();
    }

    assert(validate(first, 6));
  }

  unittest {
    writeln(__FILE__, ": test error");

    auto lexer = new Lexer;
    auto parser = new Parser;
    auto clauseBuilder = new ClauseBuilder;

    void testError(dstring src, bool isError) {
      lexer.run(src);
      assert(!lexer.hasError);
      parser.run(lexer.get);
      assert(!parser.hasError);
      clauseBuilder.run(parser.get);
      assert(clauseBuilder.hasError == isError);
    }

    testError("", false);
    testError(".", false);
    testError("hoge(a).", false);
    testError("hoge(X).", false);
    testError("?- hoge(X).", false);
    testError("aaa(a), bbb(b).", true);            // => Error: Factが複合節
    testError("aaa(a); bbb(b).", true);            // => Error: Factが複合節
    testError("aaa(X), bbb(X) :- ccc(X).", true);  // => Error: Ruleのheadが複合節
    testError("aa :- (bb :- cc).", true);          // => Error: RuleのSyntaxが不適切
    testError("?- (aa :- cc).", true);             // => Error: QueryのSyntaxが不適切
    testError("[].", false);
    testError("[a | X].", false);
    testError("[a | a].", true);                   // => Error: ListのSyntaxが不適切
    testError("[a | [a | X]].", false);
    testError("[a | a | X].", true);               // => Error: ListのSyntaxが不適切
    testError("[1, 2, 3, 4].", false);
    testError("[1, 2, 3, 4 | []].", false);
    testError("[1, 2, 3 | [4]].", false);
    testError("[1, 2, 3 | 4].", true);             // => Error: ListのSyntaxが不適切
    testError("[1 | [2 | [3 | [4]]]].", false);
    testError("[1 | [2, 3 | [4]]].", false);
    testError("[[], a, [1, 2]].", false);
  }

}
