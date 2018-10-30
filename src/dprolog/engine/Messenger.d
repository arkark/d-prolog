module dprolog.engine.Messenger;

import dprolog.data.Message;

import std.stdio;
import std.container : DList;

class Messenger {

private:
  DList!Message _messageList;

public:
  this() {
    clear();
  }

  @property bool empty() {
    return _messageList.empty;
  }

  void add(Message msg) {
    _messageList.insertBack(msg);
  }

  void show() in(!empty) do {
    _messageList.front.text.writeln;
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
