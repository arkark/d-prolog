module dprolog.converter.Parser;

import dprolog.data.token;
import dprolog.data.AST;
import dprolog.data.Message;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.util.functions;
import dprolog.util.Maybe;

import std.stdio;
import std.conv;
import std.algorithm;
import std.array;
import std.range;
import std.concurrency;
import std.traits;
import std.container : DList;

// Parser: Token[] -> ASTRoot

class Parser : Converter!(Token[], ASTRoot) {

private:
  bool _isParsed;
  ASTRoot _resultAST;

  Maybe!Message _errorMessage;

public:

  this() {
    clear();
  }

  void run(Token[] tokens) {
    clear();
    parse(tokens);
  }

  ASTRoot get() in(_isParsed) do {
    return _resultAST;
  }

  void clear() {
    _isParsed = false;
    _resultAST = null;
    _errorMessage = None!Message;
  }

  @property bool hasError() {
    return _errorMessage.isJust;
  }

  @property Message errorMessage() in(hasError) do {
    return _errorMessage.get;
  }

private:

  void parse(Token[] tokens) {
    _resultAST = new ASTRoot(tokens);
    parseProgram(tokens, _resultAST);
    _isParsed = true;
  }

  void parseProgram(Token[] tokens, AST parent) {
    while(!tokens.empty) {
      long cnt = tokens.countUntil!(t => t.instanceOf!Period);
      if (cnt == -1) {
        setErrorMessage(tokens);
        return;
      } else {
        AST ast = new AST(tokens[cnt], tokens[0..cnt+1]);
        parseClause(tokens[0..cnt], ast);
        parent.children ~= ast;
        tokens = tokens[cnt+1..$];
      }
    }
  }

  void parseClause(Token[] tokens, AST parent) {
    specifyOperators(tokens);
    parseTermList(tokens, parent);
  }

  void parseTermList(Token[] tokens, AST parent) {
    Maybe!Operator opM = findHighestOperator(tokens);
    if (hasError) return;
    if (opM.isNone) {
      parseTerm(tokens, parent);
    } else {
      opM.apply!((op) {
        AST ast = new AST(op, tokens);
        long cnt = tokens.countUntil!(t => t is op);
        if (op.notation != Operator.Notation.Prefix) parseTermList(tokens[0..cnt], ast);
        if (op.notation != Operator.Notation.Postfix) parseTermList(tokens[cnt+1..$], ast);
        parent.children ~= ast;
      }, true);
    }
  }

  void parseTerm(Token[] tokens, AST parent) {
    if (tokens.empty) return;

    Token head = tokens.front;
    Token last = tokens.back;
    if (head.instanceOf!LParen && last.instanceOf!RParen && tokens.length>2) {
      parseTermList(tokens[1..$-1], parent);
    } else if (head.instanceOf!LBracket) {
      parseList(tokens, parent);
    } else if (head.instanceOf!Atom && tokens.length>1) {
      parseStructure(tokens, parent);
    } else if ((head.instanceOf!Atom || head.instanceOf!Number || head.instanceOf!Variable) && tokens.length==1) {
      parent.children ~= new AST(head, tokens[0..1]);
    } else {
      setErrorMessage(tokens);
    }
  }

  void parseStructure(Token[] tokens, AST parent) {
    if (tokens.length < 4) {
      setErrorMessage(tokens);
      return;
    }
    if (!tokens.front.instanceOf!Atom || !tokens[1].instanceOf!LParen || !tokens.back.instanceOf!RParen) {
      setErrorMessage(tokens);
      return;
    }
    AST ast = new AST(new Functor(cast(Atom) tokens.front), tokens);
    parseTermList(tokens[2..$-1], ast);
    parent.children ~= ast;
  }

  void parseList(Token[] tokens, AST parent) {
    if (tokens.length < 2) {
      setErrorMessage(tokens);
      return;
    }
    if (!tokens.front.instanceOf!LBracket || !tokens.back.instanceOf!RBracket) {
      setErrorMessage(tokens);
      return;
    }
    AST ast = new AST(tokens.front, tokens[0..1]);
    if (tokens.length == 2) {
      // 空リスト
      ast.children ~= new AST(cast(Token) Atom.emptyList, []);
    } else {
      parseTermList(tokens[1..$-1], ast);
    }
    parent.children ~= ast;
  }

  Maybe!Operator findHighestOperator(Token[] tokens) {
    auto gen = new Generator!Operator({
      auto parenStack = DList!Token();
      foreach(token; tokens) {
        if (token.instanceOf!LParen || token.instanceOf!LBracket) {
          parenStack.insertBack(token);
        } else if (token.instanceOf!RParen) {
          if (parenStack.empty) {
            setErrorMessage(tokens);
            return;
          }
          if (!parenStack.back.instanceOf!LParen) {
            setErrorMessage(tokens);
            return;
          }
          parenStack.removeBack;
        } else if (token.instanceOf!RBracket) {
          if (parenStack.empty) {
            setErrorMessage(tokens);
            return;
          }
          if (!parenStack.back.instanceOf!LBracket) {
            setErrorMessage(tokens);
            return;
          }
          parenStack.removeBack;
        } else if (token.instanceOf!Operator && parenStack.empty) {
          yield(cast(Operator) token);
        }
      }
    });
    return (!gen.empty).fmap(gen.fold!((a, b) {
      if (a.precedence>b.precedence) return a;
      if (a.precedence<b.precedence) return b;

      if (a.type.endsWith("y") && !b.type.startsWith("y")) return a;
      if (b.type.startsWith("y") && !a.type.endsWith("y")) return b;

      setErrorMessage(tokens);
      return b;
    }));
  }

  void specifyOperators(Token[] tokens) {
    foreach(i, ref token; tokens) {
      if (token.instanceOf!Atom) {
        bool isPrefix  = i==0               || tokens[i-1].instanceOf!LParen || tokens[i-1].instanceOf!LBracket;
        bool isPostfix = i==tokens.length-1 || tokens[i+1].instanceOf!RParen || tokens[i+1].instanceOf!RBracket;
        Maybe!Operator opM =  Operator.getOperator(
          cast(Atom) token,
          isPrefix  ? Operator.Notation.Prefix  :
          isPostfix ? Operator.Notation.Postfix :
                      Operator.Notation.Infix
        );
        if (opM.isNone) {
          foreach(notation; EnumMembers!(Operator.Notation)) {
            if (Operator.getOperator(cast(Atom)token, notation).isJust) {
              // when an operator is used as a non-operator
              setErrorMessage(tokens);
              break;
            }
          }
        } else {
          auto op = opM.get;
          if ((isPrefix || isPostfix) && tokens.length < 2) {
            setErrorMessage(tokens);
            break;
          }
          token = op;
        }
      }
    }
  }

  void setErrorMessage(Token[] tokens) in(!tokens.empty) do {
    dstring str = tokens.map!(t => t.lexeme).join(" ");
    _errorMessage = Message("ParseError(" ~tokens.front.line.to!dstring~ ", " ~tokens.front.column.to!dstring~ "): cannot parse \"" ~str~ "\".");
  }


  /* ---------- Unit Tests ---------- */

  static void testAST(TAry...)(ASTRoot root, long[] inds...) {
    AST ast = root;
    foreach(i; inds) {
      assert(ast.children.length > i);
      ast = ast.children[i];
    }
    assert(ast.children.length == TAry.length);
    foreach(i, T; TAry) {
      assert(ast.children[i].token.instanceOf!T);
    }
  }

  unittest {
    writeln(__FILE__, ": test parse 1");

    auto lexer = new Lexer;
    auto parser = new Parser;
    lexer.run("hoge(X).");
    parser.run(lexer.get());
    assert(!parser.hasError);
    ASTRoot root = parser.get();
    Parser.testAST!(Period)(root);
    Parser.testAST!(Functor)(root, 0);
    Parser.testAST!(Variable)(root, 0, 0);

    // root.writeln;
  }

  unittest {
    writeln(__FILE__, ": test parse 2");

    auto lexer = new Lexer;
    auto parser = new Parser;
    lexer.run("aa(X) :- po(X, _).");
    parser.run(lexer.get());
    assert(!parser.hasError);
    ASTRoot root = parser.get();
    Parser.testAST!(Period)(root);
    Parser.testAST!(Operator)(root, 0);
    Parser.testAST!(Functor, Functor)(root, 0, 0);
    Parser.testAST!(Variable)(root, 0, 0, 0);
    Parser.testAST!(Operator)(root, 0, 0, 1);
    Parser.testAST!(Variable, Variable)(root, 0, 0, 1, 0);

    // root.writeln;
  }

  unittest {
    writeln(__FILE__, ": test parse 3");

    auto lexer = new Lexer;
    auto parser = new Parser;
    lexer.run("aa; _po. ('あ').");
    parser.run(lexer.get());
    assert(!parser.hasError);
    ASTRoot root = parser.get();
    Parser.testAST!(Period, Period)(root);
    Parser.testAST!(Operator)(root, 0);
    Parser.testAST!(Atom, Variable)(root, 0, 0);
    Parser.testAST!(Atom)(root, 1);

    // root.writeln;
  }

  unittest {
    writeln(__FILE__, ": test parse 4");

    auto lexer = new Lexer;
    auto parser = new Parser;
    lexer.run("X is 1 + 2 + Y * 10.");
    parser.run(lexer.get());
    assert(!parser.hasError);
    ASTRoot root = parser.get();
    Parser.testAST!(Period)(root);
    Parser.testAST!(Operator)(root, 0);
    Parser.testAST!(Variable, BinaryOperator)(root, 0, 0);
    Parser.testAST!(BinaryOperator, BinaryOperator)(root, 0, 0, 1);
    Parser.testAST!(Number, Number)(root, 0, 0, 1, 0);
    Parser.testAST!(Variable, Number)(root, 0, 0, 1, 1);

    // root.writeln;
  }

  unittest {
    writeln(__FILE__, ": test parse 5");

    auto lexer = new Lexer;
    auto parser = new Parser;
    lexer.run("X is + 1.");
    parser.run(lexer.get());
    assert(!parser.hasError);
    ASTRoot root = parser.get();
    Parser.testAST!(Period)(root);
    Parser.testAST!(Operator)(root, 0);
    Parser.testAST!(Variable, UnaryOperator)(root, 0, 0);
    Parser.testAST!(Number)(root, 0, 0, 1);

    // root.writeln;
  }

  unittest {
    writeln(__FILE__, ": test parse 6");

    auto lexer = new Lexer;
    auto parser = new Parser;
    lexer.run("conc([X|L1], L2, [X|List]) :- conc(L1, L2, List).");
    parser.run(lexer.get());
    assert(!parser.hasError);
    ASTRoot root = parser.get();
    Parser.testAST!(Period)(root);
    Parser.testAST!(Operator)(root, 0);
    Parser.testAST!(Functor, Functor)(root, 0, 0);
    Parser.testAST!(Operator)(root, 0, 0, 0);
    Parser.testAST!(LBracket, Operator)(root, 0, 0, 0, 0);
    Parser.testAST!(Operator)(root, 0, 0, 0, 0, 0);
    Parser.testAST!(Variable, Variable)(root, 0, 0, 0, 0, 0, 0);
    Parser.testAST!(Variable, LBracket)(root, 0, 0, 0, 0, 1);
    Parser.testAST!(Operator)(root, 0, 0, 0, 0, 1, 1);
    Parser.testAST!(Variable, Variable)(root, 0, 0, 0, 0, 1, 1, 0);
    Parser.testAST!(Operator)(root, 0, 0, 1);
    Parser.testAST!(Variable, Operator)(root, 0, 0, 1, 0);
    Parser.testAST!(Variable, Variable)(root, 0, 0, 1, 0, 1);

    // root.writeln;
  }

  unittest {
    writeln(__FILE__, ": test error");

    auto lexer = new Lexer;
    auto parser = new Parser;

    void testError(dstring src, bool isError) {
      lexer.run(src);
      assert(!lexer.hasError);
      parser.run(lexer.get);
      if (parser.hasError != isError) {
        lexer.get.writeln;
        parser.hasError.writeln;
        parser.errorMessage.writeln;
        parser.get.writeln;
      }
      assert(parser.hasError == isError);
    }

    testError("", false);
    testError(".....", false);
    testError("().", true);
    testError("+.", true);
    testError("*.", true);
    testError("hoge(X). po", true);
    testError("hoge(X).", false);
    testError("?- a :- b.", true);
    testError("?- .", true);
    testError("aa :- bb :- cc.", true);
    testError("aa :- (bb :- cc).", false);
    testError("hoge(aa aa).", true);
    testError("hoge(()).", true);
    testError("hoge((X).", true);
    testError("[].", false);
    testError("[|].", true);
    testError("[a|].", true);
    testError("[|a].", true);
    testError("+1+2+3.", false);
    testError("*1*2*3.", true);
  }

}
