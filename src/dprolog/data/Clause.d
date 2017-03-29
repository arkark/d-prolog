module dprolog.data.Clause;

import dprolog.data.Token,
       dprolog.data.Term;

import std.conv;

abstract class Clause {}

class Fact : Clause {
    Term first;

    this(Term first) {
        this.first = first;
    }

    override string toString() {
        return "Fact(" ~ first.to!string ~ ")";
    }

    invariant {
        assert(first.isDetermined);
        assert(!first.isCompound);
    }
}

class Rule : Clause {
    Term first;
    Term second;

    this(Term first, Term second) {
        this.first  = first;
        this.second = second;
    }

    override string toString() {
        return "Rule(" ~ first.to!string ~ " :- " ~ second.to!string ~ ")";
    }

    invariant {
        assert(!first.isCompound);
    }
}

class Query : Clause {
    Term first;

    this(Term first) {
        this.first = first;
    }

    override string toString() {
        return "Query(?- " ~ first.to!string ~ ")";
    }
}
