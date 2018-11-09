module dprolog.engine.builtIn.BuiltInCommand;

import dprolog.util.functions;
import dprolog.util.Message;
import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.engine.Reader;
import dprolog.engine.Consulter;
import dprolog.data.Command;
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

@property BuiltInCommand_ BuiltInCommand() {
  static BuiltInCommand_ instance;
  if (!instance) {
    instance = new BuiltInCommand_();
  }
  return instance;
}

private class BuiltInCommand_ {

private:
  Lexer _lexer;
  Parser _parser;
  ClauseBuilder _clauseBuilder;

  Command[] _commands;

public:
  this() {
    _lexer = new Lexer;
    _parser = new Parser;
    _clauseBuilder = new ClauseBuilder;
    setCommands();
  }

  bool traverse(Term term) {
    foreach(command; _commands) {
      if (command.isMatch(term)) {
        command.execute(term);
        return true;
      }
    }
    return false;
  }

private:
  void setCommands() {
    // halt
    auto halt = buildCommand(
      "halt",
      term => Engine.halt()
    );

    // clear screen
    auto clearScreen = buildCommand(
      "clear",
      term => Linenoise.clearScreen()
    );

    // add rules
    auto addRules = buildCommand(
      "[user]",
      term => Consulter.consult()
    );

    // read file
    auto readFile = buildCommand(
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
    auto answerToEverything = buildCommand(
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

    auto runSL = buildCommand(
      "sl",
      term => SL.run()
    );

    _commands = [
      halt,
      addRules,
      readFile,
      answerToEverything,
      clearScreen,
      runSL,
    ];
  }

  Command buildCommand(dstring src, void delegate(Term) executeFun, bool delegate(Term)[dstring] validators = null) {
    Term targetTerm = toTerm(src);
    return new class() Command {
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
