module dprolog.core.Shell;

import dprolog.util.Either;
import dprolog.util.Message;

import std.stdio : StdioException;
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

  Either!(Message, int) getColumns() {
    try {
      auto result = execute(["tput", "cols"]);
      if (result.status == 0) {
        return result.output.chomp.to!int.Right!(Message, int);
      } else {
        return ErrorMessage("Shell Error").Left!(Message, int);
      }
    } catch (ProcessException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    } catch (StdioException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    } catch (ConvException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    }
  }

  Either!(Message, int) getLines() {
    try {
      auto result = execute(["tput", "lines"]);
      if (result.status == 0) {
        return result.output.chomp.to!int.Right!(Message, int);
      } else {
        return ErrorMessage("Shell Error").Left!(Message, int);
      }
    } catch (ProcessException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    } catch (StdioException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    } catch (ConvException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    }
  }
}
