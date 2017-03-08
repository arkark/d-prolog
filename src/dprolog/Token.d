module dprolog.Token;

import std.conv,
       std.algorithm,
       std.typecons;

/*

Token -> Atom | Number | Variable | Operator | LParen | RParen | Period

*/

abstract class Token {

    static immutable dstring specialCharacters = ":?&;,|=<>+-*/\\";

    immutable int line;
    immutable int column;
    protected immutable dstring lexeme;
    this(dstring lexeme, int line, int column) {
        this.lexeme = lexeme;
        this.line = line;
        this.column = column;
    }

}

class Atom : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override string toString() {
        return "Atom(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class Number : Token {

    private immutable int value;
    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
        this.value = lexeme.to!int;
    }

    Number opUary(string op)()
    if (op=="+" || op=="-") {
        mixin("return new Number(" ~ op ~ "this.value);");
    }

    Number opBinary(string op)(Number that)
    if (op=="+" || op=="-" || op=="*" || op=="/" || op=="%") {
        mixin("return new Number(this.value" ~ op ~ "that.value);");
    }

    override string toString() {
        return "Number(value: " ~ value.to!string ~ ")";
    }

}

class Variable : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override string toString() {
        return "Variable(\"" ~ lexeme.to!string ~ "\")";
    }
}

class Operator : Token {

    private immutable int precedence;
    private immutable string type;
    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
        this.precedence = -1;
        this.type = "_";
    }

    override string toString() {
        return "Operator(lexeme: \"" ~ lexeme.to!string ~ "\", precedence: " ~precedence.to!string~ ", type: " ~type~  ")";
    }

    private this(dstring lexeme, int precedence, string type) in {
        assert(isLegalType(type));
    } body {
        super(lexeme, -1, -1);
        this.precedence = precedence;
        this.type = type;
    }

    static bool isLegalType(string type) {
        return type=="xfx" || type=="xfy" || type=="yfx" || type=="fx" || type=="fy" || type=="xf" || type=="yf";
    }

    static bool existOp(dstring lexeme) {
        return opList.canFind!(op => op.lexeme==lexeme);
    }

    private static Operator[] opList = [
        new Operator(":-", 1200, "xfx"),
        new Operator("?-", 1200, "fx"),
        new Operator(";", 1100, "xfy"),
        new Operator("|", 1100, "xfy"),
        new Operator(",", 1000, "xfy"),
        new Operator("=", 700, "xfx"),
        new Operator("==", 700, "xfx"),
        new Operator("<", 700, "xfx"),
        new Operator("=<", 700, "xfx"),
        new Operator(">", 700, "xfx"),
        new Operator(">=", 700, "xfx"),
        new Operator("=:=", 700, "xfx"),
        new Operator("=\\=", 700, "xfx"),
        new Operator("is", 700, "xfx"),
        new Operator("+", 500, "yfx"),
        new Operator("-", 500, "yfx"),
        new Operator("*", 400, "yfx"),
        new Operator("div", 400, "yfx"),
        new Operator("mod", 400, "yfx"),
        new Operator("+", 200, "fy"),
        new Operator("-", 200, "fy")
    ];

}

class LParen : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() {
        return "LParen(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class RParen : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() {
        return "RParen(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class Period : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() {
        return "Period(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}
