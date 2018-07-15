module dprolog.data.AST;

import dprolog.data.Token;

import std.conv,
       std.range,
       std.algorithm;

// Abstract Syntax Tree

class AST {
  Token token;
  Token[] tokenList;
  AST[] children;

  this(Token token, Token[] tokenList) {
    this.token = token;
    this.tokenList = tokenList;
    this.children = [];
  }

  override string toString() const {
    return toString(0);
  }

  protected string toString(long tabCount) const {
    string tab = "\t".repeat(tabCount).join;
    return [
      tab ~ "AST(token: ",
      token.to!string,
      ", children: [",
      children.map!(
        c => "\n" ~ c.toString(tabCount + 1)
      ).join(","),
      "\n" ~ tab ~ "])"
    ].join;
  }
}

class ASTRoot : AST {

  this(Token[] tokenList) {
    super(null, tokenList);
  }

  override string toString() const {
    return toString(0);
  }

  protected override string toString(long tabCount) const {
    string tab = "\t".repeat(tabCount).join;
    return [
      tab ~ "ASTRoot(children: [",
      children.map!(
        c => "\n" ~ c.toString(tabCount + 1)
      ).join(","),
      "\n" ~ tab ~ "])"
    ].join;
  }

}
