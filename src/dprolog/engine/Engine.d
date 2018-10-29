module dprolog.engine.Engine;

import dprolog.data.token;
import dprolog.data.Term;
import dprolog.data.Message;
import dprolog.engine.BuiltIn;
import dprolog.engine.Reader;
import dprolog.engine.Executor;
import dprolog.engine.Messenger;
import dprolog.core.Linenoise;

import std.stdio;
import std.conv;

class Engine {

private:
  BuildIn _builtIn;
  Reader _reader;
  Executor _executor;
  Messenger _messenger;

  bool _isHalt = false;
  public bool verboseMode = false;
  public bool queryMode = true;

public:
  this() {
    _builtIn = new BuildIn(this);
    _reader = new Reader(this);
    _executor = new Executor(this);
    _messenger = new Messenger;
  }

  void next() in(!isHalt) do {
    dstring queryfier = Operator.queryfier.lexeme ~ " ";
    auto line = Linenoise.nextLine(queryMode ? queryfier.to!string : "");
    if (line.isJust) {
      Linenoise.addHistory(line.get);
      dstring clause = line.get.to!dstring;
      execute((queryMode ? queryfier : ""d) ~ clause);
      showAllMessage();
      writeln;
    } else {
      halt();
    }
  }

  void execute(dstring src) in(!isHalt) do {
    _messenger.clear();
    _executor.execute(src);
  }

  void halt() {
    _isHalt = true;
  }

  @property bool isHalt() {
    return _isHalt;
  }

  void readFile(dstring filePath) {
    _reader.read(filePath);
  }

  bool traverseBuiltIn(Term term) {
    return _builtIn.traverse(term);
  }

  void showAllMessage() {
    _messenger.showAll();
  }

  void addMessage(Message msg) {
    _messenger.add(msg);
  }

}
