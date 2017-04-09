module dprolog.data.Token;

import std.conv,
       std.range,
       std.algorithm,
       std.functional,
       std.typecons;

/*

Token -> Atom | Number | Variable | Operator | LParen | RParen | LBracket | RBracket | Period

*/

abstract class Token {

    static immutable dstring specialCharacters = ":?&;,|=<>+-*/\\";

    immutable int line;
    immutable int column;
    immutable dstring lexeme;
    this(dstring lexeme, int line, int column) {
        this.lexeme = lexeme;
        this.line = line;
        this.column = column;
    }

    bool isUnderscore() {
        return lexeme == "_";
    }

    override hash_t toHash() {
        hash_t hash = 0u;
        foreach(c; lexeme) {
            hash = c.hashOf(hash);
        }
        return hash;
    }

    override string toString() const {
        return "Token(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

interface Constant {}

class Atom : Token, Constant {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        auto that = cast(Atom) o;
        return that && this.lexeme==that.lexeme;
    }

    override string toString() const {
        return "Atom(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

    static immutable Atom emptyAtom = cast(immutable) new Atom("", -1, -1); // 空リストに用いる

}

class Number : Token, Constant {

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

    override bool opEquals(Object o) {
        auto that = cast(Number) o;
        return that && this.lexeme==that.lexeme;
    }

    override string toString() const {
        return "Number(value: " ~ value.to!string ~ ")";
    }

}

class Variable : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        auto that = cast(Variable) o;
        return that && this.lexeme==that.lexeme;
    }

    override string toString() const {
        return "Variable(\"" ~ lexeme.to!string ~ "\")";
    }
}

class Functor : Atom {

    this(Atom atom) {
        super(atom.lexeme, atom.line, atom.column);
    }

    override bool opEquals(Object o) {
        auto that = cast(Functor) o;
        return that && this.lexeme==that.lexeme;
    }

    override string toString() const {
        return "Functor(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class Operator : Atom {

    immutable int precedence;
    immutable string type;
    Notation notation() @property {
        switch(type) {
            case "fx" : case "fy" :             return Notation.Prefix;
            case "xfx": case "xfy": case "yfx": return Notation.Infix;
            case "xf" : case "yf" :             return Notation.Postfix;
            default: assert(false);
        }
    }

    override bool opEquals(Object o) {
        auto that = cast(Operator) o;
        return that && this.lexeme==that.lexeme && this.precedence==that.precedence && this.type==that.type;
    }

    override string toString() const {
        return "Operator(lexeme: \"" ~ lexeme.to!string ~ "\", precedence: " ~precedence.to!string~ ", type: " ~type~  ")";
    }

    static Operator getOperator(Atom atom, Notation notation) {
        string[] types = getTypes(notation);
        auto ary = systemOperatorList.find!(
            op => op.lexeme==atom.lexeme && types.canFind(op.type)
        );
        return ary.empty ? null : new Operator(ary.front, atom.line, atom.column);
    }

    static private string[] getTypes(Notation notation) {
        final switch(notation) {
            case Notation.Prefix  : return ["fx", "fy"];
            case Notation.Infix   : return ["xfx", "xfy", "yfx"];
            case Notation.Postfix : return ["xf", "yf"];
        }
    }

    private this(immutable Operator op, int line, int column) {
        super(op.lexeme, line, column);
        this.precedence = op.precedence;
        this.type = op.type;
    }

    private this(dstring lexeme, int precedence, string type)  {
        super(lexeme, -1, -1);
        this.precedence = precedence;
        this.type = type;
    }

    enum Notation {
        Prefix, Infix, Postfix
    }

    static immutable Operator rulifier    = cast(immutable) new Operator(":-", 1200, "xfx");
    static immutable Operator querifier   = cast(immutable) new Operator("?-", 1200, "fx");
    static immutable Operator semicolon = cast(immutable) new Operator(";", 1100, "xfy");
    static immutable Operator comma = cast(immutable) new Operator(",", 1000, "xfy");
    static immutable Operator pipe        = cast(immutable) new Operator("|", 1100, "xfy");

    static private immutable immutable(Operator)[] systemOperatorList = [
        rulifier,
        querifier,
        semicolon,
        pipe,
        comma,
        cast(immutable) new Operator("=", 700, "xfx"),
        cast(immutable) new Operator("==", 700, "xfx"),
        cast(immutable) new Operator("<", 700, "xfx"),
        cast(immutable) new Operator("=<", 700, "xfx"),
        cast(immutable) new Operator(">", 700, "xfx"),
        cast(immutable) new Operator(">=", 700, "xfx"),
        cast(immutable) new Operator("=:=", 700, "xfx"),
        cast(immutable) new Operator("=\\=", 700, "xfx"),
        cast(immutable) new Operator("is", 700, "xfx"),
        cast(immutable) new Operator("+", 500, "yfx"),
        cast(immutable) new Operator("-", 500, "yfx"),
        cast(immutable) new Operator("*", 400, "yfx"),
        cast(immutable) new Operator("div", 400, "yfx"),
        cast(immutable) new Operator("mod", 400, "yfx"),
        cast(immutable) new Operator("+", 200, "fy"),
        cast(immutable) new Operator("-", 200, "fy")
    ];

}

class LParen : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() const {
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

    override string toString() const {
        return "RParen(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class LBracket : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() const {
        return "LBracket(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class RBracket : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() const {
        return "RBracket(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}

class Period : Token {

    this(dstring lexeme, int line, int column) {
        super(lexeme, line, column);
    }

    override bool opEquals(Object o) {
        return true;
    }

    override string toString() const {
        return "Period(lexeme: \"" ~ lexeme.to!string ~ "\")";
    }

}
