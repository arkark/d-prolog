module dprolog.engine.Messenger;

import std.conv;
import std.container : DList;

import dprolog.engine.Terminal;

class Messenger {

private:
  DList!Message _messageList;

public:
  this() {
    clear();
  }

  bool empty() @property {
    return _messageList.empty;
  }

  void add(Message msg) {
    _messageList.insertBack(msg);
  }

  void show() in {
    assert(!empty);
  } do {
    Terminal.writeln(_messageList.front.text);
    _messageList.removeFront;
  }

  void showAll() {
    while(!empty) {
      show();
    }
  }

  void clear() {
    _messageList.clear();
  }

}

struct Message {
  dstring text;
  this(dstring text) {
    this.text = text;
  }
  this(string text) {
    this.text = text.to!dstring;
  }
}
