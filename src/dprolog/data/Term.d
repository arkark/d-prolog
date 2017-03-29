module dprolog.data.Term;

import dprolog.data.Token,
       dprolog.util;

import std.stdio,
       std.conv,
       std.algorithm,
       std.range;

class Term {
    Token token;
    Term[] children;
    immutable bool isDetermined;
    immutable bool isCompound;

    this(Token token, Term[] children) {
        this.token = token;
        this.children = children;
        this.isDetermined = (token.instanceOf!Atom && children.all!(c => c.isDetermined)) || token.instanceOf!Number;
        this.isCompound = token==Operator.comma || token==Operator.semicolon;
    }

    bool isAtom() @property {
        return token.instanceOf!Atom && !token.instanceOf!Functor && !token.instanceOf!Operator;
    }

    bool isNumber() @property {
        return token.instanceOf!Number;
    }

    bool isVariable() @property {
        return token.instanceOf!Variable;
    }

    bool isStructure() @property {
        return token.instanceOf!Functor || token.instanceOf!Operator;
    }

    override string toString() {
        if (isCompound) {
            return "( " ~ children.front.to!string ~ " " ~ token.lexeme.to!string ~ " " ~ children.back.to!string ~ " )";
        } else if (isStructure) {
            return token.lexeme.to!string ~ "( " ~ children.map!(c => c.to!string).join(", ") ~ " )";
        } else {
            return token.lexeme.to!string;
        }
    }

    invariant {
        assert(
            (token.instanceOf!Atom                      ) ||
            (token.instanceOf!Number   && children.empty) ||
            (token.instanceOf!Variable && children.empty)
        );
        assert(token != Operator.rulifier);
        assert(token != Operator.querifier);
    }


    /* ---------- Unit Tests ---------- */

    unittest {
        writeln(__FILE__, ": test");

        Atom atom = new Atom("a", -1, -1);
        Number num = new Number("1", -1, -1);
        Variable var = new Variable("X", -1, -1);
        Functor fun = new Functor(atom);
        Operator pipe = cast(Operator) Operator.pipe;
        Operator comma = cast(Operator) Operator.comma;

        Term atomT = new Term(atom, []);
        Term numT = new Term(num, []);
        Term varT = new Term(var, []);
        Term funT = new Term(fun, [atomT, varT, numT]);
        Term listT = new Term(pipe, [funT,  new Term(pipe, [numT, varT])]);
        Term comT = new Term(comma, [listT, funT]);

        assert(atomT.isDetermined);
        assert(numT.isDetermined);
        assert(!varT.isDetermined);
        assert(!funT.isDetermined);
        assert(!listT.isDetermined);
        assert(!listT.children.back.isDetermined);
        assert(!listT.children.back.children.back.isDetermined);
        assert(!comT.isDetermined);

        assert(!atomT.isCompound);
        assert(!numT.isCompound);
        assert(!varT.isCompound);
        assert(!funT.isCompound);
        assert(!listT.isCompound);
        assert(!listT.children.back.isCompound);
        assert(!listT.children.back.children.back.isCompound);
        assert(comT.isCompound);

        import std.range, std.array, std.algorithm, std.functional;
        bool function(Term, int) validate = (term, index) => term.adjoin!(
            //          0,               1,                 2,                  3
            t => t.isAtom, t => t.isNumber, t => t.isVariable, t => t.isStructure
        ).array.enumerate.all!(a => a.value == (a.index == index));

        assert(validate(atomT, 0));
        assert(validate(numT, 1));
        assert(validate(varT, 2));
        assert(validate(funT, 3));
        assert(validate(listT, 3));
        assert(validate(listT.children.back, 3));
        assert(validate(listT.children.back.children.back, 2));
        assert(validate(comT, 3));
    }
}
