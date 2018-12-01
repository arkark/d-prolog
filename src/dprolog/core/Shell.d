module dprolog.core.Shell;

import dprolog.util.Either;
import dprolog.util.Message;
import dprolog.util.Singleton;

import std.stdio : StdioException;
import std.conv;
import std.string;
import std.process;
import std.file : chdir, FileException;
import std.traits;

alias Shell = Singleton!Shell_;

private class Shell_ {

private:
  alias Result = ReturnType!executeShell;

public:
  Either!(Message, string[]) executeLs() {
    return execute("ls").bind!((result) {
      if (result.status == 0) {
        return result.output.chomp.splitLines.Right!(Message, string[]);
      } else {
        return ErrorMessage(result.output.chomp).Left!(Message, string[]);
      }
    });
  }

  Either!(Message, string[]) executeLsWithPath(string path) {
    return execute("ls " ~ path).bind!((result) {
      if (result.status == 0) {
        return result.output.chomp.splitLines.Right!(Message, string[]);
      } else {
        return ErrorMessage(result.output.chomp).Left!(Message, string[]);
      }
    });
  }

  Either!(Message, string[]) executeCdWithPath(string path) {
    return execute("echo " ~ path).bind!((result) {
      try {
        if (result.status == 0) {
          result.output.chomp.chdir;
        } else {
          path.chdir;
        }
        return [].Right!(Message, string[]);
      } catch (FileException e) {
        return ErrorMessage(e.msg).Left!(Message, string[]);
      }
    });
  }

private:
  Either!(Message, Result) execute(string command) {
    try {
      return executeShell(command).Right!(Message, Result);
    } catch (ProcessException e) {
      return ErrorMessage(e.msg).Left!(Message, Result);
    } catch (StdioException e) {
      return ErrorMessage(e.msg).Left!(Message, Result);
    }
  }
}
