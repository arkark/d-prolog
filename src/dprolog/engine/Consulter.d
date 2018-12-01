module dprolog.engine.Consulter;

import dprolog.engine.Executor;
import dprolog.util.Singleton;
import dprolog.core.Linenoise;

import std.conv;
import std.array;

alias Consulter = Singleton!Consulter_;

private class Consulter_ {
  void consult() {
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
    Executor.execute(texts.join("\n"));
  }
}
