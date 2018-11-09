module dprolog.engine.BuiltIn;

import dprolog.util.functions;
import dprolog.util.Message;
import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.engine.Reader;
import dprolog.engine.Consulter;
import dprolog.data.Pattern;
import dprolog.data.Clause;
import dprolog.data.Term;
import dprolog.converter.Converter;
import dprolog.converter.Lexer;
import dprolog.converter.Parser;
import dprolog.converter.ClauseBuilder;
import dprolog.core.Linenoise;
import dprolog.sl.SL;

import std.range;
import std.string;
import std.functional;

@property BuiltIn_ BuiltIn() {
  static BuiltIn_ instance;
  if (!instance) {
    instance = new BuiltIn_();
  }
  return instance;
}

private class BuiltIn_ {

private:
  Lexer _lexer;
  Parser _parser;
  ClauseBuilder _clauseBuilder;

  Pattern[] _patterns;

public:
  this() {
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
    setPatterns();
  }

  bool traverse(Term term) {
    foreach(pattern; _patterns) {
      if (pattern.isMatch(term)) {
        pattern.execute(term);
        return true;
      }
    }
    return false;
  }

private:
  void setPatterns() {
    // halt
    auto halt = buildPattern(
      "halt",
      term => Engine.halt()
    );

    // clear screen
    auto clearScreen = buildPattern(
      "clear",
      term => Linenoise.clearScreen()
    );

    // add rules
    auto addRules = buildPattern(
      "[user]",
      term => Consulter.consult()
    );

    // read file
    auto readFile = buildPattern(
      "[FilePath]",
      (term) {
        dstring filePath = term.children[0].token.lexeme;
        if (filePath.front == '\'') {
          filePath = filePath[1..$-1];
        }
        Reader.read(filePath);
      },
      [
        "FilePath": (Term term) => term.isAtom && term.children.empty
      ]
    );

    // 42
    auto answerToEverything = buildPattern(
      "X",
      (term) {
        enum string lines =
`
██╗  ██╗██████╗
██║  ██║╚════██╗
███████║ █████╔╝
╚════██║██╔═══╝
     ██║███████╗
     ╚═╝╚══════╝ ■
`;
        foreach(line; lines.splitLines) {
          if (line.empty) continue;
          Messenger.writeln(InfoMessage(line));
        }
      },
      [
        "X": (Term term) => term.isVariable
      ]
    );

    auto runSL = buildPattern(
      "sl",
      term => SL.run()
    );

    _patterns = [
      halt,
      addRules,
      readFile,
      answerToEverything,
      clearScreen,
      runSL,
    ];
  }

  Pattern buildPattern(dstring src, void delegate(Term) executeFun, bool delegate(Term)[dstring] validators = null) {
    Term targetTerm = toTerm(src);
    return new class() Pattern {
      override bool isMatch(Term term) {
        bool rec(Term src, Term dst) {
          if (dst.isVariable) {
            if (!validators[dst.token.lexeme](src)) return false;
          } else {
            if (src.token != dst.token) return false;
            if (src.children.length != dst.children.length) return false;
            foreach(l, r; zip(src.children, dst.children)) {
              if (!rec(l, r)) return false;
            }
          }
          return true;
        }
        return rec(term, targetTerm);
      }
      override void execute(Term term) {
        executeFun(term);
      }
    };
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
