module dprolog.engine.Reader;

import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.engine.Executor;
import dprolog.util.Message;

import std.format;
import std.conv;
import std.file;

@property Reader_ Reader() {
  static Reader_ instance;
  if (!instance) {
    instance = new Reader_();
  }
  return instance;
}

private class Reader_ {
  void read(dstring filePath) {
    if (filePath.exists) {
      Executor.execute(filePath.readText.to!dstring);
    } else {
      Messenger.add(WarningMessage(format!"Warning: file '%s' cannot be read"(filePath)));
    }
  }
}
