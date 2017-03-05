module dprolog.Token;

import std.conv;

/*

Token -> Atom | Number | Variable | Operator | LParen | RParen | Period

*/

interface Token {}

class Atom : Token {

    private immutable string lexeme;
    this(string lexeme) {
        this.lexeme = lexeme;
    }

    override bool opEquals(Object o) {
        auto that = cast(Atom) o;
        return this.lexeme == that.lexeme;
    }

    override string toString() {
        return "Atom(lexeme: " ~ lexeme ~ ")";
    }

}

class Number : Token {

    private immutable string lexeme;
    private immutable int value;
    this(string lexeme) {
        this.lexeme = lexeme;
        this.value = lexeme.to!int;
    }
    this(int value) {
        this.lexeme = value.to!string;
        this.value = value;
    }

    override bool opEquals(Object o) {
        auto that = cast(Number) o;
        return this.lexeme == that.lexeme;
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

    private immutable string lexeme;
    this(string lexeme) {
        this.lexeme = lexeme;
    }

    override bool opEquals(Object o) {
        auto that = cast(Variable) o;
        return this.lexeme == that.lexeme;
    }

    override string toString() {
        return "Variable(" ~ lexeme ~ ")";
    }
}

class Operator : Token {

    private immutable string lexeme;
    private immutable int precedence;
    private immutable string type;
    this(string lexeme) {
        this.lexeme = lexeme;
        this.precedence = -1;
        this.type = "_";
    }

    override bool opEquals(Object o) {
        auto that = cast(Operator) o;
        return this.lexeme == that.lexeme && this.precedence==that.precedence && this.type==that.type;
    }

    override string toString() {
        return "Operator(lexeme: " ~ lexeme ~ ", precedence: " ~precedence.to!string~ ", type: " ~type~  ")";
    }

    private this(string lexeme, int precedence, string type) in {
        assert(isLegalType(type));
    } body {
        this.lexeme = lexeme;
        this.precedence = precedence;
        this.type = type;
    }

    static bool isLegalType(string type) {
        return type=="xfx" || type=="xfy" || type=="yfx" || type=="fx" || type=="fy" || type=="xf" || type=="yf";
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

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() {
        return "LParen()";
    }

}

class RParen : Token {

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() {
        return "RParen()";
    }

}

class Period : Token {

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() {
        return "Period()";
    }

}
