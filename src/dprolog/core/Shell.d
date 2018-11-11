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
        return ErrorMessage(result.output.chomp).Left!(Message, int);
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
        return ErrorMessage(result.output.chomp).Left!(Message, int);
      }
    } catch (ProcessException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    } catch (StdioException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    } catch (ConvException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, int);
    }
  }

  Either!(Message, string[]) executeLs() {
    try {
      auto result = execute(["ls"]);
      if (result.status == 0) {
        return result.output.chomp.splitLines.Right!(Message, string[]);
      } else {
        return ErrorMessage(result.output.chomp).Left!(Message, string[]);
      }
    } catch (ProcessException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, string[]);
    } catch (StdioException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, string[]);
    } catch (ConvException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, string[]);
    }
  }

  Either!(Message, string[]) executeLsWithPath(string path) {
    try {
      auto result = execute(["ls", path]);
      if (result.status == 0) {
        return result.output.chomp.splitLines.Right!(Message, string[]);
      } else {
        return ErrorMessage(result.output.chomp).Left!(Message, string[]);
      }
    } catch (ProcessException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, string[]);
    } catch (StdioException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, string[]);
    } catch (ConvException e) {
      return ErrorMessage("Shell Error: " ~ e.msg).Left!(Message, string[]);
    }
  }
}
