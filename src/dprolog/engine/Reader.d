module dprolog.engine.Reader;

import dprolog.engine.Engine;
import dprolog.util.Message;

import std.format;
import std.conv;
import std.file;

class Reader {

private:
  Engine _engine;

public:
  this(Engine engine) {
    _engine = engine;
  }

  void read(dstring filePath) {
    if (filePath.exists) {
      _engine.execute(filePath.readText.to!dstring);
    } else {
      _engine.addMessage(WarningMessage(format!"Warning: file '%s' cannot be read"(filePath)));
    }
  }

}
