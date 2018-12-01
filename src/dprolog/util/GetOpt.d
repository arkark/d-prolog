module dprolog.util.GetOpt;

import dprolog.engine.Engine;
import dprolog.engine.Messenger;
import dprolog.engine.Reader;
import dprolog.util.Singleton;

import std.stdio;
import std.format;
import std.conv;
import std.string;
import std.algorithm;
import std.getopt;
import std.typecons;

alias GetOpt = Singleton!GetOpt_;

private class GetOpt_ {

private:
  bool _shouldExit = false;

  enum helpOption = Option("h", "help", "Print this help message", false);
  enum versionOption = Option("v", "version", "Print version of dprolog", false);
  enum fileOption = Option("f", "file", "Read `VALUE` as an initialization file", true);
  enum verboseOption = Option("", "verbose", "Print diagnostic output", false);

  enum programVersion = import("dprolog_version.txt").chomp;
  enum compileDate = import("compile_date.txt").chomp;
public:
  void run(string[] args) {
    bool helpMode;
    bool versionMode;
    string filePath;
    bool verboseMode;

    try {
      args.getopt(
        helpOption.params(helpMode).expand,
        versionOption.params(versionMode).expand,
        fileOption.params(filePath).expand,
        verboseOption.params(verboseMode).expand,
      );
    } catch(Throwable e) {
      writeln(format!"Error processing arguments: %s"(e.msg));
      writeln("Run 'dprolog --help' for usage information.");
      _shouldExit = true;
      return;
    }

    if (helpMode) {
      printUsage!([
        helpOption,
        versionOption,
        fileOption,
        verboseOption,
      ]);
      _shouldExit = true;
      return;
    }

    if (versionMode) {
      format!"D-Prolog %s, built on %s"(
        programVersion,
        compileDate
      ).writeln;
      _shouldExit = true;
      return;
    }

    Engine.verboseMode = verboseMode;

    // read a file
    if (!filePath.empty) {
      Reader.read(filePath.to!dstring);
      Messenger.showAll();
    }
  }

  bool shouldExit() {
    return _shouldExit;
  }

private:
  struct Option {
    string shortOpt;
    string longOpt;
    string description;
    bool requiredValue;
    auto params(T)(ref T value) {
      return tuple(
        format!"%s%s"(
          longOpt,
          (shortOpt.empty ? "" : "|") ~ shortOpt
        ),
        description,
        &value
      );
    }
    @property string shortString() {
      return shortOpt.empty ? "" : format!"-%s"(shortOpt);
    }
    @property string longString() {
      return format!"--%s%s"(longOpt, requiredValue ? "=VALUE" : "");
    }
  }

  void printUsage(Option[] options)() {
    writeln("Usage:");
    writeln("    dprolog [<options...>]");
    writeln;
    writeln("Options:");
    enum len1 = options.map!"a.shortString.length".reduce!max.to!string;
    enum len2 = options.map!"a.longString.length".reduce!max.to!string;
    foreach(opt; options) {
      format!(
        "    %"~ len1 ~"s  %"~ len2 ~"s  %s"
      )(
        opt.shortString,
        opt.longString,
        opt.description
      ).writeln;
    }
  }

}
