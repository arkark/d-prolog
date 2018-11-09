module dprolog.engine.builtIn.BuiltIn;

import dprolog.data.Term;
import dprolog.data.Clause;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.converter.Parser;
import dprolog.converter.ClauseBuilder;
import dprolog.util.functions;

import std.range;
import std.functional;

abstract class BuiltIn {

private:
  Lexer _lexer;
  Parser _parser;
  ClauseBuilder _clauseBuilder;

protected:
  this() {
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
  }

  Term toTerm(dstring src) {
    auto convert(S, T)(Converter!(S, T) converter) {
      return (S src) {
        converter.run(src);
        assert(!converter.hasError);
        return converter.get;
      };
    }
    Clause[] clauseList = (src ~ ".").pipe!(
      a => convert(_lexer)(a),
      a => convert(_parser)(a),
      a => convert(_clauseBuilder)(a)
    );
    assert(clauseList.length == 1 && clauseList.front.instanceOf!Fact);
    return (cast(Fact) clauseList.front).first;
  }

}
