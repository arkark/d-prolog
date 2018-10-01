module dprolog.engine.Engine;

import dprolog.data.token;
import dprolog.data.Term;
import dprolog.engine.BuiltIn;
import dprolog.engine.Reader;
import dprolog.engine.Executor;

import std.conv;
import std.container : DList;

import arsd.terminal;

class Engine {

private:
  BuildIn _builtIn;
  Reader _reader;
  Executor _executor;

  Terminal _terminal;

  DList!dstring _messageList;

  bool _isHalt = false;
  public bool verboseMode = false;
  public bool queryMode = true;

public:
  this() {
    _builtIn = new BuildIn(this);
    _reader = new Reader(this);
    _executor = new Executor(this);
    _terminal = Terminal(ConsoleOutputType.linear);
    clear();
  }

  void next() in {
    assert(!isHalt);
  } do {
    dstring querifier = Operator.querifier.lexeme ~ " ";
    if (queryMode) _terminal.write(querifier);
    _terminal.flush();
    try {
      string clause = _terminal.getline();
      _terminal.flush();
      execute((queryMode ? querifier : ""d) ~ clause.to!dstring);
      while(!emptyMessage) showMessage;
      _terminal.writeln;
    } catch(UserInterruptionException e) {
      halt();
    } catch(HangupException e) {
      halt();
    }
  }

  void execute(dstring src) in {
    assert(!isHalt);
  } do {
    clearMessage();
    _executor.execute(src);
  }

  bool emptyMessage() {
    return _messageList.empty;
  }

  void showMessage() in {
    assert(!emptyMessage);
  } do {
    _terminal.writeln(_messageList.front);
    _messageList.removeFront;
  }

  void clear() {
    clearMessage();
  }

  void halt() {
    _isHalt = true;
  }

  bool isHalt() @property {
    return _isHalt;
  }

  void readFile(dstring filePath) {
    _reader.read(filePath);
  }

  bool traverseBuiltIn(Term term) {
    return _builtIn.traverse(term);
  }

  void addMessage(T)(T message) {
    _messageList.insertBack(message.to!dstring);
  }

private:
  void clearMessage() {
    _messageList.clear;
  }

}
