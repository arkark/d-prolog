
import dprolog.engine.Engine;

import std.stdio;
import std.conv;
import std.string;
import std.getopt;

void main(string[] args) {

  string filePath;
  auto opt = getopt(args, "file", &filePath);

  Engine engine = new Engine;

  // read a file
  if (!filePath.empty) {
    engine.readFile(filePath.to!dstring);
  }

  while(!engine.isHalt) {
    writeln;
    write("Input: ");
    stdout.flush();
    string query = readln.chomp;
    engine.execute(query.to!dstring);
    while(!engine.emptyMessage) engine.showMessage;
  }
}
