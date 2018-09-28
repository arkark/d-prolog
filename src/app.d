
import dprolog.engine.Engine;

import std.stdio;
import std.conv;
import std.string;
import std.getopt;

import arsd.terminal;

void main(string[] args) {

  string filePath;
  bool verbose;
  auto opt = getopt(
    args,
    "file", &filePath,
    "verbose", &verbose
  );

  Engine engine = new Engine;
  engine.setVerbose(verbose);

  // read a file
  if (!filePath.empty) {
    engine.readFile(filePath.to!dstring);
    while(!engine.emptyMessage) engine.showMessage;
  }

  auto terminal = Terminal(ConsoleOutputType.linear);

  while(!engine.isHalt) {
    terminal.writeln;
    terminal.write("?- ");
    terminal.flush();
    try {
      string query = terminal.getline();
      terminal.flush();
      engine.execute("?- "d ~ query.to!dstring);
      while(!engine.emptyMessage) engine.showMessage;
    } catch(UserInterruptionException e) {
      break;
    } catch(HangupException e) {
      break;
    }
  }
}
