
import dprolog.Engine;

import std.stdio,
       std.conv,
       std.string;

void main() {

    Engine engine = new Engine;

    /*dstring src1 = "hoge(aaa). po(X, Y) :- hoge(X), hoge(Y).";
    dstring src2 = "?- po(aaa)."; // => true
    dstring src3 = "?- po(X, Y)."; // => false*/

    /*dstring src = "
    append([],L,L).
    append([H|T],L,[H|R]):- append(T,L,R).
    ";

    engine.execute(src);
    while(!engine.emptyMessage) engine.showMessage;*/

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
