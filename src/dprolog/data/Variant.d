module dprolog.data.Variant;

import dprolog.data.Term;

import std.conv,
       std.range,
       std.algorithm;

class Variant {
    private const int id;
    Term term;
    Variant[] children;

    this(int id, Term term, Variant[] children) {
        this.id = id;
        this.term = term;
        this.children = children;
    }

    bool isVariable() {
        return term.isVariable;
    }

    override hash_t toHash() {
        hash_t hash = term.token.toHash;
        return id.hashOf(hash);
    }

    override bool opEquals(Object o) {
        auto that = cast(Variant) o;
        return that && this.id==that.id && this.term.token==that.term.token && this.children.length==that.children.length && zip(this.children, that.children).all!(a => a[0] == a[1]);
    }

    override string toString() {
        return "Variant(id: " ~ id.to!string ~ ", term: " ~ term.toString ~ ")";
    }

}
