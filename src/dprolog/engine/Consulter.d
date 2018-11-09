module dprolog.engine.Consulter;

import dprolog.engine.Engine;
import dprolog.core.Linenoise;

import std.stdio;
import std.conv;
import std.array;

class Consulter {
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
    Engine.execute(texts.join("\n"));
  }
}
