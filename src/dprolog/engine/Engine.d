module dprolog.engine.Engine;

import dprolog.data.token;
import dprolog.engine.Executor;
import dprolog.engine.Messenger;
import dprolog.util.Message;
import dprolog.util.Singleton;
import dprolog.core.Linenoise;

import std.conv;

alias Engine = Singleton!Engine_;

private class Engine_ {

private:
  bool _isHalt = false;
  bool _verboseMode = false;

public:
  void next() in(!isHalt) do {
    dstring queryfier = Operator.queryfier.lexeme ~ " ";
    auto line = Linenoise.nextLine(queryfier.to!string);
    if (line.isJust) {
      Linenoise.addHistory(line.get);
      dstring clause = line.get.to!dstring;
      Executor.execute(queryfier ~ clause);
      Messenger.showAll();
      Messenger.writeln(DefaultMessage(""));
    } else {
      halt();
    }
  }

  void halt() {
    _isHalt = true;
  }

  @property bool isHalt() {
    return _isHalt;
  }

  @property bool verboseMode() {
    return _verboseMode;
  }
  @property bool verboseMode(bool value) {
    return _verboseMode = value;
  }

}
