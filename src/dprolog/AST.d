module dprolog.AST;

import dprolog.Token;

import std.conv,
       std.range,
       std.algorithm;

// Abstract Syntax Tree

class AST {
    Token token;
    AST[] children;

    this(Token token) {
        this.token = token;
        this.children = [];
    }

    override string toString() {
        return toString(0);
    }

    protected string toString(int tabCount) {
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

    this() {
        super(null);
    }

    void clear() {
        children = [];
    }

    override string toString() {
        return toString(0);
    }

    protected override string toString(int tabCount) {
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
