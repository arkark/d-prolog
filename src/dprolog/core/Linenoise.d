module dprolog.core.Linenoise;

import dprolog.util.Maybe;
import dprolog.util.Singleton;

import std.conv;
import std.string;

import raw = deimos.linenoise;

alias Linenoise = Singleton!Linenoise_;

private class Linenoise_ {
  private enum defaultMaxHistoryLength = 100;

  this() {
    setMaxHistoryLength(defaultMaxHistoryLength);
  }

  Maybe!string nextLine(string prompt) {
    char* line = raw.linenoise(prompt.toStringz);
    return (line !is null).fmap!({
      string result = line.fromStringz.to!string;
      destroy(line);
      return result;
    });
  }

  bool addHistory(string line) {
    return raw.linenoiseHistoryAdd(line.toStringz) != 0;
  }

  bool setMaxHistoryLength(size_t length) {
    return raw.linenoiseHistorySetMaxLen(length.to!int) != 0;
  }

  bool saveHistory(string fileName) {
    return raw.linenoiseHistorySave(fileName.toStringz) != 0;
  }

  bool loadHistory(string fileName) {
    return raw.linenoiseHistoryLoad(fileName.toStringz) != 0;
  }

  void clearScreen() {
    raw.linenoiseClearScreen();
  }

  void enableMultiLineMode() {
    raw.linenoiseSetMultiLine(1);
  }

  void disableMultiLineMode() {
    raw.linenoiseSetMultiLine(0);
  }

  /*
    The followings aren't wrapped.
    - struct linenoiseCompletions
    - alias linenoiseCompletionCallback
    - void linenoiseSetCompletionCallback(linenoiseCompletionCallback)
    - void linenoiseAddCompletion(linenoiseCompletions *, const char *)
   */
}
