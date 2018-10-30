module dprolog.engine.Consulter;

import dprolog.engine.Engine;
import dprolog.core.Linenoise;

import std.stdio;
import std.conv;
import std.array;

class Consulter {

private:
  Engine _engine;

public:
  this(Engine engine) {
    _engine = engine;
  }

  void exec() {
    dstring[] texts = [];
    string prompt = "|: ";
    while(true) {
      auto line = Linenoise.nextLine(prompt);
      if (line.isJust) {
        texts ~= line.get.to!dstring;
      } else {
        break;
      }
    }
    _engine.execute(texts.join("\n"));
  }
}
