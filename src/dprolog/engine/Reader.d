module dprolog.engine.Reader;

import dprolog.engine.Messenger;
import dprolog.engine.Executor;
import dprolog.util.Message;
import dprolog.util.Singleton;

import std.format;
import std.conv;
import std.file;

alias Reader = Singleton!Reader_;

private class Reader_ {
  void read(dstring filePath) {
    if (filePath.exists) {
      Executor.execute(filePath.readText.to!dstring);
    } else {
      Messenger.add(ErrorMessage(format!"Error: file '%s' cannot be read"(filePath)));
    }
  }
}
