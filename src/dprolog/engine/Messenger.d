module dprolog.engine.Messenger;

import dprolog.data.Message;
import dprolog.engine.Terminal;

import std.container : DList;

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
