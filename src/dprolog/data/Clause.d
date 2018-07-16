module dprolog.data.Clause;

import dprolog.data.Token;
import dprolog.data.Term;
import dprolog.util.UnionFind;

import std.format;

abstract class Clause {}

class Fact : Clause {
  Term first;

  this(Term first) {
    this.first = first;
  }

  override string toString() const {
    return format!"Fact(\"%s.\")"(first);
  }

  invariant {
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

  override string toString() const {
    return format!"Rule(\"%s :- %s.\")"(first, second);
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

  override string toString() const {
    return format!"Query(\"?- %s.\")"(first);
  }
}
