module dprolog.engine.builtIn.BuiltInCommand;

import dprolog.util.Message;
import dprolog.util.Either;
import dprolog.data.Command;
import dprolog.data.Term;
import dprolog.sl.SL;
import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.engine.Reader;
import dprolog.engine.Consulter;
import dprolog.engine.builtIn.BuiltIn;
import dprolog.core.Linenoise;
import dprolog.core.Shell;

import std.conv;
import std.range;
import std.string;

@property BuiltInCommand_ BuiltInCommand() {
  static BuiltInCommand_ instance;
  if (!instance) {
    instance = new BuiltInCommand_();
  }
  return instance;
}

private class BuiltInCommand_ : BuiltIn {

private:
  Command[] _commands;

public:
  this() {
    super();
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
      (term) {
        Consulter.consult();
        writelnTrue();
      }
    );

    // read file
    auto readFile = buildCommand(
      "[FilePath]",
      (term) {
        dstring filePath = term.children.front.token.lexeme;
        if (filePath.front == '\'') {
          filePath = filePath[1..$-1];
        }
        Reader.read(filePath);
        writelnTrue();
      },
      [
        "FilePath": (Term term) => term.isAtom && term.children.empty
      ]
    );

    // 42
    auto answerToEverything = buildCommand(
      "X",
      term => Messenger.writeln(DefaultMessage("42.")),
      [
        "X": (Term term) => term.isVariable
      ]
    );

    auto pwdCommand = buildCommand(
      "pwd",
      (term) {
        Shell.executePwd.apply!(
          msg => Messenger.writeln(msg),
          (lines) {
            foreach(line; lines) {
              Message msg = InfoMessage("%  " ~ line);
              Messenger.writeln(msg);
            }
          }
        );
        writelnTrue();
      }
    );

    auto lsCommand = buildCommand(
      "ls",
      (term) {
        Shell.executeLs.apply!(
          msg => Messenger.writeln(msg),
          (lines) {
            foreach(line; lines) {
              Message msg = InfoMessage("%  " ~ line);
              Messenger.writeln(msg);
            }
          }
        );
        writelnTrue();
      }
    );

    auto lsCommandWithPath = buildCommand(
      "ls(Path)",
      (term) {
        dstring path = term.children.front.token.lexeme;
        if (path.front == '\'') {
          path = path[1..$-1];
        }

        Shell.executeLsWithPath(path.to!string).apply!(
          msg => Messenger.writeln(msg),
          (lines) {
            foreach(line; lines) {
              Message msg = InfoMessage("%  " ~ line);
              Messenger.writeln(msg);
            }
          }
        );
        writelnTrue();
      },
      [
        "Path": (Term term) => term.isAtom && term.children.empty
      ]
    );

    auto cdCommandWithPath = buildCommand(
      "cd(Path)",
      (term) {
        dstring path = term.children.front.token.lexeme;
        if (path.front == '\'') {
          path = path[1..$-1];
        }

        Shell.executeCdWithPath(path.to!string).apply!(
          msg => Messenger.writeln(msg),
          (lines) {
            foreach(line; lines) {
              Message msg = InfoMessage("%  " ~ line);
              Messenger.writeln(msg);
            }
          }
        );
        writelnTrue();
      },
      [
        "Path": (Term term) => term.isAtom && term.children.empty
      ]
    );

    // sl
    auto slCommand = buildCommand(
      "sl",
      term => SL.run()
    );

    _commands = [
      halt,
      addRules,
      readFile,
      answerToEverything,
      clearScreen,
      pwdCommand,
      lsCommand,
      lsCommandWithPath,
      cdCommandWithPath,
      slCommand,
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

  void writelnTrue() {
    Messenger.writeln(DefaultMessage("true."));
  }
}
