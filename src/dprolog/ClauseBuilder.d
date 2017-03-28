module dprolog.ClauseBuilder;

import dprolog.Token,
       dprolog.AST,
       dprolog.Clause,
       dprolog.Term,
       dprolog.Lexer,
       dprolog.Parser,
       dprolog.util;

import std.stdio,
       std.conv,
       std.range,
       std.array,
       std.algorithm,
       std.functional,
       std.container : DList;

// ClauseBuilder: AST -> Clause[]

class ClauseBuilder {

private:
    bool _isBuilded;
    DList!Clause _resultClauses;

    bool _hasError;
    dstring _errorMessage;

public:

    this() {
        clear();
    }

    void run(ASTRoot astRoot) {
        clear();
        build(astRoot);
        _isBuilded = true;
    }

    Clause[] get() in {
        assert(_isBuilded);
    } body {
        return _resultClauses.array;
    }

    bool hasError() {
        return _hasError;
    }

    dstring errorMessage() in {
        assert(hasError);
    } body {
        return _errorMessage;
    }

private:

    void clear() {
        _isBuilded = false;
        _resultClauses.clear();
        _hasError = false;
        _errorMessage = "";
    }

    void build(ASTRoot astRoot) {
        foreach(ast; astRoot.children) {
            assert(ast.token.instanceOf!Period);
            assert(ast.children.length == 1);
            if (ast.children.empty) continue;

            AST clauseAST = ast.children.front;
            if (clauseAST.pipe!isRule) {
                _resultClauses.insertBack(clauseAST.pipe!toRule);
            } else if (clauseAST.pipe!isQuery) {
                _resultClauses.insertBack(clauseAST.pipe!toQuery);
            } else {
                _resultClauses.insertBack(clauseAST.pipe!toFact);
            }
            if (hasError) return;
        }
    }

    bool isRule(AST ast) {
        return ast.token == Operator.rulifier;
    }

    bool isQuery(AST ast) {
        return ast.token == Operator.querifier;
    }

    Fact toFact(AST ast) {
        Term term = ast.pipe!toTerm;
        if (hasError) return null;
        if (!term.isDetermined || term.isCompound) setErrorMessage(ast.tokenList);
        if (hasError) return null;
        return new Fact(term);
    }

    Rule toRule(AST ast) {
        assert(ast.children.length == 2);
        Term headTerm = ast.children.front.pipe!toTerm;
        Term bodyTerm = ast.children.back.pipe!toTerm;
        if (hasError) return null;
        if (headTerm.isCompound) setErrorMessage(ast.tokenList);
        if (hasError) return null;
        return new Rule(headTerm, bodyTerm);
    }

    Query toQuery(AST ast) {
        assert(ast.children.length == 1);
        Term term = ast.children.front.pipe!toTerm;
        if (hasError) return null;
        return new Query(term);
    }

    Term toTerm(AST ast) {
        Term term;
        if (ast.token.instanceOf!Functor) {
            // Structure
            assert(ast.children.length==1);
            term = ast.children.front.pipe!toArguments.pipe!(
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
            term = ast.children.map!(c => c.pipe!toTerm).array.pipe!(
                children => hasError ? null : new Term(ast.token, children)
            );
        } else if (ast.token.instanceOf!LBracket) {
            // List
            assert(ast.children.length == 1);
            term = ast.children.front.pipe!toList;
        } else {
            // Atom, Number, Variable
            assert(ast.children.empty);
            term = new Term(ast.token, []);
        }
        return term;
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

            Term back;
            if (ast.children.back.token.instanceOf!LBracket) {
                assert(ast.children.back.children.length == 1);
                back = ast.children.back.children.front.pipe!toList;
                if (back.token != Operator.pipe && back.token != Atom.emptyAtom) {
                    Term empty = new Term(cast(Token) Atom.emptyAtom, []);
                    back = new Term(cast(Token) Operator.pipe, [back, empty]);
                }
            } else if (ast.children.back.token.instanceOf!Variable) {
                back = new Term(ast.children.back.token, []);
            } else {
                setErrorMessage(ast.tokenList);
                return null;
            }

            Term front = ast.children.front.pipe!toList;
            if (front.token == Operator.pipe) {
                Term parent = front;
                while(parent.children.back.token == Operator.pipe) {
                    parent = parent.children.back;
                }
                parent.children.back = back;
                return front;
            } else {
                return new Term(ast.token, [front, back]);
            }
        } else if (ast.token == Operator.comma) {
            assert(ast.children.length == 2);
            Term front = ast.children.front.pipe!toTerm;
            Term back = ast.children.back.pipe!toList;
            if (back.token != Operator.pipe) {
                Term empty = new Term(cast(Token) Atom.emptyAtom, []);
                back = new Term(cast(Token) Operator.pipe, [back, empty]);
            }
            return new Term(cast(Token) Operator.pipe, [front, back]);
        } else {
            return ast.pipe!toTerm;
        }
    }

    /*Term concatList(AST a, AST b) {

    }*/




    void setErrorMessage(Token[] tokens) in {
        assert(!tokens.empty);
    } body {
        dstring str = tokens.map!(t => t.lexeme).join(" ");
        _errorMessage = "SyntaxError(" ~tokens.front.line.to!dstring~ ", " ~tokens.front.column.to!dstring~ "): \"" ~str~ "\"";
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

        bool validate(Term term, int n)  {
            return n==0 ? (() =>
                term.isAtom && term.token == Atom.emptyAtom
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

        testError("", false);                          //
        testError("hoge(a).", false);                  //
        testError("hoge(X).", true);                   // => Error: FactなのにVariableがある
        testError("?- hoge(X).", false);               //
        testError("aaa(a), bbb(b).", true);            // => Error: Factが複合節
        testError("aaa(a); bbb(b).", true);            // => Error: Factが複合節
        testError("aaa(X), bbb(X) :- ccc(X).", true);  // => Error: Ruleのheadが複合節
        testError("aa :- (bb :- cc).", true);          // => Error: RuleのSyntaxが不適切
        testError("?- (aa :- cc).", true);             // => Error: QueryのSyntaxが不適切
        testError("?- [].", false);                    //
        testError("?- [a | X].", false);               //
        testError("?- [a | a].", true);                // => Error: ListのSyntaxが不適切
        testError("?- [a | [a | X]].", false);         //
        testError("?- [a | a | X].", true);            // => Error: ListのSyntaxが不適切
        testError("?- [1, 2, 3, 4].", false);          //
        testError("?- [1, 2, 3, 4 | []].", false);     //
        testError("?- [1, 2, 3 | [4]].", false);       //
        testError("?- [1, 2, 3 | 4].", true);          // => Error: ListのSyntaxが不適切
        testError("?- [1 | [2 | [3 | [4]]]].", false); //
        testError("?- [1 | [2, 3 | [4]]].", false);    //
        testError("?- [[], a, [1, 2]].", false);       //
    }

}