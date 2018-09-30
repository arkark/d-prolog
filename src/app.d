
import dprolog.engine.Engine;

import std.conv;
import std.string;
import std.getopt;

void main(string[] args) {

  string filePath;
  bool verbose;
  auto opt = getopt(
    args,
    "file|f", &filePath,
    "verbose|v", &verbose
  );

  Engine engine = new Engine;
  engine.verboseMode = verbose;

  // read a file
  if (!filePath.empty) {
    engine.readFile(filePath.to!dstring);
    while(!engine.emptyMessage) engine.showMessage;
  }

  while(!engine.isHalt) {
    engine.next();
  }
  destroy(engine);
}
