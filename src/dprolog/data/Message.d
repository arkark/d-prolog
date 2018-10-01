module dprolog.data.Message;

import std.conv;

struct Message {
  dstring text;
  this(dstring text) {
    this.text = text;
  }
  this(string text) {
    this.text = text.to!dstring;
  }
}
