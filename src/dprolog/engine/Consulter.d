module dprolog.engine.Consulter;

import dprolog.engine.Executor;
import dprolog.core.Linenoise;

import std.conv;
import std.array;

@property Consulter_ Consulter() {
  static Consulter_ instance;
  if (!instance) {
    instance = new Consulter_();
  }
  return instance;
}

class Consulter_ {
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
