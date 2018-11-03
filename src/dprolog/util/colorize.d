module dprolog.util.colorize;

import std.conv;
import std.format;
import std.traits;

enum ForegroundColor {
  None = -1,
  Black = 30,
  Red,
  Green,
  Yellow,
  Blue,
  Magenta,
  Cyan,
  White,
}

enum BackgroundColor {
  None = -1,
  Black = 40,
  Red,
  Green,
  Yellow,
  Blue,
  Magenta,
  Cyan,
  White
}

bool isColor(Color)() {
  return is(Color == ForegroundColor) || is(Color == BackgroundColor);
}

@property String colorize(String, Color)(String text, Color color)
if (isSomeString!String && isColor!Color) {
  if (color == Color.None) return text;
  return format!"\033[%dm%s\033[0m"(color, text).to!String;
}

import std.stdio;

unittest {
  writeln(__FILE__, ": test color print");
  foreach(bgColor; EnumMembers!BackgroundColor) {
    foreach(fgColor; EnumMembers!ForegroundColor) {
      format!"(%d, %d)"(bgColor, fgColor).colorize(bgColor).colorize(fgColor).write;
    }
    writeln;
  }
}
