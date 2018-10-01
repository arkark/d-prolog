
import dprolog.engine.Engine;
import dprolog.engine.Terminal;

import std.stdio;
import std.format;
import std.conv;
import std.string;
import std.algorithm;
import std.getopt;
import std.typecons;

enum fileOption = Option("f", "file", "Read `VALUE` as a user initialization file", true);
enum verboseOption = Option("v", "verbose", "Print diagnostic output", false);
enum helpOption = Option("h", "help", "This help information", false);

void main(string[] args) {

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
    return;
  }

  if (help) {
    printUsage!([fileOption, verboseOption, helpOption]);
    return;
  }

  Engine engine = new Engine;
  engine.verboseMode = verbose;

  // read a file
  if (!filePath.empty) {
    engine.readFile(filePath.to!dstring);
    engine.showAllMessage();
  }

  while(!engine.isHalt) {
    engine.next();
  }
  destroy(Terminal);
}

struct Option {
  string shortOpt;
  string longOpt;
  string description;
  bool requiredValue;
  auto params(T)(ref T value) {
    return tuple(format!"%s|%s"(longOpt, shortOpt), description, &value);
  }
  string shortString() @property {
    return format!"-%s"(shortOpt);
  }
  string longString() @property {
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
