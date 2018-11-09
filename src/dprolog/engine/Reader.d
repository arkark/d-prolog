module dprolog.engine.Reader;

import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.util.Message;

import std.format;
import std.conv;
import std.file;

class Reader {
  void read(dstring filePath) {
    if (filePath.exists) {
      Engine.execute(filePath.readText.to!dstring);
    } else {
      Messenger.add(WarningMessage(format!"Warning: file '%s' cannot be read"(filePath)));
    }
  }
}
