module dprolog.Clause;

import dprolog.Token,
       dprolog.Term;

import std.conv;

interface Clause {}

class Fact : Clause {
    Term term;

    this(Term term) {
        this.term = term;
    }

    override string toString() {
        return "Fact(" ~ term.to!string ~ ")";
    }

    invariant {
        assert(term.isDetermined);
        assert(!term.isCompound);
    }
}

class Rule : Clause {
    Term headTerm;
    Term bodyCompoundTerm;

    this(Term headTerm, Term bodyCompoundTerm) {
        this.headTerm  = headTerm;
        this.bodyCompoundTerm = bodyCompoundTerm;
    }

    override string toString() {
        return "Rule(" ~ headTerm.to!string ~ " :- " ~ bodyCompoundTerm.to!string ~ ")";
    }

    invariant {
        assert(!headTerm.isCompound);
    }
}

class Query : Clause {
    Term compoundTerm;

    this(Term compoundTerm) {
        this.compoundTerm = compoundTerm;
    }

    override string toString() {
        return "Query(?- " ~ compoundTerm.to!string ~ ")";
    }
}
