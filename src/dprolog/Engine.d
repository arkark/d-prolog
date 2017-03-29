
module dprolog.Engine;

import dprolog.data.Token,
       dprolog.data.Term,
       dprolog.data.Clause,
       dprolog.converter.Converter,
       dprolog.converter.Lexer,
       dprolog.converter.Parser,
       dprolog.converter.ClauseBuilder,
       dprolog.util;

import std.stdio,
       std.range,
       std.array,
       std.algorithm,
       std.functional;

class Engine {

private:
    Lexer _lexer                 = new Lexer;
    Parser _parser               = new Parser;
    ClauseBuilder _clauseBuilder = new ClauseBuilder;

    Clause[][Constant] _storage;

    bool _hasError;
    dstring _errorMessage;

public:
    this() {

    }

    void execute(dstring src) {
        Clause[] clauseList = toClauseList(src);
        if (hasError) return;
        clauseList.each!(clause => executeClause(clause));
    }

    void clear() {
        _lexer.clear;
        _parser.clear;
        _clauseBuilder.clear;
        _storage = null;
        _hasError = false;
        _errorMessage = "";
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

    Clause[] toClauseList(dstring src) {
        auto convert(S, T)(Converter!(S, T) converter) {
            return (S src) {
                if (src is null) return null;
                converter.run(src);
                if (converter.hasError) {
                    setErrorMessage(converter.errorMessage);
                    return null;
                }
                return converter.get;
            };
        }
        return src.pipe!(
            a => convert(_lexer)(a),
            a => convert(_parser)(a),
            a => convert(_clauseBuilder)(a)
        );
    }

    void executeClause(Clause clause) {
        clause.castSwitch!(
            (Fact fact)   => executeFact(fact),
            (Rule rule)   => executeRule(rule),
            (Query query) => executeQuery(query)
        );
    }

    void executeFact(Fact fact) {
        storeClause(fact, findConstant(fact.first));
    }

    void executeRule(Rule rule) {
        storeClause(rule, findConstant(rule.first) ~ findConstant(rule.second));
    }

    void executeQuery(Query query) {
        if (query.first.isDetermined) {
            // 正しいかどうか
        } else {
            // 存在するかどうか & ユニフィケーション
        }
    }

    void storeClause(Clause clause, Constant[] constantList) {
        foreach(constant; constantList) {
            if (constant !in _storage) {
                _storage[constant] = [];
            }
            _storage[constant] ~= clause;
        }
    }

    Constant[] findConstant(Term term) {
        return term.token.pipe!((token) {
            if (token.instanceOf!Constant) {
                return [cast(Constant) token];
            } else {
                return new Constant[0];
            }
        }) ~ term.children.map!(t => findConstant(t)).join.array;
    }

    void setErrorMessage(dstring message) {
        _errorMessage = message;
        _hasError = true;
    }

    unittest {
        dstring src = "hoge(aaa). po(X) :- hoge(X). ?- po(aaa).";

        Engine engine = new Engine;
    }

}
