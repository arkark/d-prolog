module dprolog.core.Shell;

import std.conv;
import std.string;
import std.process;

@property Shell_ Shell() {
  static Shell_ instance;
  if (!instance) {
    instance = new Shell_();
  }
  return instance;
}

private class Shell_ {

private:
  enum {
    DEFAULT_COLUMNS = 300,
    DEFAULT_LINES = 100,
  }

public:
  int getColumns() {
    try {
      auto result = execute(["tput", "cols"]);
      if (result.status == 0) {
        return result.output.chomp.to!int;
      } else {
        return DEFAULT_COLUMNS;
      }
    } catch (ProcessException e) {
      return DEFAULT_COLUMNS;
    } catch (ConvException e) {
      return DEFAULT_COLUMNS;
    }
  }

  int getLines() {
    try {
      auto result = execute(["tput", "lines"]);
      if (result.status == 0) {
        return result.output.chomp.to!int;
      } else {
        return DEFAULT_LINES;
      }
    } catch (ProcessException e) {
      return DEFAULT_LINES;
    } catch (ConvException e) {
      return DEFAULT_LINES;
    }
  }
}
