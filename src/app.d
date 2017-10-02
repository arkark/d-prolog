
import dprolog.Engine;

import std.stdio,
       std.conv,
       std.string,
       std.file,
       std.getopt;

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

    while(true) {
        writeln;
        write("Input: ");
        stdout.flush();
        string query = readln.chomp;
        if (query == "halt.") {
            break;
        } else {
            engine.execute(query.to!dstring);
            while(!engine.emptyMessage) engine.showMessage;
        }
    }
}
