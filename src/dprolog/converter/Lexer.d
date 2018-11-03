module dprolog.converter.Lexer;

import dprolog.data.token;
import dprolog.util.Message;
import dprolog.converter.Converter;
import dprolog.util.functions;
import dprolog.util.Maybe;

import std.stdio;
import std.format;
import std.conv;
import std.string;
import std.format;
import std.ascii;
import std.range;
import std.array;
import std.algorithm;
import std.regex;
import std.functional;
import std.concurrency;
import std.container : DList;

// Lexer (lexical analyzer): dstring -> Token[]

class Lexer : Converter!(dstring, Token[]) {

private:
  bool _isTokenized;
  DList!Token _resultTokens;

  Maybe!Message _errorMessage;

public:
  this() {
    clear();
  }

  void run(dstring src) {
    clear();
    tokenize(src);
  }

  Token[] get() in(_isTokenized) do {
    return _resultTokens.array;
  }

  void clear() {
    _isTokenized = false;
    _resultTokens.clear;
    _errorMessage = None!Message;
  }

  @property bool hasError() {
    return _errorMessage.isJust;
  }

  @property Message errorMessage() in(hasError) do {
    return _errorMessage.get;
  }

private:

  void tokenize(dstring src) {
    auto lookaheader = getLookaheader(src);
    while(!lookaheader.empty) {
      TokenGen tokenGen = getTokenGen(lookaheader);
      getToken(lookaheader, tokenGen).apply!(
        token => _resultTokens.insertBack(token)
      );
    }
    _isTokenized = true;
  }

  TokenGen getTokenGen(Generator!Node lookaheader) {
    Node node = lookaheader.front;
    dstring head = node.value;
    auto genR = [
      AtomGen,
      NumberGen,
      VariableGen,
      LParenGen,
      RParenGen,
      LBracketGen,
      RBracketGen,
      PeriodGen,
      EmptyGen
    ].find!(gen => gen.validatePrefix(head));
    return genR.empty ? ErrorGen : genR.front;
  }

  Maybe!Token getToken(Generator!Node lookaheader, TokenGen tokenGen) {
    if (lookaheader.empty) return None!Token;
    Node node = getTokenNode(lookaheader, tokenGen);
    return tokenGen.getToken(node);
  }

  Node getTokenNode(Generator!Node lookaheader, TokenGen tokenGen) in(!lookaheader.empty) do {
    Node nowNode = lookaheader.front;
    lookaheader.popFront;
    while(!lookaheader.empty) {
      Node nextNode = nowNode ~ lookaheader.front;
      if (tokenGen.validatePrefix(nextNode.value)) {
        nowNode = nextNode;
        lookaheader.popFront;
      } else {
        break;
      }
    }
    if (!tokenGen.validateAll(nowNode.value)) {
      setErrorMessage(nowNode);
      clearLookaheader(lookaheader);
    }
    return nowNode;
  }

  void setErrorMessage(Node node) {
    long num = 20;
    dstring str = node.value.pipe!(
      lexeme => lexeme.length>num ? lexeme.take(num).to!dstring ~ " ... " : lexeme
    );
    _errorMessage = ErrorMessage(
      format!"TokenError(%d, %d): cannot tokenize \"%s\"."(
        node.line,
        node.column,
        str
      )
    );
  }

  Generator!Node getLookaheader(immutable dstring src) {
    return new Generator!Node({
      foreach(line, str; src.splitLines) {
        foreach(column, ch; str) {
          if (ch == '%') break; // a comment
          Node(ch.to!dstring, line+1, column+1).yield;
        }
      }
    });
  }

  void clearLookaheader(Generator!Node lookaheader) {
    while(!lookaheader.empty) {
      lookaheader.popFront;
    }
  }

  struct TokenGen {
    immutable bool function(dstring) validatePrefix;
    immutable bool function(dstring) validateAll;
    immutable Maybe!Token function(Node) getToken;
  }

  static TokenGen AtomGen = TokenGen(
    (dstring prefix) {
      static auto re = ctRegex!(r"(([a-z][_0-9a-zA-Z]*)|('[^']*'?)|(["d ~Token.specialCharacters.escaper.to!dstring~ r"]+))$"d);
      auto res = prefix.matchFirst(re);
      return !res.empty && res.front==prefix;
    },
    (dstring lexeme) {
      static auto re = ctRegex!(r"(([a-z][_0-9a-zA-Z]*)|('[^']*')|(["d ~Token.specialCharacters.escaper.to!dstring~ r"]+))$"d);
      auto res = lexeme.matchFirst(re);
      return !res.empty && res.front==lexeme;
    },
    (Node node) => Just!Token(new Atom(node.value, node.line, node.column))
  );

  static TokenGen NumberGen = TokenGen(
    (dstring prefix) {
      enum dstring decimal = r"0|[1-9][0-9]*"d;
      enum dstring binary = r"0[bB](0|[1-1][0-1]*)?"d;
      enum dstring hexadecimal = r"0[xX](0|[1-9a-fA-F][0-9a-fA-F]*)?"d;
      static auto re = ctRegex!(format!r"((%s)|(%s)|(%s))$"d(decimal, binary, hexadecimal));
      auto res = prefix.matchFirst(re);
      return !res.empty && res.front==prefix;
    },
    (dstring lexeme) {
      enum dstring decimal = r"0|[1-9][0-9]*"d;
      enum dstring binary = r"0[bB](0|[1-1][0-1]*)"d;
      enum dstring hexadecimal = r"0[xX](0|[1-9a-fA-F][0-9a-fA-F]*)"d;
      static auto re = ctRegex!(format!r"((%s)|(%s)|(%s))$"d(decimal, binary, hexadecimal));
      auto res = lexeme.matchFirst(re);
      return !res.empty && res.front==lexeme;
    },
    (Node node) => Just!Token(new Number(node.value, node.line, node.column))
  );

  static TokenGen VariableGen = TokenGen(
    (dstring prefix) {
      static auto re = ctRegex!(r"[_A-Z][_0-9a-zA-Z]*$"d);
      auto res = prefix.matchFirst(re);
      return !res.empty && res.front==prefix;
    },
    (dstring lexeme) {
      static auto re = ctRegex!(r"[_A-Z][_0-9a-zA-Z]*$"d);
      auto res = lexeme.matchFirst(re);
      return !res.empty && res.front==lexeme;
    },
    (Node node) => Just!Token(new Variable(node.value, node.line, node.column))
  );

  static TokenGen LParenGen = TokenGen(
    (dstring prefix) => prefix == "(",
    (dstring lexeme) => lexeme == "(",
    (Node node)      => Just!Token(new LParen(node.value, node.line, node.column))
  );

  static TokenGen RParenGen = TokenGen(
    (dstring prefix) => prefix == ")",
    (dstring lexeme) => lexeme == ")",
    (Node node)      => Just!Token(new RParen(node.value, node.line, node.column))
  );

  static TokenGen LBracketGen = TokenGen(
    (dstring prefix) => prefix == "[",
    (dstring lexeme) => lexeme == "[",
    (Node node)      => Just!Token(new LBracket(node.value, node.line, node.column))
  );

  static TokenGen RBracketGen = TokenGen(
    (dstring prefix) => prefix == "]",
    (dstring lexeme) => lexeme == "]",
    (Node node)      => Just!Token(new RBracket(node.value, node.line, node.column))
  );

  static TokenGen PeriodGen = TokenGen(
    (dstring prefix) => prefix == ".",
    (dstring lexeme) => lexeme == ".",
    (Node node)      => Just!Token(new Period(node.value, node.line, node.column))
  );

  static TokenGen EmptyGen = TokenGen(
    (dstring prefix) => prefix.length==1 && prefix.front.isWhite,
    (dstring lexeme) => lexeme.length==1 && lexeme.front.isWhite,
    (Node node)      => None!Token
  );

  static TokenGen ErrorGen = TokenGen(
    (dstring prefix) => false,
    (dstring lexeme) => false,
    (Node node)      => None!Token
  );

  struct Node {
    dstring value;
    long line;
    long column;

    Node opBinary(string op)(Node that) if (op == "~") {
      return Node(
        this.value~that.value,
        min(this.line, that.line),
        this.line<that.line ? this.column                   :
        this.line>that.line ? that.column                   :
                              min(this.column, that.column)
      );
    }

    string toString() const {
      return format!"Node(value: \"%s\", line: %s, column: %s)"(value, line, column);
    }

  }



  /* ---------- Unit Tests ---------- */

  // test Node
  unittest {
    writeln(__FILE__, ": test Node");

    Node n1 = Node("abc", 1, 10);
    Node n2 = Node("de", 2, 5);
    Node n3 = Node("fg", 2, 1);
    assert(n1~n2 == Node("abcde", 1, 10));
    assert(n2~n3 == Node("defg", 2, 1));
  }

  // test TokenGen
  unittest {
    writeln(__FILE__, ": test TokenGen");

    // AtomGen
    assert(AtomGen.validatePrefix("a"));
    assert(AtomGen.validatePrefix("\'"));
    assert(AtomGen.validatePrefix("\'aaa"));
    assert(!AtomGen.validatePrefix("aaa\'"));
    assert(AtomGen.validatePrefix(","));
    assert(!AtomGen.validatePrefix("A"));
    assert(AtomGen.validateAll("abc"));
    assert(AtomGen.validateAll("' po _'"));
    assert(AtomGen.validateAll("''"));
    assert(AtomGen.validateAll("|+|"));
    assert(!AtomGen.validateAll("'"));
    assert(!AtomGen.validateAll("' po _"));
    // NumberGen
    assert(NumberGen.validatePrefix("0"));
    assert(NumberGen.validatePrefix("0b"));
    assert(NumberGen.validatePrefix("0B"));
    assert(NumberGen.validatePrefix("0x"));
    assert(NumberGen.validatePrefix("0X"));
    assert(!NumberGen.validatePrefix("_"));
    assert(NumberGen.validateAll("123"));
    assert(NumberGen.validateAll("0"));
    assert(NumberGen.validateAll("0b10"));
    assert(NumberGen.validateAll("0xff"));
    assert(NumberGen.validateAll("0XFF"));
    assert(!NumberGen.validateAll("0b123"));
    assert(!NumberGen.validateAll("0xxxx"));
    assert(!NumberGen.validateAll("0123"));
    // VariableGen
    assert(VariableGen.validatePrefix("A"));
    assert(VariableGen.validatePrefix("_"));
    assert(VariableGen.validatePrefix("_a"));
    assert(!VariableGen.validatePrefix("a"));
    assert(VariableGen.validateAll("Po"));
    assert(VariableGen.validateAll("_yeah"));
    // LParenGen
    assert(LParenGen.validatePrefix("("));
    assert(LParenGen.validateAll("("));
    // RParenGen
    assert(RParenGen.validatePrefix(")"));
    assert(RParenGen.validateAll(")"));
    // LBracketGen
    assert(LBracketGen.validatePrefix("["));
    assert(LBracketGen.validateAll("["));
    // RBracketGen
    assert(RBracketGen.validatePrefix("]"));
    assert(RBracketGen.validateAll("]"));
    // PeriodGen
    assert(PeriodGen.validatePrefix("."));
    assert(PeriodGen.validateAll("."));
    // EmptyGen
    assert(EmptyGen.validatePrefix(" "));
    assert(EmptyGen.validateAll(" "));
  }

  // test lookaheader
  unittest {
    writeln(__FILE__, ": test Lookaheader");

    auto lexer = new Lexer;
    auto lookaheader = lexer.getLookaheader("a\nbc\nd");

    assert(!lookaheader.empty);
    assert(lookaheader.front == Node("a", 1, 1));
    lookaheader.popFront;
    assert(lookaheader.front == Node("b", 2, 1));
    lookaheader.popFront;
    assert(lookaheader.front == Node("c", 2, 2));
    lookaheader.popFront;
    assert(lookaheader.front == Node("d", 3, 1));
    lookaheader.popFront;
    assert(lookaheader.empty);
  }

  // test getTokenGen
  unittest {
    writeln(__FILE__, ": test getTokenGen");

    auto lexer = new Lexer;
    auto lookaheader = lexer.getLookaheader("hoge(10, X).");
    assert(lexer.getTokenGen(lookaheader) == AtomGen);
    lookaheader.drop(4);
    assert(lexer.getTokenGen(lookaheader) == LParenGen);
    lookaheader.drop(1);
    assert(lexer.getTokenGen(lookaheader) == NumberGen);
    lookaheader.drop(2);
    assert(lexer.getTokenGen(lookaheader) == AtomGen);
    lookaheader.drop(1);
    assert(lexer.getTokenGen(lookaheader) == EmptyGen);
    lookaheader.drop(1);
    assert(lexer.getTokenGen(lookaheader) == VariableGen);
    lookaheader.drop(1);
    assert(lexer.getTokenGen(lookaheader) == RParenGen);
    lookaheader.drop(1);
    assert(lexer.getTokenGen(lookaheader) == PeriodGen);
    lookaheader.drop(1);
    assert(lookaheader.empty);

    assert(!lexer.hasError);
    assert(lexer._errorMessage.isNone);
  }

  // test getTokenNode
  unittest {
    writeln(__FILE__, ": test getTokenNode");

    auto lexer = new Lexer;
    auto lookaheader = lexer.getLookaheader("hoge(10, X).");
    assert(lexer.getTokenNode(lookaheader, AtomGen)     == Node("hoge", 1, 1));
    assert(lexer.getTokenNode(lookaheader, LParenGen)   == Node("(", 1, 5));
    assert(lexer.getTokenNode(lookaheader, NumberGen)   == Node("10", 1, 6));
    assert(lexer.getTokenNode(lookaheader, AtomGen)     == Node(",", 1, 8));
    assert(lexer.getTokenNode(lookaheader, EmptyGen)    == Node(" ", 1, 9));
    assert(lexer.getTokenNode(lookaheader, VariableGen) == Node("X", 1, 10));
    assert(lexer.getTokenNode(lookaheader, RParenGen)   == Node(")", 1, 11));
    assert(lexer.getTokenNode(lookaheader, PeriodGen)   == Node(".", 1, 12));
    assert(lookaheader.empty);

    assert(!lexer.hasError);
    assert(lexer._errorMessage.isNone);
  }

  // test getToken
  unittest {
    writeln(__FILE__, ": test getToken");

    auto lexer = new Lexer;
    auto lookaheader = lexer.getLookaheader("hoge(10, X).");
    assert(lexer.getToken(lookaheader, AtomGen).fmap!(t => t.instanceOf!Atom) == true);
    assert(lexer.getToken(lookaheader, LParenGen).fmap!(t => t.instanceOf!LParen) == true);
    assert(lexer.getToken(lookaheader, NumberGen).fmap!(t => t.instanceOf!Number) == true);
    assert(lexer.getToken(lookaheader, AtomGen).fmap!(t => t.instanceOf!Atom) == true);
    assert(lexer.getToken(lookaheader, EmptyGen).isNone);
    assert(lexer.getToken(lookaheader, VariableGen).fmap!(t => t.instanceOf!Variable) == true);
    assert(lexer.getToken(lookaheader, RParenGen).fmap!(t => t.instanceOf!RParen) == true);
    assert(lexer.getToken(lookaheader, PeriodGen).fmap!(t => t.instanceOf!Period) == true);
    assert(lookaheader.empty);

    assert(!lexer.hasError);
    assert(lexer._errorMessage.isNone);
  }

  // test tokenize
  unittest {
    writeln(__FILE__, ": test tokenize");

    auto lexer = new Lexer;
    Token[] tokens;

    lexer.run("hoge(10, X).");
    assert(!lexer.hasError);
    tokens = lexer.get();
    assert(tokens.length == 7);
    assert(tokens[0].instanceOf!Atom);
    assert(tokens[1].instanceOf!LParen);
    assert(tokens[2].instanceOf!Number);
    assert(tokens[3].instanceOf!Atom);
    assert(tokens[4].instanceOf!Variable);
    assert(tokens[5].instanceOf!RParen);
    assert(tokens[6].instanceOf!Period);

    lexer.run("('poあ').");
    assert(!lexer.hasError);
    tokens = lexer.get();
    assert(tokens.length == 4);
    assert(tokens[0].instanceOf!LParen);
    assert(tokens[1].instanceOf!Atom);
    assert(tokens[2].instanceOf!RParen);
    assert(tokens[3].instanceOf!Period);

  }

  // test errorMessage
  unittest {
    writeln(__FILE__, ": test errorMessage");

    auto lexer = new Lexer;
    assert(!lexer.hasError);
    lexer.run("{po}");
    assert(lexer.hasError);
    lexer.run("hoge(X).");
    assert(!lexer.hasError);
    lexer.run("hoge(hogeあ)");
    assert(lexer.hasError);
    lexer.run("'aaaaaaaaaaaaaaaaabbbbbbbbbbbbbbb");
    assert(lexer.hasError);
    // lexer.errorMessage.writeln;
  }
}
