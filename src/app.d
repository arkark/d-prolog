
import dprolog.engine.Engine;

import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.getopt;

void main(string[] args) {

  string filePath;
  auto opt = getopt(args, "file", &filePath);

  Engine engine = new Engine;

  // read a file
  if (!filePath.empty) {
    if (filePath.exists) {
      engine.execute(filePath.readText.to!dstring);
    } else {
      writeln("Warning: file '", filePath, "' cannot be read");
    }
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
