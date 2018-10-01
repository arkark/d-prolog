module dprolog.data.AST;

import dprolog.data.token;

import std.range;
import std.format;
import std.algorithm;

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
    return format!"%sAST(token: %s, chidlen: [%-(\n%s,%)\n%s])"(
      tab,
      token,
      children.map!(
        c => c.toString(tabCount + 1)
      ),
      tab
    );
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
    return format!"%sASTRoot(children: [%-(\n%s,%)\n%s])"(
      tab,
      children.map!(
        c => c.toString(tabCount + 1)
      ),
      tab
    );
  }

}
