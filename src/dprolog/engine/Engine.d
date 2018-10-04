module dprolog.engine.Engine;

import dprolog.data.token;
import dprolog.data.Term;
import dprolog.data.Message;
import dprolog.engine.BuiltIn;
import dprolog.engine.Reader;
import dprolog.engine.Executor;
import dprolog.engine.Messenger;
import dprolog.engine.Terminal;

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
    dstring querifier = Operator.querifier.lexeme ~ " ";
    if (queryMode) Terminal.write(querifier);
    try {
      string clause = Terminal.getline();
      execute((queryMode ? querifier : ""d) ~ clause.to!dstring);
      showAllMessage();
      Terminal.writeln;
    } catch(UserInterruptionException e) {
      halt();
    } catch(HangupException e) {
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
