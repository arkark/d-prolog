module dprolog.util.GetOpt;

import dprolog.engine.Engine;

import std.stdio;
import std.format;
import std.conv;
import std.string;
import std.algorithm;
import std.getopt;
import std.typecons;

@property GetOpt_ GetOpt() {
  static GetOpt_ instance;
  if (!instance) {
    instance = new GetOpt_();
  }
  return instance;
}

private class GetOpt_ {

private:
  bool _shouldExit = false;

  enum fileOption = Option("f", "file", "Read `VALUE` as a user initialization file", true);
  enum verboseOption = Option("v", "verbose", "Print diagnostic output", false);
  enum helpOption = Option("h", "help", "This help information", false);

public:
  void run(Engine engine, string[] args) {
    string filePath;
    bool verbose;
    bool help;

    try {
      args.getopt(
        fileOption.params(filePath).expand,
        verboseOption.params(verbose).expand,
        helpOption.params(help).expand
      );
    } catch(Throwable e) {
      writeln(format!"Error processing arguments: %s"(e.msg));
      writeln("Run 'dprolog --help' for usage information.");
      _shouldExit = true;
      return;
    }

    if (help) {
      printUsage!([fileOption, verboseOption, helpOption]);
      _shouldExit = true;
      return;
    }

    engine.verboseMode = verbose;

    // read a file
    if (!filePath.empty) {
      engine.readFile(filePath.to!dstring);
      engine.showAllMessage();
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
      return tuple(format!"%s|%s"(longOpt, shortOpt), description, &value);
    }
    @property string shortString() {
      return format!"-%s"(shortOpt);
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
