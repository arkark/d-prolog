module dprolog.Parser;

import dprolog.Token,
       dprolog.AST,
       dprolog.Lexer,
       dprolog.util;

import std.stdio,
       std.conv,
       std.algorithm,
       std.array,
       std.range,
       std.concurrency,
       std.container : DList;

class Parser {

private:
    bool _isParsed;
    ASTRoot _resultAST;

    bool _hasError;
    dstring _errorMessage;

public:

    this() {
        _resultAST = new ASTRoot;
        clear();
    }

    void run(Token[] tokens) {
        clear();
        parse(tokens);
    }

    ASTRoot get() in {
        assert(_isParsed);
    } body {
        return _resultAST;
    }

    bool hasError() @property {
        return _hasError;
    }

    dstring errorMessage() @property in {
        assert(hasError);
    } body {
        return _errorMessage;
    }

private:

    void clear() {
        _isParsed = false;
        _resultAST.clear;
        _hasError = false;
        _errorMessage = "";
    }

    void parse(Token[] tokens) {
        parseProgram(tokens, _resultAST);
        _isParsed = true;
    }

    void parseProgram(Token[] tokens, AST parent) {
        while(!tokens.empty) {
            int cnt = tokens.countUntil!(t => t.instanceOf!Period);
            if (cnt == -1) {
                setErrorMessage(tokens);
                return;
            } else {
                AST ast = new AST(tokens[cnt]);
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
        Operator op = getHighestOperator(tokens);
        if (hasError) return;
        if (op is null) {
            parseTerm(tokens, parent);
        } else {
            AST ast = new AST(op);
            int cnt = tokens.countUntil(op);
            if (op.notation != Operator.Notation.Prefix) parseTermList(tokens[0..cnt], ast);
            if (op.notation != Operator.Notation.Postfix) parseTermList(tokens[cnt+1..$], ast);
            parent.children ~= ast;
        }
    }

    void parseTerm(Token[] tokens, AST parent) {
        if (tokens.empty) return;

        Token head = tokens.front;
        Token last = tokens.back;
        if (head.instanceOf!LParen && last.instanceOf!RParen && tokens.length>2) {
            parseTerm(tokens[1..$-1], parent);
        } else if (head.instanceOf!LBracket) {
            parseList(tokens, parent);
        } else if (head.instanceOf!Atom && tokens.length>1) {
            parseStructure(tokens, parent);
        } else if ((head.instanceOf!Atom || head.instanceOf!Number || head.instanceOf!Variable) && tokens.length==1) {
            parent.children ~= new AST(head);
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
        AST ast = new AST(new Functor(cast(Atom) tokens.front));
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
        AST ast = new AST(tokens.front);
        parseTermList(tokens[1..$-1], ast);
        parent.children ~= ast;
    }

    Operator getHighestOperator(Token[] tokens) {
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
        return gen.empty ? null : gen.fold!((a, b) {
            if (a.precedence>b.precedence) return a;
            if (a.precedence<b.precedence) return b;

            if (a.type.endsWith("y") && !b.type.startsWith("y")) return a;
            if (b.type.startsWith("y") && !a.type.endsWith("y")) return b;

            setErrorMessage(tokens);
            return b;
        });
    }

    void specifyOperators(Token[] tokens) {
        foreach(i, ref token; tokens) {
            if (token.instanceOf!Atom) {
                bool isPrefix  = i==0               || tokens[i-1].instanceOf!LParen || tokens[i-1].instanceOf!LBracket;
                bool isPostfix = i==tokens.length-1 || tokens[i+1].instanceOf!RParen || tokens[i+1].instanceOf!RBracket;
                Operator op =  Operator.getOperator(
                    cast(Atom) token,
                    isPrefix  ? Operator.Notation.Prefix  :
                    isPostfix ? Operator.Notation.Postfix :
                                Operator.Notation.Infix
                );
                if (op !is null) token = op;
            }
        }
    }

    void setErrorMessage(Token[] tokens) in {
        assert(!tokens.empty);
    } body {
        dstring str = tokens.map!(t => t.lexeme).join(" ");
        _errorMessage = "ParseError(" ~tokens.front.line.to!dstring~ ", " ~tokens.front.column.to!dstring~ "): cannot parse \"" ~str~ "\".";
        _hasError = true;
    }


    /* ---------- Unit Tests ---------- */

    static void testAST(TAry...)(ASTRoot root, int[] inds...) {
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
        Parser.testAST!(Variable, Operator)(root, 0, 0);
        Parser.testAST!(Operator, Operator)(root, 0, 0, 1);
        Parser.testAST!(Number, Number)(root, 0, 0, 1, 0);
        Parser.testAST!(Variable, Number)(root, 0, 0, 1, 1);

        // root.writeln;
    }

    unittest {
        writeln(__FILE__, ": test errorMessage");

        auto lexer = new Lexer;
        auto parser = new Parser;
        lexer.run("hoge(X). po");
        parser.run(lexer.get());
        assert(parser.hasError);
        // parser.errorMessage.writeln;
        lexer.run("hoge(X).");
        parser.run(lexer.get());
        // parser.get().writeln;
        assert(!parser.hasError);
        lexer.run("aa :- bb:- cc.");
        parser.run(lexer.get());
        assert(parser.hasError);
        // parser.errorMessage.writeln;
        lexer.run("hoge(aa aa).");
        parser.run(lexer.get());
        assert(parser.hasError);
        // parser.errorMessage.writeln;
        lexer.run("hoge(()).");
        parser.run(lexer.get());
        assert(parser.hasError);
        // parser.errorMessage.writeln;
        lexer.run("hoge((X).");
        parser.run(lexer.get());
        assert(parser.hasError);
        // parser.errorMessage.writeln;
    }

}
