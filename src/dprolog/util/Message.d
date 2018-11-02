module dprolog.util.Message;

import dprolog.util.colorize;

import std.conv;
import std.traits;

Message DefaultMessage(String)(String text)
if (isSomeString!String) {
  return text.makeMessage(ForegroundColor.None, BackgroundColor.None);
}

Message InfoMessage(String)(String text)
if (isSomeString!String) {
  return text.makeMessage(ForegroundColor.Green, BackgroundColor.None);
}

Message VerboseMessage(String)(String text)
if (isSomeString!String) {
  return text.makeMessage(ForegroundColor.Cyan, BackgroundColor.None);
}

Message WarningMessage(String)(String text)
if (isSomeString!String) {
  return text.makeMessage(ForegroundColor.Yellow, BackgroundColor.None);
}

Message ErrorMessage(String)(String text)
if (isSomeString!String) {
  return text.makeMessage(ForegroundColor.Red, BackgroundColor.None);
}

private Message makeMessage(String)(String text, ForegroundColor fgColor, BackgroundColor bgColor)
if (isSomeString!String) {
  return Message(text.to!dstring.colorize(fgColor).colorize(bgColor));
}

struct Message {
  private dstring text;
  private this(dstring text) {
    this.text = text;
  }
  string toString() const {
    return text.to!string;
  }
}
