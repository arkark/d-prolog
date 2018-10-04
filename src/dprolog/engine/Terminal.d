module dprolog.engine.Terminal;

import arsd.terminal : ArsdTerminal = Terminal, ConsoleOutputType;

public {
  import arsd.terminal : UserInterruptionException, HangupException;
}

@property Terminal_ Terminal() {
  static Terminal_ instance;
  if(!instance) {
    instance = new Terminal_();
  }
  return instance;
}

private class Terminal_ {

private:
  ArsdTerminal _terminal;

public:
  this() {
    _terminal = ArsdTerminal(ConsoleOutputType.linear);
  }

  void write(T...)(T text) {
    _terminal.write(text);
    _terminal.flush();
  }

  void writeln(T...)(T text) {
    _terminal.writeln(text);
    _terminal.flush();
  }

  string getline() {
    return _terminal.getline();
  }
}
